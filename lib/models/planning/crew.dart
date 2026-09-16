import 'organization.dart';
import 'subcontractor.dart';
import 'employee.dart';
import 'enums/other_enums.dart';

class Crew {
  final String id;
  final String name;
  final CrewType type;
  final Organization? organization;
  final Subcontractor? subcontractor;
  final List<Employee> members;

  const Crew({
    required this.id,
    required this.name,
    required this.type,
    this.organization,
    this.subcontractor,
    this.members = const [],
  });
}
