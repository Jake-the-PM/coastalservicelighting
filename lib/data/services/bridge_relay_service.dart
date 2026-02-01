import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../wled/wled_client.dart';

/// Represents a command to be relayed to a local WLED device
class RelayCommand {
  final String id;
  final String installationId;
  final String controllerIp;
  final String action; // 'power', 'color', 'effect', 'brightness'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final bool processed;

  RelayCommand({
    required this.id,
    required this.installationId,
    required this.controllerIp,
    required this.action,
    required this.payload,
    required this.createdAt,
    this.processed = false,
  });

  factory RelayCommand.fromRow(Map<String, dynamic> row) {
    return RelayCommand(
      id: row['id'],
      installationId: row['installation_id'],
      controllerIp: row['controller_ip'],
      action: row['action'],
      payload: Map<String, dynamic>.from(row['payload'] ?? {}),
      createdAt: DateTime.parse(row['created_at']),
      processed: row['processed'] ?? false,
    );
  }
}

class BridgeRelayService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  final WledClient _wledClient = WledClient();
  
  static const String _commandsTable = 'relay_commands';
  
  bool _isActive = false;
  String? _activeInstallationId;
  StreamSubscription? _subscription;
  List<String> _log = [];

  bool get isActive => _isActive;
  List<String> get log => _log;

  /// Start listening for commands for a specific installation
  void startBridge(String installationId) {
    if (_isActive) return;
    
    _activeInstallationId = installationId;
    _isActive = true;
    _log = ['Bridge started at ${DateTime.now()}'];
    notifyListeners();

    // Subscribe to new commands for this installation
    _subscription = _client
        .from(_commandsTable)
        .stream(primaryKey: ['id'])
        .eq('installation_id', installationId)
        .listen((rows) {
          for (final row in rows) {
            final cmd = RelayCommand.fromRow(row);
            if (!cmd.processed) {
              _processCommand(cmd);
            }
          }
        });
  }

  /// Stop the bridge
  void stopBridge() {
    _subscription?.cancel();
    _subscription = null;
    _isActive = false;
    _activeInstallationId = null;
    _log.add('Bridge stopped at ${DateTime.now()}');
    notifyListeners();
  }

  /// Process and execute a relay command
  Future<void> _processCommand(RelayCommand cmd) async {
    _log.add('[${cmd.action}] -> ${cmd.controllerIp}');
    notifyListeners();

    try {
      switch (cmd.action) {
        case 'power':
          await _wledClient.setPower(cmd.controllerIp, cmd.payload['on'] ?? true);
          break;
        case 'brightness':
          await _wledClient.setBrightness(cmd.controllerIp, cmd.payload['value'] ?? 128);
          break;
        case 'color':
          await _wledClient.setColor(
            cmd.controllerIp,
            cmd.payload['r'] ?? 255,
            cmd.payload['g'] ?? 255,
            cmd.payload['b'] ?? 255,
          );
          break;
        case 'effect':
          await _wledClient.setEffect(cmd.controllerIp, cmd.payload['effectId'] ?? 0);
          break;
        default:
          _log.add('Unknown action: ${cmd.action}');
      }

      // Mark as processed
      await _client.from(_commandsTable).update({'processed': true}).eq('id', cmd.id);
      _log.add('✓ Executed ${cmd.action}');
    } catch (e) {
      _log.add('✗ Error: $e');
    }

    notifyListeners();
  }

  /// Send a command to be relayed (called from remote app)
  static Future<void> sendRemoteCommand({
    required String installationId,
    required String controllerIp,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    await Supabase.instance.client.from(_commandsTable).insert({
      'installation_id': installationId,
      'controller_ip': controllerIp,
      'action': action,
      'payload': payload,
      'processed': false,
    });
  }
}
