import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleLogin() {
    final username = _usernameController.text;
    final password = _passwordController.text;
    
    if (username.isNotEmpty && password.isNotEmpty) {
      ref.read(authProvider.notifier).login(username, password);
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'QuarkBau',
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 48),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Field Operations Portal',
                    style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'USERNAME',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'obrero, projekt, bauleiter',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'PASSWORD',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                  ),
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _handleLogin,
                  child: const Text('SECURE LOGIN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

