import '../auth/user.dart';
import 'segment.dart';
import 'enums/hazard_status.dart';
import 'enums/hazard_severity_level.dart';
import 'enums/hazard_type.dart';

class Hazard {
  final String id;
  final Segment segment;
  final String? description;
  final User? reportedBy;
  final HazardStatus? status;
  final HazardSeverityLevel? severity;
  final HazardType? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? photoEvidenceUrl;

  const Hazard({
    required this.id,
    required this.segment,
    this.description,
    this.reportedBy,
    this.status,
    this.severity,
    this.type,
    this.createdAt,
    this.updatedAt,
    this.photoEvidenceUrl,
  });
}
