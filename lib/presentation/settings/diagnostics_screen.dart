import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/lighting_repository.dart';
import 'simulation_screen.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  late Future<int> _healthFuture;

  @override
  void initState() {
    super.initState();
    // Cache the future to avoid spamming the network on every rebuild
    final repo = context.read<LightingRepository>();
    _healthFuture = repo.checkNetworkHealth();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<LightingRepository>();
    final theme = Theme.of(context);

    // Mock Audit Log (In real app, fetch from local DB)
    final auditLogs = [
      "INFO: App started",
      if (repo.currentIp != null) "INFO: Connected to ${repo.currentIp}",
      "ACTION: Global Brightness changed to ${repo.globalBrightness}",
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Diagnostics', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(
              context, 
              title: "Controller Status",
              child: Column(
                children: [
                  _buildKeyValuePair("IP Address", repo.currentIp ?? "Disconnected"),
                  _buildKeyValuePair("Connection", repo.currentIp != null ? "Online (LAN)" : "Offline"),
                  _buildKeyValuePair("Zones Detected", "${repo.zones.length}"),
                  const Divider(),
                  FutureBuilder<int>(
                    future: _healthFuture,
                    builder: (context, snapshot) {
                      final score = snapshot.data ?? 0;
                      Color color = Colors.red;
                      if (score > 80) color = Colors.green;
                      else if (score > 50) color = Colors.orange;
                      
                      return Padding(
                         padding: const EdgeInsets.symmetric(vertical: 8.0),
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             const Text("Network Health", style: TextStyle(color: Colors.white60)),
                             Row(
                               children: [
                                 Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                 const SizedBox(width: 8),
                                 Text("$score/100", style: const TextStyle(fontWeight: FontWeight.bold)),
                               ],
                             ),
                           ],
                         ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              context,
              title: "Audit Log (Recent)",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var log in auditLogs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(log, style: const TextStyle(fontFamily: 'Courier', fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy, color: Colors.black),
              label: const Text('COPY DIAGNOSTICS BUNDLE', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final bundle = "IP: ${repo.currentIp}\nZones: ${repo.zones.length}\nLogs:\n${auditLogs.join('\n')}";
                Clipboard.setData(ClipboardData(text: bundle));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            const SizedBox(height: 16),
             OutlinedButton.icon(
              icon: const Icon(Icons.science, color: Colors.blueAccent),
              label: const Text('OPEN EVENT SIMULATOR (DEV)', style: TextStyle(color: Colors.blueAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blueAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SimulationScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18)),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildKeyValuePair(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(color: Colors.white60)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
