import 'package:flutter_test/flutter_test.dart';
import 'package:coastal_services_lighting/domain/models/installation.dart';

void main() {
  group('Installation Model', () {
    test('toJson and fromJson round-trip correctly', () {
      final original = Installation(
        id: 'test-123',
        customerName: 'John Doe',
        address: '123 Main St',
        dateInstalled: DateTime(2026, 1, 15),
        controllerIps: ['192.168.1.100', '192.168.1.101'],
        previewImage: 'preview.png',
      );

      final json = original.toJson();
      final restored = Installation.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.customerName, equals(original.customerName));
      expect(restored.address, equals(original.address));
      expect(restored.dateInstalled, equals(original.dateInstalled));
      expect(restored.controllerIps, equals(original.controllerIps));
      expect(restored.previewImage, equals(original.previewImage));
    });

    test('fromJson handles missing optional fields gracefully', () {
      final json = {
        'id': 'test-456',
        'customerName': 'Jane Doe',
        'address': '456 Oak Ave',
        'dateInstalled': '2026-01-20T00:00:00.000',
        'controllerIps': ['192.168.1.50'],
        // previewImage is missing
      };

      final installation = Installation.fromJson(json);

      expect(installation.id, equals('test-456'));
      expect(installation.customerName, equals('Jane Doe'));
      expect(installation.previewImage, isNull);
    });

    test('fromJson handles empty controllerIps', () {
      final json = {
        'id': 'test-789',
        'customerName': 'Empty Test',
        'address': '789 Pine Rd',
        'dateInstalled': '2026-01-25T00:00:00.000',
        'controllerIps': [],
      };

      final installation = Installation.fromJson(json);

      expect(installation.controllerIps, isEmpty);
    });

    test('toJson produces valid JSON structure', () {
      final installation = Installation(
        id: 'json-test',
        customerName: 'JSON Validator',
        address: 'Test Address',
        dateInstalled: DateTime(2026, 2, 1),
        controllerIps: ['10.0.0.1'],
      );

      final json = installation.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], equals('json-test'));
      expect(json['customerName'], equals('JSON Validator'));
      expect(json['controllerIps'], isA<List>());
    });

    test('handles special characters in customer names', () {
      final installation = Installation(
        id: 'special-chars',
        customerName: "O'Brien & Associates",
        address: '100 "Test" Lane',
        dateInstalled: DateTime.now(),
        controllerIps: [],
      );

      final json = installation.toJson();
      final restored = Installation.fromJson(json);

      expect(restored.customerName, equals("O'Brien & Associates"));
      expect(restored.address, equals('100 "Test" Lane'));
    });
  });

  group('Installation Validation', () {
    test('validates IP format in controllerIps', () {
      final validIps = ['192.168.1.1', '10.0.0.1', '172.16.0.1'];
      final installation = Installation(
        id: 'ip-test',
        customerName: 'IP Test',
        address: 'Test',
        dateInstalled: DateTime.now(),
        controllerIps: validIps,
      );

      // Basic IP regex validation
      final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      for (final ip in installation.controllerIps) {
        expect(ipRegex.hasMatch(ip), isTrue, reason: 'IP $ip should be valid');
      }
    });
  });
}
