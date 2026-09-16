class GeometryPoint {
  final double latitude;
  final double longitude;

  const GeometryPoint({
    required this.latitude,
    required this.longitude,
  });

  factory GeometryPoint.fromJson(Map<String, dynamic> json) {
    return GeometryPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
