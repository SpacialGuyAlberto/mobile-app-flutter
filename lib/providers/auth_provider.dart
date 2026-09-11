import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole {
  obrero,
  projekt,
  bauleiter,
  none
}

class AuthState {
  final bool isAuthenticated;
  final UserRole role;
  final String userName;

  AuthState({
    required this.isAuthenticated,
    required this.role,
    required this.userName,
  });

  factory AuthState.initial() {
    return AuthState(
      isAuthenticated: false,
      role: UserRole.none,
      userName: '',
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial());

  void login(String username, String password) {
    // Mock login based on role
    UserRole role = UserRole.obrero;
    if (username.contains('admin') || username.contains('projekt')) {
      role = UserRole.projekt;
    } else if (username.contains('bauleiter')) {
      role = UserRole.bauleiter;
    }

    state = AuthState(
      isAuthenticated: true,
      role: role,
      userName: username,
    );
  }

  void logout() {
    state = AuthState.initial();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
