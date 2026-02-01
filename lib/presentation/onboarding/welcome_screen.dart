import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/lighting_repository.dart';
import '../../data/services/mdns_service.dart';
import 'zone_mapping_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _ipController = TextEditingController(text: "4.3.2.1"); // WLED AP Default
  final MDnsDiscoveryService _discovery = MDnsDiscoveryService();
  bool _isLoading = false;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _startAutoScan();
  }

  Future<void> _startAutoScan() async {
    final ip = await _discovery.findFirstWled();
    if (mounted && ip != null) {
      setState(() {
        _ipController.text = ip;
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Discovered WLED at $ip')),
      );
    } else if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connect() async {
    setState(() => _isLoading = true);
    final ip = _ipController.text.trim();
    final repo = context.read<LightingRepository>();

    // Hardening: Verify connectivity & Identity
    final success = await repo.addController(ip);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ZoneMappingScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection Failed: Unreachable or Invalid Device')),
        );
      }
    }
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lightbulb_outline, size: 64, color: Color(0xFF00BFA6)), // Coastal Teal
              const SizedBox(height: 24),
              Text(
                'Coastal Services', 
                style: theme.textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Permanent Lighting Control',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Connect Controller', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'Device IP Address',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 4.3.2.1',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _connect,
                          child: _isLoading 
                            ? const CircularProgressIndicator()
                            : const Text('CONNECT & CONFIGURE'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Installer Setup Wizard',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
