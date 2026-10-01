class GeometryPoint {
  final double latitude;
  final double longitude;
  final double? z;

  const GeometryPoint({
    required this.latitude,
    required this.longitude,
    this.z,
  });

  factory GeometryPoint.fromJson(Map<String, dynamic> json) {
    return GeometryPoint(
      latitude: (json['lat'] ?? json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['lng'] ?? json['longitude'] ?? 0.0).toDouble(),
      z: json['z'] != null ? (json['z'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lng': longitude,
      'z': z,
    };
  }
}
