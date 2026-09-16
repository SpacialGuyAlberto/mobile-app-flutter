import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth/user.dart';
import '../models/auth/user_role.dart';
import '../models/planning/company_role.dart';
import '../models/planning/internal_employee.dart';
import '../models/planning/external_employee.dart';
import '../models/planning/employee.dart';

class AuthState {
  final bool isAuthenticated;
  final User? user;

  AuthState({
    required this.isAuthenticated,
    this.user,
  });

  factory AuthState.initial() {
    return AuthState(
      isAuthenticated: false,
      user: null,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial());

  void login(String username, String password) {
    // Mock login based on role
    UserRole userRole = UserRole.fieldExpert;
    Employee employee;

    if (username.contains('admin') || username.contains('projekt')) {
      userRole = UserRole.projectManager;
      employee = InternalEmployee(
        id: '2',
        email: 'admin@quarkbau.com',
        firstName: 'Admin',
        lastName: 'User',
        role: CompanyRole.projektManager,
        organizationId: 'org1',
      );
    } else if (username.contains('bauleiter')) {
      userRole = UserRole.manager;
      employee = InternalEmployee(
        id: '3',
        email: 'bauleiter@quarkbau.com',
        firstName: 'Site',
        lastName: 'Manager',
        role: CompanyRole.bauleiter,
        organizationId: 'org1',
      );
    } else {
      employee = ExternalEmployee(
        id: '1',
        email: 'obrero@subcontractor.com',
        firstName: 'Field',
        lastName: 'Worker',
        role: CompanyRole.subcontractorFieldExpert,
        subcontractorId: 'sub1',
      );
    }

    final user = User(
      id: 'u1',
      employee: employee,
      email: employee.email,
      firstName: employee.firstName,
      lastName: employee.lastName,
      role: userRole,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = AuthState(
      isAuthenticated: true,
      user: user,
    );
  }

  void logout() {
    state = AuthState.initial();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
