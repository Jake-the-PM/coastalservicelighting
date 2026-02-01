import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import '../auth/login_screen.dart';
import '../splash/splash_screen.dart';

/// Root widget that handles auth state routing.
/// Shows loading -> Login (if not authenticated) or Splash (if authenticated)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    // Still loading auth state
    if (authService.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Not authenticated -> Login
    if (!authService.isAuthenticated) {
      return const LoginScreen();
    }

    // Authenticated -> Splash (which handles controller discovery routing)
    return const SplashScreen();
  }
}
