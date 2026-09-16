import 'segment.dart';

class Huep {
  final String id;
  final String streetAddress;
  final String houseNumber;
  final String? installationLocation;
  final String? status;

  const Huep({
    required this.id,
    required this.streetAddress,
    required this.houseNumber,
    this.installationLocation,
    this.status,
  });
}

class Muffe {
  final String id;
  final String type;
  final double? latitude;
  final double? longitude;
  final int? spliceCount;
  final bool? isSealed;

  const Muffe({
    required this.id,
    required this.type,
    this.latitude,
    this.longitude,
    this.spliceCount,
    this.isSealed,
  });
}

class Pop {
  final String id;
  final String name;
  final String locationAddress;
  final int? maxCapacityPorts;
  final String? clusterId;
  final List<Netzverteiler> nvts;

  const Pop({
    required this.id,
    required this.name,
    required this.locationAddress,
    this.maxCapacityPorts,
    this.clusterId,
    this.nvts = const [],
  });

  factory Pop.fromJson(Map<String, dynamic> json) {
    return Pop(
      id: json['id'].toString(),
      name: json['name'],
      locationAddress: json['locationAddress'],
      maxCapacityPorts: json['maxCapacityPorts'],
      clusterId: json['clusterId']?.toString() ?? json['cluster']?['id']?.toString(),
      nvts: json['nvts'] != null 
          ? (json['nvts'] as List).map((e) => Netzverteiler.fromJson(e)).toList() 
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'locationAddress': locationAddress,
      'maxCapacityPorts': maxCapacityPorts,
      'clusterId': clusterId,
      'nvts': nvts.map((e) => e.toJson()).toList(),
    };
  }
}

class Netzverteiler {
  final String id;
  final String identifier;
  final double? latitude;
  final double? longitude;
  final String? popId;

  const Netzverteiler({
    required this.id,
    required this.identifier,
    this.latitude,
    this.longitude,
    this.popId,
  });

  factory Netzverteiler.fromJson(Map<String, dynamic> json) {
    return Netzverteiler(
      id: json['id'].toString(),
      identifier: json['identifier'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      popId: json['popId']?.toString() ?? json['pop']?['id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identifier': identifier,
      'latitude': latitude,
      'longitude': longitude,
      'popId': popId,
    };
  }
}

class Rohrverband {
  final String id;
  final String type;
  final String? colorCode;
  final bool? passedPressureTest;
  final Segment segment;

  const Rohrverband({
    required this.id,
    required this.type,
    this.colorCode,
    this.passedPressureTest,
    required this.segment,
  });
}

class DropConnection {
  const DropConnection();
}

class FiberBox {
  const FiberBox();
}
