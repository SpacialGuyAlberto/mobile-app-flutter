class Organization {
  final String id;
  final String name;
  final String slug;
  final String type;
  final DateTime createdAt;

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    required this.createdAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'].toString(),
      name: json['name'],
      slug: json['slug'],
      type: json['type'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
