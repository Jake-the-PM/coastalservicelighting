
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:coastal_services_lighting/data/repositories/lighting_repository.dart';
import 'package:coastal_services_lighting/data/wled/wled_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // For SharedPreferences

  group('Cycle 4: Mock Fleet Verification', () {
    late LightingRepository repo;
    
    // Virtual Device State
    Map<String, Map<String, dynamic>> virtualDevices = {
      '192.168.1.10': { // "Pool House"
        'info': {'mac': 'AA:BB:CC:DD:EE:10', 'name': 'Pool House', 'ver': '0.14.0'},
        'state': {
          'on': true,
          'bri': 128,
          'seg': [
            {'id': 0, 'start': 0, 'stop': 30, 'on': true, 'bri': 255, 'n': 'Pool Eaves'},
            {'id': 1, 'start': 30, 'stop': 50, 'on': false, 'bri': 0, 'n': 'Pool Bar'}
          ]
        }
      },
      '192.168.1.11': { // "Patio"
        'info': {'mac': 'AA:BB:CC:DD:EE:11', 'name': 'Patio', 'ver': '0.14.0'},
        'state': {
          'on': true,
          'bri': 128,
          'seg': [
             {'id': 0, 'start': 0, 'stop': 20, 'on': true, 'bri': 100, 'n': 'Patio Railing'}
          ]
        }
      }
    };

    // Requests Log for Verification
    List<String> requestLog = [];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      final mockHttpClient = MockClient((request) async {
        final ip = request.url.host;
        final path = request.url.path;
        requestLog.add('${request.method} $ip$path');

        if (!virtualDevices.containsKey(ip)) {
           return http.Response('Unreachable', 404);
        }

        // GET STATUS
        if (request.method == 'GET' && path == '/json') {
           return http.Response(jsonEncode(virtualDevices[ip]), 200);
        }

        // SET STATE
        if (request.method == 'POST' && path == '/json/state') {
           return http.Response('{"success":true}', 200);
        }
        
        return http.Response('Error', 400);
      });

      final wledClient = WledClient(client: mockHttpClient);
      repo = LightingRepository(wledClient);
    });

    test('Discovery: Can Aggregate Multiple Controllers', () async {
      // 1. Add Pool House
      await repo.addController('192.168.1.10');
      expect(repo.zones.length, 2, reason: "Should have 2 zones from Pool House");
      expect(repo.zones.first.label, contains('Pool Eaves'));

      // 2. Add Patio
      await repo.addController('192.168.1.11');
      expect(repo.zones.length, 3, reason: "Should have 3 zones total (2+1)");
      
      // 3. Verify labels contain Context
      final labels = repo.zones.map((z) => z.label).toList();
      print('Fleet Zones: $labels');
      expect(labels, contains('Patio Railing'));
    });

    test('Control: Global Brightness controls Fleet', () async {
      await repo.addController('192.168.1.10');
      await repo.addController('192.168.1.11');
      requestLog.clear();

      // Fire Global Brightness
      await repo.setGlobalBrightness(200);

      // Verify requests sent to BOTH IPs
      final targets = requestLog.map((r) => r.split(' ').last).toList(); // POST 192...
      
      expect(targets.any((t) => t.contains('192.168.1.10/json/state')), isTrue);
      expect(targets.any((t) => t.contains('192.168.1.11/json/state')), isTrue);
      print("Global Command Targets: $targets");
    });
  });
}
