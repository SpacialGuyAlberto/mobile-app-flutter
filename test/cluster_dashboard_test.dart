import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Cluster;
import 'package:quarkbau_mobile/models/planning/cluster.dart';
import 'package:quarkbau_mobile/models/planning/project.dart';
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
      const item = ClusterElementItem(
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

      const pop = Pop(
        id: 'pop_1',
        name: 'Central POP',
        clusterId: 'c1',
        locationAddress: 'Main St 1',
        latitude: 52.52,
        longitude: 13.40,
        maxCapacityPorts: 100,
        nvts: [],
      );

      const segment = Segment(
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

    test('defaultMarkerSize is reduced to 72.0 for compact map display', () {
      expect(ClusterMapObjectBuilder.defaultMarkerSize, 72.0);
    });

    test('build applies custom popIcon and nvtIcon if provided', () {
      final builder = ClusterMapObjectBuilder();
      final customIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      builder.popIcon = customIcon;
      builder.nvtIcon = customIcon;

      const pop = Pop(
        id: 'pop_test',
        name: 'Custom Icon POP',
        clusterId: 'c1',
        locationAddress: 'Test Address',
        latitude: 52.52,
        longitude: 13.40,
        maxCapacityPorts: 50,
        nvts: [],
      );

      const nvt = Netzverteiler(
        id: 'nvt_test',
        identifier: 'NVT-01',
        latitude: 52.53,
        longitude: 13.41,
      );

      final mapData = builder.build(
        pops: [pop],
        nvts: [nvt],
        segments: [],
        utilities: [],
        onSegmentTapped: (_) {},
        onCrewTapped: (_) {},
        onMachineryTapped: (_) {},
      );

      expect(mapData.markers.length, 2);
      final popMarker = mapData.markers.firstWhere((m) => m.markerId.value == 'pop_pop_test');
      final nvtMarker = mapData.markers.firstWhere((m) => m.markerId.value == 'nvt_nvt_test');
      expect(popMarker.icon, customIcon);
      expect(nvtMarker.icon, customIcon);
    });

    test('build prioritizes clusterCenter over default Berlin coordinates when nvts/segments are empty', () {
      final builder = ClusterMapObjectBuilder();
      const frankfurtCenter = LatLng(50.1020, 8.5531);

      final mapData = builder.build(
        pops: [],
        nvts: [],
        segments: [],
        utilities: [],
        clusterCenter: frankfurtCenter,
        onSegmentTapped: (_) {},
        onCrewTapped: (_) {},
        onMachineryTapped: (_) {},
      );

      expect(mapData.initialCamera, isNotNull);
      expect(mapData.initialCamera!.target.latitude, frankfurtCenter.latitude);
      expect(mapData.initialCamera!.target.longitude, frankfurtCenter.longitude);
      expect(mapData.initialCamera!.zoom, 16.0);
    });

    test('build falls back to pops when nvts are empty', () {
      final builder = ClusterMapObjectBuilder();
      const pop = Pop(
        id: 'pop_central',
        name: 'Frankfurt Central POP',
        clusterId: 'c1',
        locationAddress: 'Frankfurt',
        latitude: 50.1109,
        longitude: 8.6821,
        maxCapacityPorts: 100,
        nvts: [],
      );

      final mapData = builder.build(
        pops: [pop],
        nvts: [],
        segments: [],
        utilities: [],
        onSegmentTapped: (_) {},
        onCrewTapped: (_) {},
        onMachineryTapped: (_) {},
      );

      expect(mapData.initialCamera, isNotNull);
      expect(mapData.initialCamera!.target.latitude, 50.1109);
      expect(mapData.initialCamera!.target.longitude, 8.6821);
    });
  });

  group('Cluster & Project coordinates model tests', () {
    test('Cluster parses latitude and longitude from JSON and serializes correctly', () {
      final json = {
        'id': 15,
        'name': 'Frankfurt Cluster',
        'description': 'Main cluster area',
        'projectId': 42,
        'latitude': 50.102064,
        'longitude': 8.553179,
      };

      final cluster = Cluster.fromJson(json);
      expect(cluster.id, '15');
      expect(cluster.name, 'Frankfurt Cluster');
      expect(cluster.latitude, 50.102064);
      expect(cluster.longitude, 8.553179);

      final serialized = cluster.toJson();
      expect(serialized['latitude'], 50.102064);
      expect(serialized['longitude'], 8.553179);
    });

    test('Project model parses latitude/longitude aliases and getters properly', () {
      final json = {
        'id': 12,
        'name': 'Frankfurt Hochst',
        'latitude': 50.102064,
        'longitude': 8.553179,
      };

      final project = Project.fromJson(json);
      expect(project.id, '12');
      expect(project.name, 'Frankfurt Hochst');
      expect(project.startLatitude, 50.102064);
      expect(project.startLongitude, 8.553179);
      expect(project.latitude, 50.102064);
      expect(project.longitude, 8.553179);
    });
  });
}
