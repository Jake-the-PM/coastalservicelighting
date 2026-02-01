import 'package:supabase_flutter/supabase_flutter.dart';

class CloudCommand {
  final String id;
  final String installationId;
  final String controllerIp;
  final Map<String, dynamic> payload;
  final bool executed;
  final DateTime createdAt;

  CloudCommand({
    required this.id,
    required this.installationId,
    required this.controllerIp,
    required this.payload,
    required this.executed,
    required this.createdAt,
  });

  factory CloudCommand.fromMap(Map<String, dynamic> map) {
    return CloudCommand(
      id: map['id'] ?? '',
      installationId: map['installation_id'] ?? '',
      controllerIp: map['controller_ip'] ?? '',
      payload: map['payload'] ?? {},
      executed: map['executed'] ?? false,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class CommandService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sends a command to the cloud for a remote relay to pick up
  Future<void> sendCommand({
    required String installationId,
    required String controllerIp,
    required Map<String, dynamic> payload,
  }) async {
    await _supabase.from('commands').insert({
      'installation_id': installationId,
      'controller_ip': controllerIp,
      'payload': payload,
      'executed': false,
//      'created_at': DateTime.now().toIso8601String(), // Let DB handle default
    });
  }

  /// Listens for PENDING commands for a specific installation
  /// This is used by the "Bridge" device on-site
  Stream<List<CloudCommand>> streamPendingCommands(String installationId) {
    return _supabase
        .from('commands')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => data
            .where((e) => 
                e['installation_id'] == installationId && 
                e['executed'] == false)
            .map((e) => CloudCommand.fromMap(e))
            .toList());
  }

  /// Marks a command as executed (so it isn't repeated)
  Future<void> markAsExecuted(String commandId) async {
    await _supabase
        .from('commands')
        .update({'executed': true})
        .eq('id', commandId);
  }
}
