import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Strongly-typed metadata representation for CreateSegmentScreen (LSP compliant).
class CreateSegmentMetadata {
  final List<dynamic> crews;
  final List<dynamic> pops;
  final List<dynamic> netzverteilers;
  final List<dynamic> segmentsContext;
  final LatLng? projectInitialLocation;

  const CreateSegmentMetadata({
    this.crews = const [],
    this.pops = const [],
    this.netzverteilers = const [],
    this.segmentsContext = const [],
    this.projectInitialLocation,
  });

  CreateSegmentMetadata copyWith({
    List<dynamic>? crews,
    List<dynamic>? pops,
    List<dynamic>? netzverteilers,
    List<dynamic>? segmentsContext,
    LatLng? projectInitialLocation,
  }) {
    return CreateSegmentMetadata(
      crews: crews ?? this.crews,
      pops: pops ?? this.pops,
      netzverteilers: netzverteilers ?? this.netzverteilers,
      segmentsContext: segmentsContext ?? this.segmentsContext,
      projectInitialLocation: projectInitialLocation ?? this.projectInitialLocation,
    );
  }
}
