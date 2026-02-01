/// Input validation and sanitization utilities
class InputValidator {
  static final RegExp _ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
  static final RegExp _emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  );

  /// Validate IPv4 address format
  static bool isValidIp(String ip) {
    if (!_ipPattern.hasMatch(ip)) return false;
    
    final parts = ip.split('.');
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return _emailPattern.hasMatch(email.trim());
  }

  /// Validate UUID format
  static bool isValidUuid(String id) {
    return _uuidPattern.hasMatch(id);
  }

  /// Sanitize string for safe display (prevent XSS in web views)
  static String sanitizeForDisplay(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Validate and sanitize customer name
  static String? validateCustomerName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Customer name is required';
    }
    if (name.length > 100) {
      return 'Name must be less than 100 characters';
    }
    if (RegExp(r'[<>{}]').hasMatch(name)) {
      return 'Name contains invalid characters';
    }
    return null; // Valid
  }

  /// Validate address
  static String? validateAddress(String? address) {
    if (address == null || address.trim().isEmpty) {
      return 'Address is required';
    }
    if (address.length > 200) {
      return 'Address must be less than 200 characters';
    }
    return null;
  }

  /// Validate controller IP list
  static String? validateControllerIps(List<String>? ips) {
    if (ips == null || ips.isEmpty) {
      return null; // Optional field
    }
    for (final ip in ips) {
      if (!isValidIp(ip)) {
        return 'Invalid IP address: $ip';
      }
    }
    return null;
  }

  /// Validate brightness value (0-255)
  static bool isValidBrightness(int value) {
    return value >= 0 && value <= 255;
  }

  /// Validate WLED preset ID (1-250 typically)
  static bool isValidPresetId(int id) {
    return id >= 1 && id <= 250;
  }

  /// Validate WLED effect ID (0-200+ depending on version)
  static bool isValidEffectId(int id) {
    return id >= 0 && id <= 200;
  }
}

/// Relay command validation for Bridge Mode security
class RelayCommandValidator {
  static const List<String> _allowedCommands = [
    'setPower',
    'setBrightness', 
    'setColor',
    'setEffect',
    'applyPreset',
  ];

  static const int _maxBrightness = 255;
  static const int _maxColorValue = 255;

  /// Validate incoming relay command from Supabase
  static ValidationResult validateCommand(Map<String, dynamic> command) {
    // Check required fields
    if (!command.containsKey('type')) {
      return ValidationResult.invalid('Missing command type');
    }

    final type = command['type'] as String?;
    if (type == null || !_allowedCommands.contains(type)) {
      return ValidationResult.invalid('Invalid command type: $type');
    }

    // Validate command-specific payload
    switch (type) {
      case 'setPower':
        if (command['value'] is! bool) {
          return ValidationResult.invalid('setPower requires boolean value');
        }
        break;

      case 'setBrightness':
        final value = command['value'];
        if (value is! int || value < 0 || value > _maxBrightness) {
          return ValidationResult.invalid('setBrightness requires int 0-255');
        }
        break;

      case 'setColor':
        final color = command['value'];
        if (color is! List || color.length != 3) {
          return ValidationResult.invalid('setColor requires [r,g,b] array');
        }
        for (final c in color) {
          if (c is! int || c < 0 || c > _maxColorValue) {
            return ValidationResult.invalid('Color values must be 0-255');
          }
        }
        break;

      case 'setEffect':
        final effectId = command['value'];
        if (effectId is! int || !InputValidator.isValidEffectId(effectId)) {
          return ValidationResult.invalid('Invalid effect ID');
        }
        break;

      case 'applyPreset':
        final presetId = command['value'];
        if (presetId is! int || !InputValidator.isValidPresetId(presetId)) {
          return ValidationResult.invalid('Invalid preset ID');
        }
        break;
    }

    // Validate target IP if present
    if (command.containsKey('targetIp')) {
      final ip = command['targetIp'] as String?;
      if (ip != null && !InputValidator.isValidIp(ip)) {
        return ValidationResult.invalid('Invalid target IP');
      }
    }

    return ValidationResult.valid();
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult._(this.isValid, this.error);

  factory ValidationResult.valid() => ValidationResult._(true, null);
  factory ValidationResult.invalid(String error) => ValidationResult._(false, error);
}

/// RLS Policy Test Queries (for development/debugging)
class RlsTestQueries {
  /// SQL queries to verify RLS policies work correctly
  /// Run these in Supabase SQL Editor or generate test coverage
  
  static const String testInstallerCanOnlySeeOwnInstallations = '''
-- Test: Installer can only see their own installations
-- Run as authenticated user with installer role
SELECT * FROM installations 
WHERE installer_id != auth.uid();
-- Expected: 0 rows (RLS blocks access to other installers' data)
''';

  static const String testHomeownerCanOnlySeeClaimedInstallations = '''
-- Test: Homeowner can only see claimed installations
SELECT * FROM installations 
WHERE customer_id != auth.uid();
-- Expected: 0 rows
''';

  static const String testRelayCommandsRequireMatchingInstallation = '''
-- Test: Relay commands require matching installation ownership
INSERT INTO relay_commands (installation_id, command_type, payload)
VALUES ('00000000-0000-0000-0000-000000000000', 'setPower', '{"value": true}');
-- Expected: Error (no matching installation for current user)
''';

  static const String testAnonymousCannotAccessInstallations = '''
-- Test: Anonymous users cannot access installations
-- Run without authentication
SELECT * FROM installations;
-- Expected: Error or 0 rows
''';

  /// Generate a test report as markdown
  static String generateTestReport() {
    return '''
# RLS Policy Test Report

## Test Cases

### 1. Installer Data Isolation
- **Status**: ⚠️ Requires manual verification
- **Query**: See `testInstallerCanOnlySeeOwnInstallations`
- **Expected**: Installer A cannot see Installer B's installations

### 2. Homeowner Data Isolation  
- **Status**: ⚠️ Requires manual verification
- **Query**: See `testHomeownerCanOnlySeeClaimedInstallations`
- **Expected**: Homeowner A cannot see Homeowner B's installations

### 3. Relay Command Authorization
- **Status**: ⚠️ Requires manual verification
- **Query**: See `testRelayCommandsRequireMatchingInstallation`
- **Expected**: Cannot create commands for unowned installations

### 4. Anonymous Access Blocked
- **Status**: ⚠️ Requires manual verification
- **Query**: See `testAnonymousCannotAccessInstallations`
- **Expected**: No data leakage to unauthenticated users

## How to Verify

1. Go to Supabase Dashboard → SQL Editor
2. Run each test query as the specified user role
3. Document results in this report
4. Fix any policy violations found
''';
  }
}
