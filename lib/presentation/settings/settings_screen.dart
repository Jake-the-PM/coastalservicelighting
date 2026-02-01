import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/lighting_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/installation_service.dart';
import '../onboarding/zone_mapping_screen.dart';
import '../widgets/liquid_container.dart';
import '../widgets/living_background.dart';
import '../installer/installer_dashboard_screen.dart';
import '../onboarding/discovery_screen.dart';
import '../schedules/schedules_screen.dart';
import '../integrations/integrations_screen.dart';
import 'help_guides_screen.dart';
import 'diagnostics_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedInstallationId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchInstallationId();
  }

  Future<void> _fetchInstallationId() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;
    
    if (uid != null) {
      final service = InstallationService();
      // Heuristic: If installer -> fetch their installs. If homeowner -> fetch theirs.
      // For V1 "Bridge on Tablet", usually it's the Installer setting it up OR Homeowner.
      // Let's try fetching installer ones first, assuming this is an Installer logged in.
      var installs = await service.getInstallerInstallations(uid).first;
      if (!mounted) return;
      
      if (installs.isNotEmpty) {
           setState(() {
            _selectedInstallationId = installs.first.id;
            _loading = false;
          });
      } else {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<LightingRepository>();
    final auth = context.read<AuthService>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("Settings", style: GoogleFonts.outfit(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: LivingBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
        children: [
          // 1. Zone Configuration
          _SettingsTile(
            icon: Icons.grid_view_rounded,
            title: "Configure Zones",
            subtitle: "Map segments, LED counts, and names",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ZoneMappingScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // 1b. Installer Fleet (Pro Tool)
          _SettingsTile(
            icon: Icons.business_center,
            title: "Installer Fleet",
            subtitle: "Manage all your client installations",
            color: const Color(0xFFD4AF37),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InstallerDashboardScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // 1c. Device Discovery
          _SettingsTile(
            icon: Icons.wifi_find,
            title: "Find Devices",
            subtitle: "Scan network for WLED controllers",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiscoveryScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // 1d. Schedules
          _SettingsTile(
            icon: Icons.schedule,
            title: "Schedules",
            subtitle: "Sunrise, sunset, and timed automation",
            color: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SchedulesScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // 1e. Integrations
          _SettingsTile(
            icon: Icons.extension,
            title: "Integrations",
            subtitle: "HomeKit, Alexa, Google Home",
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IntegrationsScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // 2. Bridge Mode (Remote Relay)
          LiquidContainer(
            padding: const EdgeInsets.all(16),
            isActive: repo.isBridgeActive,
            activeColor: const Color(0xFF00BFA6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_sync, color: Color(0xFF00BFA6)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Bridge Mode", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("Turn this device into a Remote Gateway", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (_loading)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Switch(
                        value: repo.isBridgeActive,
                        activeColor: const Color(0xFF00BFA6),
                        onChanged: _selectedInstallationId == null ? null : (val) {
                          repo.enableBridgeMode(_selectedInstallationId!, val);
                        },
                      ),
                  ],
                ),
                if (_selectedInstallationId == null && !_loading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "No installation found. Create a job first.",
                      style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                if (repo.isBridgeActive)
                   Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          "Gateway Active - Listening for commands...",
                          style: GoogleFonts.outfit(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                   ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 2b. Help & Guides
          _SettingsTile(
            icon: Icons.help_outline,
            title: "Help & Guides",
            subtitle: "Installation and setup documentation",
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpGuidesScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // 2c. Diagnostics
          _SettingsTile(
            icon: Icons.monitor_heart,
            title: "Diagnostics",
            subtitle: "System health and logs",
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // 3. Account
          _SettingsTile(
            icon: Icons.logout,
            title: "Sign Out",
            subtitle: auth.currentUser?.email ?? "Guest",
            color: Colors.redAccent,
            onTap: () async {
              await auth.signOut();
              await context.read<LightingRepository>().clearActiveSession();
              if (mounted) Navigator.of(context).pop(); // Or trigger redirect via AuthGate
            },
          ),
        ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon, 
    required this.title, 
    required this.subtitle, 
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LiquidContainer(
        onTap: onTap,
        padding: EdgeInsets.zero,
        isActive: false,
        child: ListTile(
          // tileColor not needed as LiquidContainer has its own background
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? Colors.white),
          ),
          title: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        ),
      ),
    );
  }
}
