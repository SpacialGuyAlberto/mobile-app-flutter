import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quarkbau_mobile/screens/projekt/cluster_dashboard/models/cluster_element_item.dart';
import 'package:quarkbau_mobile/screens/projekt/cluster_dashboard/utils/cluster_map_object_builder.dart';
import 'package:quarkbau_mobile/screens/projekt/cluster_dashboard/utilities/utility_map_renderer.dart';
import 'package:quarkbau_mobile/models/planning/infrastructure_elements.dart';
import 'package:quarkbau_mobile/models/planning/segment.dart';
import 'package:quarkbau_mobile/models/planning/geometry_point.dart';
import 'package:quarkbau_mobile/models/planning/enums/work_type.dart';
import 'package:quarkbau_mobile/models/planning/enums/workflow_state.dart';
import 'package:quarkbau_mobile/models/utility_models.dart';

void main() {
  group('ClusterElementItem & ClusterElementType tests', () {
    test('ClusterElementType resolves known and unknown types correctly', () {
      final popType = ClusterElementType.fromKey('POP');
      expect(popType.key, 'POP');
      expect(popType.label, 'POP');

      final nvtType = ClusterElementType.fromKey('Netzverteiler');
      expect(nvtType.key, 'Netzverteiler');

      final unknownType = ClusterElementType.fromKey('CustomElement');
      expect(unknownType.key, 'CustomElement');
      expect(unknownType.label, 'CustomElement');
    });

    test('ClusterElementItem stores attributes polymorphically (LSP)', () {
      final item = ClusterElementItem(
        id: '123',
        name: 'Test POP',
        status: 'ACTIVE',
        type: ClusterElementType.pop,
      );

      expect(item.id, '123');
      expect(item.name, 'Test POP');
      expect(item.status, 'ACTIVE');
      expect(item.type, ClusterElementType.pop);
    });
  });

  group('UtilityMapRenderer tests', () {
    test('resolves colors according to utility types', () {
      final water = WaterPipe(geometry: []);
      final gas = GasPipe(geometry: []);
      final electricity = ElectricityCable(geometry: []);

      expect(UtilityMapRenderer.getUtilityColor(water), Colors.blueAccent);
      expect(UtilityMapRenderer.getUtilityColor(gas), Colors.yellowAccent);
      expect(UtilityMapRenderer.getUtilityColor(electricity), Colors.redAccent);
    });

    test('extracts coordinates and builds dashed polylines', () {
      final water = WaterPipe(
        id: 10,
        geometry: [
          {'lat': 52.52, 'lng': 13.40},
          {'lat': 52.53, 'lng': 13.41},
        ],
      );

      final polylines = UtilityMapRenderer.buildPolylines([water]);
      expect(polylines.length, 1);
      final polyline = polylines.first;
      expect(polyline.points.length, 2);
      expect(polyline.color, Colors.blueAccent);
      expect(polyline.patterns.length, 2); // Dash and Gap
    });
  });

  group('ClusterMapObjectBuilder tests', () {
    test('builds markers and polylines from domain entities', () {
      final builder = ClusterMapObjectBuilder();

      final pop = Pop(
        id: 'pop_1',
        name: 'Central POP',
        clusterId: 'c1',
        locationAddress: 'Main St 1',
        latitude: 52.52,
        longitude: 13.40,
        maxCapacityPorts: 100,
        nvts: [],
      );

      final segment = Segment(
        id: 'seg_1',
        streetName: 'Bahnhofstrasse',
        streetType: 'STREET',
        workType: WorkType.trenching,
        currentState: WorkflowState.plan,
        length: 120,
        geometry: [
          GeometryPoint(latitude: 52.52, longitude: 13.40),
          GeometryPoint(latitude: 52.53, longitude: 13.41),
        ],
      );

      final water = WaterPipe(
        id: 99,
        geometry: [
          {'lat': 52.52, 'lng': 13.40},
          {'lat': 52.525, 'lng': 13.405},
        ],
      );

      final mapData = builder.build(
        pops: [pop],
        nvts: [],
        segments: [segment],
        utilities: [water],
        onSegmentTapped: (_) {},
        onCrewTapped: (_) {},
        onMachineryTapped: (_) {},
      );

      expect(mapData.markers.length, 1);
      expect(mapData.markers.first.markerId.value, 'pop_pop_1');
      // 2 for segment (outer + inner) + 1 for utility
      expect(mapData.polylines.length, 3);
      expect(mapData.initialCamera, isNotNull);
    });
  });
}
