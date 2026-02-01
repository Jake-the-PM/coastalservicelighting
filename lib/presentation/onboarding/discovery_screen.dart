import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/services/device_discovery_service.dart';
import '../../data/repositories/lighting_repository.dart';
import '../../data/services/installation_service.dart';
import '../../domain/models/installation.dart';
import '../dashboard/dashboard_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _manualController = TextEditingController();
  late DeviceDiscoveryService _discoveryService;

  @override
  void initState() {
    super.initState();
    _discoveryService = DeviceDiscoveryService();
    _discoveryService.startDiscovery();
  }

  @override
  void dispose() {
    _discoveryService.stopDiscovery();
    _manualController.dispose();
    super.dispose();
  }

  void _addDevice(String ip) async {
    final repo = context.read<LightingRepository>();
    final success = await repo.addController(ip);
    
    if (mounted) {
      if (success) {
        // Gate 1 Audit: Create a persistent installation for this discovery to enable "lock-in"
        final newInstall = Installation(
          id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
          customerName: 'My Home',
          address: 'Local Connection',
          dateInstalled: DateTime.now(),
          controllerIps: [ip],
        );
        await context.read<InstallationService>().saveInstallation(newInstall);
        await repo.activateInstallation(newInstall);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Device Connected & Locked"),
            backgroundColor: Color(0xFFD4AF37),
          ),
        );
        
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          // If we're the root route (from Splash), go to Dashboard
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to connect to $ip"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("FIND DEVICES", style: GoogleFonts.outfit(color: Colors.white, letterSpacing: 1.5)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _discoveryService.startDiscovery(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _discoveryService,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              // Scanning Status
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (_discoveryService.isScanning) ...[
                        const CircularProgressIndicator(color: Color(0xFFD4AF37)),
                        const SizedBox(height: 16),
                        Text(
                          "Scanning network...",
                          style: GoogleFonts.outfit(color: Colors.white54),
                        ),
                      ] else if (_discoveryService.error != null) ...[
                        Icon(Icons.wifi_off, size: 48, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          _discoveryService.error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.white54),
                        ),
                      ] else if (_discoveryService.devices.isEmpty) ...[
                        Icon(Icons.search_off, size: 48, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          "No devices found.\nMake sure WLED is powered on.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.white54),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Discovered Devices
              if (_discoveryService.devices.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final device = _discoveryService.devices[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ListTile(
                            onTap: () => _addDevice(device.ip),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lightbulb, color: Color(0xFFD4AF37)),
                            ),
                            title: Text(
                              device.name,
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              device.ip,
                              style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.add_circle, color: Color(0xFFD4AF37)),
                          ),
                        );
                      },
                      childCount: _discoveryService.devices.length,
                    ),
                  ),
                ),

              // Manual Entry Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),
                      Text(
                        "MANUAL ENTRY",
                        style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualController,
                              style: GoogleFonts.robotoMono(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "192.168.1.100 or 'demo'",
                                hintStyle: GoogleFonts.robotoMono(color: Colors.white24),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (_manualController.text.isNotEmpty) {
                                _addDevice(_manualController.text.trim());
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("ADD"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
