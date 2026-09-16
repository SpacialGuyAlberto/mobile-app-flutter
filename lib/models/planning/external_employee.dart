import 'employee.dart';
import 'company_role.dart';

class ExternalEmployee extends Employee {
  final String subcontractorId;

  const ExternalEmployee({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.role,
    super.enabled = true,
    required this.subcontractorId,
  });
}
