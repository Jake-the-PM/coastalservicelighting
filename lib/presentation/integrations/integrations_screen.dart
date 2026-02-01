import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/integrations/homekit_bridge_service.dart';
import '../../data/integrations/alexa_skill_service.dart';
import '../widgets/liquid_container.dart';
import '../widgets/gold_button.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Integrations",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "Voice Assistants & Smart Home",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Connect Coastal Lighting to your favorite smart home platforms.",
              style: GoogleFonts.outfit(color: Colors.white54),
            ),
            const SizedBox(height: 24),

            // HomeKit Card
            _IntegrationCard(
              title: "Apple HomeKit",
              subtitle: "Control with Siri and Home app",
              icon: Icons.apple,
              iconColor: Colors.white,
              status: IntegrationStatus.notConfigured,
              onTap: () => _showHomeKitSetup(context),
            ),
            const SizedBox(height: 16),

            // Alexa Card
            _IntegrationCard(
              title: "Amazon Alexa",
              subtitle: "Voice control with Alexa",
              icon: Icons.record_voice_over,
              iconColor: const Color(0xFF00CAFF),
              status: IntegrationStatus.notConfigured,
              onTap: () => _showAlexaSetup(context),
            ),
            const SizedBox(height: 16),

            // Google Home Card (Coming Soon)
            _IntegrationCard(
              title: "Google Home",
              subtitle: "Hey Google integration",
              icon: Icons.home_max,
              iconColor: Colors.redAccent,
              status: IntegrationStatus.comingSoon,
              onTap: null,
            ),
            const SizedBox(height: 32),

            // IFTTT Section
            Text(
              "Automation Platforms",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            _IntegrationCard(
              title: "IFTTT",
              subtitle: "Connect to 700+ services",
              icon: Icons.alt_route,
              iconColor: Colors.white,
              status: IntegrationStatus.comingSoon,
              onTap: null,
            ),
            const SizedBox(height: 16),

            _IntegrationCard(
              title: "Home Assistant",
              subtitle: "Open-source home automation",
              icon: Icons.hub,
              iconColor: const Color(0xFF41BDF5),
              status: IntegrationStatus.available,
              onTap: () => _showHomeAssistantInfo(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showHomeKitSetup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _HomeKitSetupSheet(),
    );
  }

  void _showAlexaSetup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AlexaSetupSheet(),
    );
  }

  void _showHomeAssistantInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Home Assistant Integration",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "WLED controllers are natively supported by Home Assistant!\n\n"
                "Simply add the WLED integration in Home Assistant:\n\n"
                "1. Go to Settings → Devices & Services\n"
                "2. Click 'Add Integration'\n"
                "3. Search for 'WLED'\n"
                "4. Enter your controller IP\n\n"
                "Your lights will appear automatically.",
                style: GoogleFonts.outfit(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              GoldButtonFull(
                label: "GOT IT",
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum IntegrationStatus { notConfigured, configured, comingSoon, available }

class _IntegrationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final IntegrationStatus status;
  final VoidCallback? onTap;

  const _IntegrationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = status == IntegrationStatus.comingSoon;
    
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: LiquidContainer(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
          ),
          trailing: _buildStatusBadge(context),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    switch (status) {
      case IntegrationStatus.configured:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Connected",
            style: GoogleFonts.outfit(color: Colors.green, fontSize: 12),
          ),
        );
      case IntegrationStatus.comingSoon:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Coming Soon",
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
          ),
        );
      case IntegrationStatus.available:
        return const Icon(Icons.chevron_right, color: Colors.white54);
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Set Up",
            style: GoogleFonts.outfit(color: Theme.of(context).primaryColor, fontSize: 12),
          ),
        );
    }
  }
}

class _HomeKitSetupSheet extends StatelessWidget {
  const _HomeKitSetupSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.apple, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  "HomeKit Setup",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              "Requirements",
              HomeKitSetupGuide.requirements,
              Icons.checklist,
            ),
            const SizedBox(height: 20),
            
            _buildSection(
              "Setup Steps",
              HomeKitSetupGuide.steps,
              Icons.format_list_numbered,
            ),
            const SizedBox(height: 20),
            
            Text(
              "Homebridge Config",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    HomebridgeConfigGenerator.generateConfig(
                      bridgeName: 'Coastal Bridge',
                      pin: '031-45-154',
                      devices: [
                        WledDevice(name: 'Front Porch', ip: '192.168.1.100'),
                        WledDevice(name: 'Backyard', ip: '192.168.1.101'),
                      ],
                    ).toString(),
                    style: GoogleFonts.sourceCodePro(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'Config copied'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Config copied to clipboard')),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.copy, color: Color(0xFFD4AF37), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Copy Config",
                          style: GoogleFonts.outfit(color: const Color(0xFFD4AF37)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            GoldButtonFull(
              label: "LEARN MORE",
              onPressed: () {
                // Open Homebridge docs
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 4),
          child: Text(
            item,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
          ),
        )),
      ],
    );
  }
}

class _AlexaSetupSheet extends StatelessWidget {
  const _AlexaSetupSheet();

  @override
  Widget build(BuildContext context) {
    final alexaService = AlexaSkillService();
    
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.record_voice_over, color: Color(0xFF00CAFF), size: 32),
                const SizedBox(width: 12),
                Text(
                  "Alexa Setup",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Text(
              "Example Commands",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...alexaService.exampleCommands.map((cmd) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00CAFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00CAFF).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Color(0xFF00CAFF), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"$cmd"',
                      style: GoogleFonts.outfit(color: Colors.white, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 24),
            
            Text(
              "Setup Requirements",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...AlexaSetupGuide.requirements.map((req) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(color: Colors.white54)),
                  Expanded(
                    child: Text(
                      req,
                      style: GoogleFonts.outfit(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Alexa integration requires a Pro subscription and AWS Lambda setup.",
                      style: GoogleFonts.outfit(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            GoldButtonFull(
              label: "VIEW FULL GUIDE",
              onPressed: () {
                // Open documentation
              },
            ),
          ],
        ),
      ),
    );
  }
}
