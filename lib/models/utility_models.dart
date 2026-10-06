abstract class UtilityLine {
  final int? id;
  final String utilityType;
  final List<dynamic> geometry;
  final double? depth;
  final String? operatorName;
  final String? contactPhone;
  final String? hazardLevel;
  final String? status;

  UtilityLine({
    this.id,
    required this.utilityType,
    required this.geometry,
    this.depth,
    this.operatorName,
    this.contactPhone,
    this.hazardLevel,
    this.status,
  });

  static UtilityLine fromJson(Map<String, dynamic> json) {
    String type = json['utilityType'] ?? 'WATER';
    List<dynamic> geom = json['geometry'] ?? [];
    double? d = json['depth'] != null ? (json['depth'] as num).toDouble() : null;

    if (type == 'ELECTRICITY') {
      return ElectricityCable(
        id: json['id'],
        geometry: geom,
        depth: d,
        operatorName: json['operatorName'],
        contactPhone: json['contactPhone'],
        hazardLevel: json['hazardLevel'],
        status: json['status'],
      );
    } else if (type == 'GAS') {
      return GasPipe(
        id: json['id'],
        geometry: geom,
        depth: d,
        operatorName: json['operatorName'],
        contactPhone: json['contactPhone'],
        hazardLevel: json['hazardLevel'],
        status: json['status'],
      );
    } else {
      return WaterPipe(
        id: json['id'],
        geometry: geom,
        depth: d,
        operatorName: json['operatorName'],
        contactPhone: json['contactPhone'],
        hazardLevel: json['hazardLevel'],
        status: json['status'],
      );
    }
  }
}

class WaterPipe extends UtilityLine {
  final String? pipeType;
  final String? material;
  final int? diameterMm;
  final String? pressureLevel;

  WaterPipe({
    int? id,
    required List<dynamic> geometry,
    double? depth,
    String? operatorName,
    String? contactPhone,
    String? hazardLevel,
    String? status,
    this.pipeType,
    this.material,
    this.diameterMm,
    this.pressureLevel,
  }) : super(
          id: id,
          utilityType: 'WATER',
          geometry: geometry,
          depth: depth,
          operatorName: operatorName,
          contactPhone: contactPhone,
          hazardLevel: hazardLevel,
          status: status,
        );
}

class GasPipe extends UtilityLine {
  final String? pressureClass;
  final String? material;

  GasPipe({
    int? id,
    required List<dynamic> geometry,
    double? depth,
    String? operatorName,
    String? contactPhone,
    String? hazardLevel,
    String? status,
    this.pressureClass,
    this.material,
  }) : super(
          id: id,
          utilityType: 'GAS',
          geometry: geometry,
          depth: depth,
          operatorName: operatorName,
          contactPhone: contactPhone,
          hazardLevel: hazardLevel,
          status: status,
        );
}

class ElectricityCable extends UtilityLine {
  final String? voltageCategory;
  final int? voltageValue;
  final String? shieldingType;
  final int? numberOfCores;

  ElectricityCable({
    int? id,
    required List<dynamic> geometry,
    double? depth,
    String? operatorName,
    String? contactPhone,
    String? hazardLevel,
    String? status,
    this.voltageCategory,
    this.voltageValue,
    this.shieldingType,
    this.numberOfCores,
  }) : super(
          id: id,
          utilityType: 'ELECTRICITY',
          geometry: geometry,
          depth: depth,
          operatorName: operatorName,
          contactPhone: contactPhone,
          hazardLevel: hazardLevel,
          status: status,
        );
}
