import '../planning/employee.dart';
import 'user_role.dart';

class User {
  final String id;
  final Employee employee;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final bool enabled;
  final String? organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.employee,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.enabled = true,
    this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });
}
