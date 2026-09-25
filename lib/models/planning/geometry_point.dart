class GeometryPoint {
  final double latitude;
  final double longitude;

  const GeometryPoint({
    required this.latitude,
    required this.longitude,
  });

  factory GeometryPoint.fromJson(Map<String, dynamic> json) {
    return GeometryPoint(
      latitude: (json['lat'] ?? json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['lng'] ?? json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lng': longitude,
    };
  }
}
