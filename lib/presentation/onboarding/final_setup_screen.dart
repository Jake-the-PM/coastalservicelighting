import 'package:flutter/material.dart';
import '../../core/constants/app_specs.dart';
import '../navigation/main_navigation.dart';

class FinalSetupScreen extends StatelessWidget {
  const FinalSetupScreen({super.key});

  void _finishSetup(BuildContext context) {
    // In a real app, we would write a "setup_complete" flag to SharedPreferences here.
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFF00BFA6)),
              const SizedBox(height: 32),
              Text(
                'Setup Complete',
                style: theme.textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Zones are mapped and verified.\nStandard defaults have been applied.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 48),
              
              // Option to check "Leave in Advanced Mode"
              // For v1 we assume Basic Mode by default.
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _finishSetup(context),
                  child: const Text('HANDOFF TO CUSTOMER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
