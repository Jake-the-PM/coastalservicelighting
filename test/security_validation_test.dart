import 'package:flutter_test/flutter_test.dart';
import 'package:coastal_services_lighting/core/security/input_validator.dart';

void main() {
  group('InputValidator - IP Validation', () {
    test('validates correct IPv4 addresses', () {
      expect(InputValidator.isValidIp('192.168.1.1'), isTrue);
      expect(InputValidator.isValidIp('10.0.0.1'), isTrue);
      expect(InputValidator.isValidIp('172.16.0.1'), isTrue);
      expect(InputValidator.isValidIp('0.0.0.0'), isTrue);
      expect(InputValidator.isValidIp('255.255.255.255'), isTrue);
    });

    test('rejects invalid IP formats', () {
      expect(InputValidator.isValidIp(''), isFalse);
      expect(InputValidator.isValidIp('192.168.1'), isFalse);
      expect(InputValidator.isValidIp('192.168.1.1.1'), isFalse);
      expect(InputValidator.isValidIp('abc.def.ghi.jkl'), isFalse);
      expect(InputValidator.isValidIp('192.168.1.'), isFalse);
      expect(InputValidator.isValidIp('.192.168.1.1'), isFalse);
    });

    test('rejects out-of-range octets', () {
      expect(InputValidator.isValidIp('256.168.1.1'), isFalse);
      expect(InputValidator.isValidIp('192.300.1.1'), isFalse);
      expect(InputValidator.isValidIp('192.168.999.1'), isFalse);
      expect(InputValidator.isValidIp('192.168.1.1000'), isFalse);
    });
  });

  group('InputValidator - Email Validation', () {
    test('validates correct email formats', () {
      expect(InputValidator.isValidEmail('user@example.com'), isTrue);
      expect(InputValidator.isValidEmail('test.user@domain.co'), isTrue);
      expect(InputValidator.isValidEmail('user+tag@example.org'), isTrue);
      expect(InputValidator.isValidEmail('user123@test.io'), isTrue);
    });

    test('rejects invalid email formats', () {
      expect(InputValidator.isValidEmail(''), isFalse);
      expect(InputValidator.isValidEmail('user'), isFalse);
      expect(InputValidator.isValidEmail('user@'), isFalse);
      expect(InputValidator.isValidEmail('@domain.com'), isFalse);
      expect(InputValidator.isValidEmail('user domain.com'), isFalse);
    });
  });

  group('InputValidator - UUID Validation', () {
    test('validates correct UUID formats', () {
      expect(InputValidator.isValidUuid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
      expect(InputValidator.isValidUuid('6ba7b810-9dad-11d1-80b4-00c04fd430c8'), isTrue);
    });

    test('rejects invalid UUID formats', () {
      expect(InputValidator.isValidUuid(''), isFalse);
      expect(InputValidator.isValidUuid('not-a-uuid'), isFalse);
      expect(InputValidator.isValidUuid('550e8400e29b41d4a716446655440000'), isFalse); // No dashes
      expect(InputValidator.isValidUuid('550e8400-e29b-41d4-a716'), isFalse); // Too short
    });
  });

  group('InputValidator - Sanitization', () {
    test('sanitizes HTML special characters', () {
      expect(InputValidator.sanitizeForDisplay('<script>'), equals('&lt;script&gt;'));
      expect(InputValidator.sanitizeForDisplay('"test"'), equals('&quot;test&quot;'));
      expect(InputValidator.sanitizeForDisplay("O'Brien"), equals("O&#39;Brien"));
    });

    test('passes through safe strings unchanged', () {
      expect(InputValidator.sanitizeForDisplay('Hello World'), equals('Hello World'));
      expect(InputValidator.sanitizeForDisplay('123 Main St'), equals('123 Main St'));
    });
  });

  group('InputValidator - Customer Name Validation', () {
    test('accepts valid customer names', () {
      expect(InputValidator.validateCustomerName('John Doe'), isNull);
      expect(InputValidator.validateCustomerName("O'Brien"), isNull);
      expect(InputValidator.validateCustomerName('María García'), isNull);
    });

    test('rejects empty names', () {
      expect(InputValidator.validateCustomerName(''), isNotNull);
      expect(InputValidator.validateCustomerName('   '), isNotNull);
      expect(InputValidator.validateCustomerName(null), isNotNull);
    });

    test('rejects names with dangerous characters', () {
      expect(InputValidator.validateCustomerName('<script>'), isNotNull);
      expect(InputValidator.validateCustomerName('{malicious}'), isNotNull);
    });

    test('rejects overly long names', () {
      final longName = 'A' * 101;
      expect(InputValidator.validateCustomerName(longName), isNotNull);
    });
  });

  group('InputValidator - Brightness Validation', () {
    test('accepts valid brightness values', () {
      expect(InputValidator.isValidBrightness(0), isTrue);
      expect(InputValidator.isValidBrightness(128), isTrue);
      expect(InputValidator.isValidBrightness(255), isTrue);
    });

    test('rejects out-of-range values', () {
      expect(InputValidator.isValidBrightness(-1), isFalse);
      expect(InputValidator.isValidBrightness(256), isFalse);
      expect(InputValidator.isValidBrightness(1000), isFalse);
    });
  });

  group('RelayCommandValidator', () {
    test('validates setPower command', () {
      final result = RelayCommandValidator.validateCommand({
        'type': 'setPower',
        'value': true,
      });
      expect(result.isValid, isTrue);
    });

    test('rejects setPower with non-boolean', () {
      final result = RelayCommandValidator.validateCommand({
        'type': 'setPower',
        'value': 'yes',
      });
      expect(result.isValid, isFalse);
    });

    test('validates setBrightness command', () {
      final result = RelayCommandValidator.validateCommand({
        'type': 'setBrightness',
        'value': 128,
      });
      expect(result.isValid, isTrue);
    });

    test('rejects setBrightness with out-of-range value', () {
      final result = RelayCommandValidator.validateCommand({
        'type': 'setBrightness',
        'value': 300,
      });
      expect(result.isValid, isFalse);
    });

    test('validates setColor command', () {
      final result = RelayCommandValidator.validateCommand({
        'type': 'setColor',
        'value': [255, 128, 0],
      });
      expect(result.isValid, isTrue);
    });

    test('rejects setColor with invalid array', () {
      final result1 = RelayCommandValidator.validateCommand({
        'type': 'setColor',
        'value': [255, 128], // Too few elements
      });
      expect(result1.isValid, isFalse);

      final result2 = RelayCommandValidator.validateCommand({
        'type': 'setColor',
        'value': [255, 128, 300], // Out of range
      });
      expect(result2.isValid, isFalse);
    });

    test('rejects unknown command types', () {
      final result = RelayCommandValidator.validateCommand({
        'type': 'hackTheSystem',
        'value': true,
      });
      expect(result.isValid, isFalse);
    });

    test('rejects commands without type', () {
      final result = RelayCommandValidator.validateCommand({
        'value': true,
      });
      expect(result.isValid, isFalse);
    });

    test('validates targetIp if present', () {
      final validIp = RelayCommandValidator.validateCommand({
        'type': 'setPower',
        'value': true,
        'targetIp': '192.168.1.100',
      });
      expect(validIp.isValid, isTrue);

      final invalidIp = RelayCommandValidator.validateCommand({
        'type': 'setPower',
        'value': true,
        'targetIp': 'not-an-ip',
      });
      expect(invalidIp.isValid, isFalse);
    });
  });

  group('RlsTestQueries', () {
    test('generates test report', () {
      final report = RlsTestQueries.generateTestReport();
      
      expect(report, contains('RLS Policy Test Report'));
      expect(report, contains('Installer Data Isolation'));
      expect(report, contains('Homeowner Data Isolation'));
      expect(report, contains('Relay Command Authorization'));
    });
  });
}
