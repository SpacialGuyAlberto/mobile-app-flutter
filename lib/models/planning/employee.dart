import 'company_role.dart';

abstract class Employee {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final CompanyRole role;
  final bool enabled;

  const Employee({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.enabled = true,
  });
}
