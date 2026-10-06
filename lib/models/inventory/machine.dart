class Machine {
  final int? id;
  final String serialNumber;
  final String name;
  final String type;
  final String status;
  final String? currentLocation;
  final int? assignedCrewId;

  Machine({
    this.id,
    required this.serialNumber,
    required this.name,
    required this.type,
    required this.status,
    this.currentLocation,
    this.assignedCrewId,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'] as int?,
      serialNumber: json['serialNumber'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      currentLocation: json['currentLocation'] as String?,
      assignedCrewId: json['assignedCrewId'] as int?,
    );
  }
}
