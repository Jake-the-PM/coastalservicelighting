import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/installation.dart';

class CloudInstallationService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  
  static const String _table = 'installations';

  /// Stream of installations for the current user (installer or homeowner)
  Stream<List<Installation>> getInstallerInstallations(String installerId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('installer_id', installerId)
        .map((rows) => rows.map((row) => _fromRow(row)).toList());
  }

  Stream<List<Installation>> getHomeownerInstallations(String homeownerId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('homeowner_id', homeownerId)
        .map((rows) => rows.map((row) => _fromRow(row)).toList());
  }

  /// Create a new installation in the cloud
  Future<void> createInstallation(Installation installation, String installerId) async {
    await _client.from(_table).insert({
      'id': installation.id,
      'installer_id': installerId,
      'homeowner_id': null, // Will be linked later via Golden Key
      'customer_name': installation.customerName,
      'address': installation.address,
      'date_installed': installation.dateInstalled.toIso8601String(),
      'controller_ips': installation.controllerIps,
      'preview_image': installation.previewImage,
    });
    notifyListeners();
  }

  /// Update an existing installation
  Future<void> updateInstallation(Installation installation) async {
    await _client.from(_table).update({
      'customer_name': installation.customerName,
      'address': installation.address,
      'controller_ips': installation.controllerIps,
      'preview_image': installation.previewImage,
    }).eq('id', installation.id);
    notifyListeners();
  }

  /// Delete an installation
  Future<void> deleteInstallation(String id) async {
    await _client.from(_table).delete().eq('id', id);
    notifyListeners();
  }

  /// Link a homeowner to an installation (Golden Key claim)
  Future<void> claimInstallation(String installationId, String homeownerId) async {
    await _client.from(_table).update({
      'homeowner_id': homeownerId,
    }).eq('id', installationId);
    notifyListeners();
  }

  /// Convert Supabase row to Installation model
  Installation _fromRow(Map<String, dynamic> row) {
    return Installation(
      id: row['id'],
      customerName: row['customer_name'],
      address: row['address'],
      dateInstalled: DateTime.parse(row['date_installed']),
      controllerIps: List<String>.from(row['controller_ips'] ?? []),
      previewImage: row['preview_image'],
    );
  }
}
