class FencingPlan {
  final int id;
  final int segmentId;
  final String closureType;
  final List<FencingElement> elements;

  const FencingPlan({
    required this.id,
    required this.segmentId,
    required this.closureType,
    this.elements = const [],
  });

  factory FencingPlan.fromJson(Map<String, dynamic> json) {
    return FencingPlan(
      id: json['id'] as int,
      segmentId: json['segmentId'] as int,
      closureType: json['closureType'] as String? ?? 'PARTIAL',
      elements: (json['elements'] as List<dynamic>?)
              ?.map((e) => FencingElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'segmentId': segmentId,
      'closureType': closureType,
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }
}

class FencingElement {
  final int id;
  final String elementType; // "BARRIER", "CONE", "SIGN_STOP", "TRAFFIC_LIGHT"
  final double latitude;
  final double longitude;
  final double? rotation;

  const FencingElement({
    required this.id,
    required this.elementType,
    required this.latitude,
    required this.longitude,
    this.rotation,
  });

  factory FencingElement.fromJson(Map<String, dynamic> json) {
    return FencingElement(
      id: json['id'] as int,
      elementType: json['elementType'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rotation: json['rotation'] != null ? (json['rotation'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'elementType': elementType,
      'latitude': latitude,
      'longitude': longitude,
      if (rotation != null) 'rotation': rotation,
    };
  }
}
