import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/lighting_repository.dart';

class DiagnosticDashboard extends StatelessWidget {
  const DiagnosticDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<LightingRepository>();
    final controllers = repo.controllers;

    return Scaffold(
      backgroundColor: const Color(0xFF050E1C),
      appBar: AppBar(
        title: Text("DIAGNOSTIC MASTER", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: controllers.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: controllers.length,
              itemBuilder: (context, index) {
                final ip = controllers.keys.elementAt(index);
                return _DiagnosticCard(ip: ip);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.biotech, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 24),
          const Text("No controllers detected", style: TextStyle(color: Colors.white30)),
        ],
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  final String ip;

  const _DiagnosticCard({required this.ip});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<LightingRepository>();
    final info = repo.getInfo(ip);
    final state = repo.getState(ip);
    final mac = repo.getMac(ip);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ip,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (state != null) ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (state != null) ? "ONLINE" : "OFFLINE",
                  style: TextStyle(
                    color: (state != null) ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),
          _buildInfoRow("MAC ADDRESS", mac ?? "UNKNOWN"),
          _buildInfoRow("FIRMWARE", info?.ver ?? "N/A"),
          _buildInfoRow("LED COUNT", info?.ledCount.toString() ?? "N/A"),
          _buildInfoRow("BRIGHTNESS", state?.bri.toString() ?? "N/A"),
          const SizedBox(height: 16),
          _buildInfoRow("SIGNAL (RSSI)", info != null ? "${info.rssi} dBm" : "N/A"),
          _buildInfoRow("FREE MEMORY", info != null ? "${(info.freeHeap / 1024).toStringAsFixed(1)} kB" : "N/A"),
          _buildInfoRow("UPTIME", info != null ? _formatUptime(info.uptime) : "N/A"), 
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => repo.addController(ip), // Ping / Refresh
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD4AF37)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("FORCE SYNC", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          Text(value, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inDays > 0) {
      return "${duration.inDays}d ${duration.inHours % 24}h";
    }
    return "${duration.inHours}h ${duration.inMinutes % 60}m";
  }
}
