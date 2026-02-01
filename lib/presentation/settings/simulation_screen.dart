import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/contracts/schemas.dart';
import '../../data/services/rule_engine_stub.dart';
import '../../data/services/automation_service.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  late RuleEngineStub _stub;

  @override
  void initState() {
    super.initState();
    // In a real app we might put this in Provider, but for Stubbing it's fine here.
    final automationService = context.read<AutomationService>();
    _stub = RuleEngineStub(automationService);
  }

  Future<void> _simulate(String type) async {
    final event = IntegrationEvent(
      eventId: DateTime.now().toIso8601String(),
      type: type,
      sourceId: 'sim-device-1',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Injecting $type Event...'), duration: const Duration(milliseconds: 500)),
    );

    await _stub.ingestEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Simulator (Phase 2)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
             const Text(
              'Inject Rocket.new Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
               'Verify that the App correctly responds to external signals without needing the actual cloud connection.',
               style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 32),

            _buildSimButton(
              icon: Icons.directions_walk,
              label: "Simulate Motion (Zone 1)",
              color: Colors.amber,
              onPressed: () => _simulate('MOTION'),
            ),
            const SizedBox(height: 16),
            _buildSimButton(
              icon: Icons.doorbell,
              label: "Simulate Doorbell (Zone 1+2)",
              color: Colors.blueAccent,
              onPressed: () => _simulate('DOORBELL'),
            ),
            const SizedBox(height: 16),
            _buildSimButton(
              icon: Icons.mic,
              label: "Simulate Alexa 'Turn On'",
              color: Colors.cyan,
              onPressed: () => _simulate('ALEXA'),
            ),
            
            const Divider(height: 48),
            const Text("Latency Diagnostics", style: TextStyle(fontWeight: FontWeight.bold)),
            const ListTile(
              title: Text("Avg TTI (Time to Illuminance)"),
              trailing: Text("~45ms (Local)"), // Hardcoded estimation for now
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color, 
        alignment: Alignment.centerLeft,
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
