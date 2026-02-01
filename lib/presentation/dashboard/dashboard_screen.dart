import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/lighting_repository.dart';
import '../../data/services/auth_service.dart';
import '../../core/constants/app_specs.dart';
import '../settings/settings_screen.dart';
import '../widgets/liquid_container.dart';
import '../widgets/living_background.dart';
import '../widgets/living_background.dart';
import 'zone_detail_sheet.dart';
import 'scene_editor_sheet.dart';
import '../installer/installer_provisioning_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _openSceneEditor(BuildContext context, String title, String id) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: SceneEditorSheet(title: title, sceneId: id, isDialog: true),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SceneEditorSheet(title: title, sceneId: id, isDialog: false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<LightingRepository>();
    final authService = context.watch<AuthService>();
    final zones = repo.zones;
    final theme = Theme.of(context);
    final isMasterOn = zones.any((z) => z.isOn);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF050E1C), // Deep Navy Background
      body: LivingBackground(
        child: Stack(
          children: [

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                // Floating Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Image.asset('assets/images/logo.jpg', height: 40),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppSpecs.appName.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                              color: Colors.white54,
                            ),
                          ),
                          Text(
                            "Welcome, ${authService.currentUser?.fullName?.split(' ').first ?? 'Home'}",
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      LiquidIconButton(
                        icon: Icons.settings,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: IgnorePointer(
                    ignoring: repo.isOffline,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: repo.isOffline ? 0.5 : 1.0,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        children: [
                          const SizedBox(height: 12),
                          
                          // MASTER CONTROL CARD
                          LiquidContainer(
                            padding: const EdgeInsets.all(24),
                            isActive: isMasterOn,
                            activeColor: const Color(0xFFD4AF37),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isMasterOn ? "Good Evening" : "Lights Off",
                                          style: GoogleFonts.outfit(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${zones.where((z) => z.isOn).length} zones active",
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Transform.scale(
                                      scale: 1.2,
                                      child: Switch(
                                        value: isMasterOn,
                                        activeColor: const Color(0xFFD4AF37),
                                        onChanged: (val) {
                                          for (var z in zones) {
                                            repo.setZoneBrightness(
                                                z.controllerIp, z.id, val ? 255 : 0);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.wb_sunny_outlined, color: Colors.white54, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SliderTheme(
                                        data: theme.sliderTheme.copyWith(
                                          trackHeight: 4,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                        ),
                                        child: Slider(
                                          value: repo.globalBrightness.toDouble(),
                                          min: 0,
                                          max: 255,
                                          activeColor: Colors.white,
                                          inactiveColor: Colors.white10,
                                          onChanged: (val) => repo.setGlobalBrightness(val.round()),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // SCENES GRID
                          Text(
                            "SCENES",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                            children: [
                              _SceneCard(
                                title: "Welcome",
                                subtitle: "Doorbell", 
                                icon: Icons.door_front_door_outlined,
                                isActive: repo.lastPresetId == 1,
                                onTap: () => _openSceneEditor(context, "Welcome", "welcome"),
                              ),
                              _SceneCard(
                                title: "Security",
                                subtitle: "Motion", 
                                icon: Icons.shield_outlined,
                                isActive: repo.securityModeEnabled,
                                isSecurity: true,
                                onTap: () => _openSceneEditor(context, "Security", "security"),
                              ),
                              _SceneCard(
                                title: "Non-Seasonal", // Default
                                subtitle: "Accent",
                                icon: Icons.landscape_outlined,
                                isActive: repo.lastPresetId == 2,
                                onTap: () => repo.applyPreset(2), // Keep simple for now? User might want to edit this too.
                              ),
                              _SceneCard(
                                title: "Seasonal",
                                subtitle: "Auto",
                                icon: Icons.calendar_month_outlined,
                                isActive: false, 
                                onTap: () => repo.applySeasonalTheme(), // Keep auto for now? Or allow override?
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // INDIVIDUAL ZONES
                          Text(
                            "ZONES",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...zones.map((zone) => _ZoneRow(
                                label: zone.label,
                                isOn: zone.isOn,
                                value: zone.brightness,
                                onTap: () {
                                  final isDesktop = MediaQuery.of(context).size.width > 600;
                                  if (isDesktop) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: const EdgeInsets.all(24),
                                        child: ZoneDetailSheet(
                                          controllerIp: zone.controllerIp,
                                          zoneId: zone.id,
                                          label: zone.label,
                                          isDialog: true,
                                        ),
                                      ),
                                    );
                                  } else {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => ZoneDetailSheet(
                                        controllerIp: zone.controllerIp,
                                        zoneId: zone.id,
                                        label: zone.label,
                                        isDialog: false,
                                      ),
                                    );
                                  }
                                },
                                onChanged: (val) => repo.setZoneBrightness(
                                    zone.controllerIp, zone.id, val.round()),
                                onToggle: (val) => repo.setZoneBrightness(
                                    zone.controllerIp, zone.id, val ? 255 : 0),
                              )),
                          
                          const SizedBox(height: 80), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Offline Overlay
          if (repo.isOffline)
            Container(
              color: Colors.black54,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      color: Colors.white.withValues(alpha: 0.1),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.white54, size: 48),
                          const SizedBox(height: 16),
                          Text("Disconnected", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

// --- PREMIUM WIDGETS ---



class _SceneCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isActive;
  final bool isSecurity;
  final VoidCallback onTap;

  const _SceneCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.isSecurity = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isSecurity ? const Color(0xFFCF6679) : const Color(0xFFD4AF37); // Red for security, Gold for others

    return LiquidContainer(
      onTap: onTap,
      isActive: isActive,
      activeColor: activeColor,
      padding: EdgeInsets.zero,
      child: Container( // maintain sizing or sizing constraints if needed
        height: 100, // Scene cards are usually square-ish, GridView handles W/H aspect
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? activeColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(icon, color: isActive ? activeColor : Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : Colors.white70,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.white38,
                  letterSpacing: 1.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final String label;
  final bool isOn;
  final int value;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  const _ZoneRow({
    required this.label,
    required this.isOn,
    required this.value,
    required this.onChanged,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: LiquidContainer(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isActive: isOn,
        activeColor: const Color(0xFFD4AF37),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.light_mode, 
                      color: isOn ? const Color(0xFFD4AF37) : Colors.white38, 
                      size: 20
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isOn,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: onToggle,
                ),
              ],
            ),
            if (isOn)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SliderTheme(
                  data: Theme.of(context).sliderTheme.copyWith(
                    trackHeight: 2,
                    overlayShape: SliderComponentShape.noOverlay,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: 0,
                    max: 255,
                    activeColor: const Color(0xFFD4AF37),
                    inactiveColor: Colors.white10,
                    onChanged: onChanged,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
