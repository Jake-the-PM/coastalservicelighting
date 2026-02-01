
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../../data/repositories/lighting_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/installation_service.dart';
import '../onboarding/discovery_screen.dart';
import '../installer/installer_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(seconds: 2), 
       vsync: this,
    )..repeat(reverse: true);
    
    _animation = curvedAnimation(_controller);
    
    _bootstrap();
  }
  
  Animation<double> curvedAnimation(AnimationController controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeInOut);
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    setState(() => _errorMessage = null);

    try {
      // 1. Determine destination based on user role and controller state
      final authService = context.read<AuthService>();
      final repo = context.read<LightingRepository>();
      final installService = context.read<InstallationService>();
      
      // HYDRATION GATE: Reconnect to last active controller session
      if (repo.activeInstallationId != null) {
        final installations = await installService.getInstallations();
        final index = installations.indexWhere((i) => i.id == repo.activeInstallationId);
        if (index >= 0) {
          await repo.activateInstallation(installations[index]);
        }
      }

      Widget destination;
      
      // Check role
      if (authService.isInstaller) {
        // Installers go to their fleet management dashboard
        destination = const InstallerDashboardScreen();
      } else {
        // Homeowners: Check if they have an installation or can claim one
        final service = InstallationService();
        final uid = authService.currentUser?.uid;
        
        bool hasInstallation = false;
        
        if (uid != null) {
          // 1. Check existing ownership
          final owned = await service.getHomeownerInstallations(uid).first;
          if (owned.isNotEmpty) {
            hasInstallation = true;
          } else {
            // 2. Check pending assignment (Auto-Claim)
            final email = authService.currentUser?.email;
            if (email != null) {
              final assigned = await service.getAssignedInstallations(email);
              if (assigned.isNotEmpty) {
                 // Claim the first one found
                 final success = await service.claimInstallation(assigned.first.id, uid);
                 if (success) hasInstallation = true;
              }
            }
          }
        }

        destination = hasInstallation 
            ? const DashboardScreen()
            : const DiscoveryScreen();
      }
      
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "System Error: ${e.toString()}";
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using the Navy background from Theme
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                image: const DecorationImage(
                   image: AssetImage('assets/images/logo.png'),
                   fit: BoxFit.contain, // Contain to respect aspect ratio
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // SYSTEM STATUS
           FadeTransition(
             opacity: _animation,
             child: Column(
               children: [
                 Text(
                   "COASTAL SERVICES",
                   style: theme.textTheme.headlineSmall?.copyWith(
                     fontWeight: FontWeight.bold,
                     letterSpacing: 1.5,
                     color: Colors.white,
                   ),
                 ),
                 const SizedBox(height: 8),
                 if (_errorMessage != null) ...[
                  const Text(
                    "CONNECTION ERROR", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)
                  ),
                 ] else ...[
                   Text(
                     "INITIALIZING CONTROLLERS...",
                     style: theme.textTheme.labelMedium?.copyWith(
                       color: theme.colorScheme.onSurface.withOpacity(0.5),
                       letterSpacing: 2.0,
                     ),
                   ),
                 ],
               ],
             ),
           ),
          ],
        ),
      ),
    );
  }
}
