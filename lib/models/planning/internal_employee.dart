import 'employee.dart';
import 'company_role.dart';

class InternalEmployee extends Employee {
  final String organizationId;

  const InternalEmployee({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.role,
    super.enabled = true,
    required this.organizationId,
  });
}
