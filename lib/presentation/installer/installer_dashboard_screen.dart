import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/lighting_repository.dart';
import '../../data/services/installation_service.dart';
import '../../domain/models/installation.dart';
import '../dashboard/dashboard_screen.dart';
import 'create_installation_screen.dart';
import 'golden_key_screen.dart';
import 'scan_key_screen.dart';
import '../onboarding/zone_mapping_screen.dart';
import '../widgets/shimmer_effect.dart';
import '../widgets/feedback_widgets.dart';
import 'diagnostic_dashboard.dart';

class InstallerDashboardScreen extends StatefulWidget {
  const InstallerDashboardScreen({super.key});

  @override
  State<InstallerDashboardScreen> createState() => _InstallerDashboardScreenState();
}
class _InstallerDashboardScreenState extends State<InstallerDashboardScreen> {
  late Future<List<Installation>> _installationsFuture;

  @override
  void initState() {
    super.initState();
    _installationsFuture = context.read<InstallationService>().getInstallations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("MY FLEET", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white54),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanKeyScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white54),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticDashboard()));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD4AF37),
        label: Text("NEW INSTALL", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInstallationScreen()));
        },
      ),
      body: FutureBuilder<List<Installation>>(
        future: _installationsFuture,
        builder: (context, snapshot) {
          // Shimmer Loading State
          if (!snapshot.hasData) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              separatorBuilder: (_,__) => const SizedBox(height: 12),
              itemBuilder: (_, __) => const ShimmerInstallationCard(),
            );
          }
          
          final installations = snapshot.data!;

          // Empty State
          if (installations.isEmpty) {
            return EmptyState(
              icon: Icons.business,
              title: "No Active Installations",
              subtitle: "Tap '+ New Install' to add your first client.",
              actionLabel: "ADD FIRST CLIENT",
              onAction: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInstallationScreen()));
              },
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: installations.length,
            separatorBuilder: (_,__) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final install = installations[index];
              return _InstallationCard(installation: install);
            },
          );
        }
      ),
    );
  }
}

class _InstallationCard extends StatelessWidget {
  final Installation installation;

  const _InstallationCard({required this.installation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Load Client Context
        context.read<LightingRepository>().activateInstallation(installation);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      },
      child: Container(
        height: 140, // Fixed height for consistent look
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          image: installation.previewImage != null ? DecorationImage(
            image: NetworkImage(installation.previewImage!),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
          ) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(4)),
                    child: Text("ACTIVE", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: Colors.white54),
                    color: const Color(0xFF1E293B),
                    onSelected: (value) {
                      if (value == 'key') {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => GoldenKeyScreen(installation: installation))
                        );
                      } else if (value == 'config') {
                        // Load context and jump to setup
                        context.read<LightingRepository>().activateInstallation(installation);
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const ZoneMappingScreen(isCommissioning: true))
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'key',
                        child: Row(
                          children: [
                            const Icon(Icons.vpn_key, color: Color(0xFFD4AF37), size: 20),
                            const SizedBox(width: 12),
                            Text("Mint Golden Key", style: GoogleFonts.outfit(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'config',
                        child: Row(
                          children: [
                            const Icon(Icons.settings_input_component, color: Color(0xFFD4AF37), size: 20),
                            const SizedBox(width: 12),
                            Text("Configure Hardware", style: GoogleFonts.outfit(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    installation.customerName, 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          installation.address, 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${installation.controllerIps.length} Controllers • Installed ${DateFormat.yMMMd().format(installation.dateInstalled)}",
                    style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
