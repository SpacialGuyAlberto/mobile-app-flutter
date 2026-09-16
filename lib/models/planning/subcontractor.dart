import 'organization.dart';
import 'crew.dart';
import 'enums/other_enums.dart';

class Subcontractor {
  final String id;
  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final double? rating;
  final SubcontractorStatus status;
  final List<String> skills;
  final List<String> certifications;
  final double? averageTimePerMeter;
  final double? defectRate;
  final double? reworkFrequency;
  final List<Crew> crews;
  final Organization? organization;

  const Subcontractor({
    required this.id,
    required this.name,
    this.contactPerson,
    this.email,
    this.phone,
    this.rating,
    this.status = SubcontractorStatus.active,
    this.skills = const [],
    this.certifications = const [],
    this.averageTimePerMeter,
    this.defectRate,
    this.reworkFrequency,
    this.crews = const [],
    this.organization,
  });
}
