class Pop {
  final int id;
  final String name;
  final String locationAddress;
  final int maxCapacityPorts;
  final List<int>? nvtIds;

  Pop({
    required this.id,
    required this.name,
    required this.locationAddress,
    required this.maxCapacityPorts,
    this.nvtIds,
  });

  factory Pop.fromJson(Map<String, dynamic> json) {
    return Pop(
      id: json['id'],
      name: json['name'],
      locationAddress: json['locationAddress'],
      maxCapacityPorts: json['maxCapacityPorts'],
      nvtIds: json['nvtIds'] != null ? List<int>.from(json['nvtIds']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'locationAddress': locationAddress,
      'maxCapacityPorts': maxCapacityPorts,
      'nvtIds': nvtIds,
    };
  }
}

class Netzverteiler {
  final int id;
  final String identifier;
  final double latitude;
  final double longitude;
  final int popId;
  final List<int>? huepIds;

  Netzverteiler({
    required this.id,
    required this.identifier,
    required this.latitude,
    required this.longitude,
    required this.popId,
    this.huepIds,
  });

  factory Netzverteiler.fromJson(Map<String, dynamic> json) {
    return Netzverteiler(
      id: json['id'],
      identifier: json['identifier'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      popId: json['popId'],
      huepIds: json['huepIds'] != null ? List<int>.from(json['huepIds']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identifier': identifier,
      'latitude': latitude,
      'longitude': longitude,
      'popId': popId,
      'huepIds': huepIds,
    };
  }
}

class Muffe {
  final int id;
  final String type;
  final double latitude;
  final double longitude;
  final int spliceCount;
  final bool isSealed;
  final int? splicerSubcontractorId;

  Muffe({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.spliceCount,
    required this.isSealed,
    this.splicerSubcontractorId,
  });

  factory Muffe.fromJson(Map<String, dynamic> json) {
    return Muffe(
      id: json['id'],
      type: json['type'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      spliceCount: json['spliceCount'],
      isSealed: json['isSealed'],
      splicerSubcontractorId: json['splicerSubcontractorId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'spliceCount': spliceCount,
      'isSealed': isSealed,
      'splicerSubcontractorId': splicerSubcontractorId,
    };
  }
}

class Huep {
  final int id;
  final String streetAddress;
  final String houseNumber;
  final String installationLocation;
  final String status;
  final int netzverteilerId;

  Huep({
    required this.id,
    required this.streetAddress,
    required this.houseNumber,
    required this.installationLocation,
    required this.status,
    required this.netzverteilerId,
  });

  factory Huep.fromJson(Map<String, dynamic> json) {
    return Huep(
      id: json['id'],
      streetAddress: json['streetAddress'],
      houseNumber: json['houseNumber'],
      installationLocation: json['installationLocation'],
      status: json['status'],
      netzverteilerId: json['netzverteilerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'streetAddress': streetAddress,
      'houseNumber': houseNumber,
      'installationLocation': installationLocation,
      'status': status,
      'netzverteilerId': netzverteilerId,
    };
  }
}
