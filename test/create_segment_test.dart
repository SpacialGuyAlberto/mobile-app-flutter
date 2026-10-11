import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quarkbau_mobile/models/planning/geometry_point.dart';
import 'package:quarkbau_mobile/screens/projekt/create_segment/geometry/segment_geometry_service.dart';
import 'package:quarkbau_mobile/screens/projekt/create_segment/models/create_segment_metadata.dart';
import 'package:quarkbau_mobile/screens/projekt/create_segment/models/segment_creation_payload.dart';
import 'package:quarkbau_mobile/screens/projekt/create_segment/utils/segment_map_builder.dart';

void main() {
  group('SegmentGeometryService tests', () {
    test('calculateDistance computes distance accurately', () {
      // Distance between 2 coordinates in Berlin (~1.1 km)
      final distance = SegmentGeometryService.calculateDistance(
        52.5200,
        13.4050,
        52.5300,
        13.4050,
      );

      expect(distance, greaterThan(1100));
      expect(distance, lessThan(1120));
    });

    test('calculateTotalLength with 2 points does not interpolate', () {
      final points = [
        const GeometryPoint(latitude: 52.5200, longitude: 13.4050),
        const GeometryPoint(latitude: 52.5300, longitude: 13.4050),
      ];

      final total = SegmentGeometryService.calculateTotalLength(points, 0.85);
      expect(total, greaterThan(1100));
    });

    test('catmullRomSpline generates smooth curve with >2 points', () {
      final points = [
        const GeometryPoint(latitude: 52.5200, longitude: 13.4050),
        const GeometryPoint(latitude: 52.5250, longitude: 13.4100),
        const GeometryPoint(latitude: 52.5300, longitude: 13.4050),
      ];

      final spline = SegmentGeometryService.catmullRomSpline(points, 0.85);
      expect(spline.length, greaterThan(points.length));
    });

    test('calculateVectorMetrics computes slope and delta Z', () {
      final points = [
        const GeometryPoint(latitude: 52.5200, longitude: 13.4050, z: 10.0),
        const GeometryPoint(latitude: 52.5300, longitude: 13.4050, z: 20.0),
      ];

      final metrics = SegmentGeometryService.calculateVectorMetrics(points);
      expect(metrics.length, 1);
      final m = metrics.first;
      expect(m.index, 1);
      expect(m.z1, 10.0);
      expect(m.z2, 20.0);
      expect(m.slopePercent, greaterThan(0));
    });
  });

  group('SegmentCreationPayload tests', () {
    test('toJson serializes correctly', () {
      const payload = SegmentCreationPayload(
        streetName: 'Berliner Allee',
        streetType: 'residential',
        workType: 'EXCAVATION',
        soilType: 'ASPHALT',
        trafficLevel: 'LOW',
        length: 250.5,
        points: [
          GeometryPoint(latitude: 52.52, longitude: 13.40, z: 5.0),
          GeometryPoint(latitude: 52.53, longitude: 13.41, z: 6.0),
        ],
      );

      final json = payload.toJson();
      expect(json['streetName'], 'Berliner Allee');
      expect(json['length'], 250.5);
      expect(json['currentState'], 'PLAN');
      expect((json['geometry'] as List).length, 2);
    });
  });

  group('SegmentMapBuilder tests', () {
    test('buildContextMarkers accepts custom popIcon and nvtIcon', () {
      final customIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      const metadata = CreateSegmentMetadata(
        pops: [
          {'id': 'p1', 'name': 'POP 1', 'latitude': 52.52, 'longitude': 13.40},
        ],
        netzverteilers: [
          {'id': 'n1', 'identifier': 'NVT 1', 'latitude': 52.53, 'longitude': 13.41},
        ],
      );

      final markers = SegmentMapBuilder.buildContextMarkers(
        metadata,
        popIcon: customIcon,
        nvtIcon: customIcon,
      );

      expect(markers.length, 2);
      final popMarker = markers.firstWhere((m) => m.markerId.value == 'pop_p1');
      final nvtMarker = markers.firstWhere((m) => m.markerId.value == 'nvt_n1');
      expect(popMarker.icon, customIcon);
      expect(nvtMarker.icon, customIcon);
    });
  });
}
