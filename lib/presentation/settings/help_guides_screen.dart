import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/liquid_container.dart';

class HelpGuidesScreen extends StatelessWidget {
  const HelpGuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("System Guides", style: GoogleFonts.outfit(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGuideTile(
            context,
            title: "Provisioning Guide",
            subtitle: "How to set up new hardware clients",
            icon: Icons.settings_input_component,
            content: "1. Connect WLED to client's WiFi\n"
                    "2. Assign Static IP in Router\n"
                    "3. Enter IP in App Settings → Discovery\n"
                    "4. Name the zones and test connectivity.",
          ),
          const SizedBox(height: 16),
          _buildGuideTile(
            context,
            title: "Physical Button Integration",
            subtitle: "Wiring external switches to WLED",
            icon: Icons.power_settings_new,
            content: "Connect G-VCC and Pin D2 to your physical momentary switch.\n"
                    "In WLED UI:\n"
                    "1. Config → LED Preferences\n"
                    "2. Button Setup → GPIO 2\n"
                    "3. Select 'Pushbutton' mode.",
          ),
          const SizedBox(height: 16),
          _buildGuideTile(
            context,
            title: "Remote Access (Bridge)",
            subtitle: "Enabling control via Cloud Relay",
            icon: Icons.cloud_circle,
            content: "1. Log in to your installer account\n"
                    "2. Navigate to Settings → Bridge Mode\n"
                    "3. Flip the switch to 'On'\n"
                    "4. This device will now relay internet commands to local lights.",
          ),
          const SizedBox(height: 16),
          _buildGuideTile(
            context,
            title: "Supabase Setup",
            subtitle: "Database and Auth configuration",
            icon: Icons.storage,
            content: "The app uses Supabase for Fleet Management.\n"
                    "Ensure your URL and Anon Key are correct in 'supabase_config.dart'.\n"
                    "Verification: 'AuthService' will show 'Connected' in Diagnostics.",
          ),
          const SizedBox(height: 16),
          _buildGuideTile(
            context,
            title: "Alexa & HomeKit",
            subtitle: "Voice control and mobile ecosystems",
            icon: Icons.speaker_group,
            content: "**HomeKit:** Requires HomeBridge with 'homebridge-wled' plugin.\n"
                    "**Alexa:** Enable WLED Native Alexa in Segments → Sync.\n"
                    "Or use our Cloud Skill (Coming Soon) for advanced scenes.",
          ),
        ],
      ),
    );
  }

  Widget _buildGuideTile(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String content,
  }) {
    return LiquidContainer(
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
        childrenPadding: const EdgeInsets.all(16),
        iconColor: Colors.white54,
        collapsedIconColor: Colors.white54,
        children: [
          Text(
            content,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
