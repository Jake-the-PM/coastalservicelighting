import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/installation.dart';

class InstallationService extends ChangeNotifier {
  static const String _key = 'coastal_installations_registry';

  Future<List<Installation>> getInstallations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => Installation.fromJson(e)).toList();
    } catch (e) {
      print("Registry Corrupt: $e");
      return [];
    }
  }

  Future<void> saveInstallation(Installation installation) async {
    final list = await getInstallations();
    
    // Check if exists update, else add
    final index = list.indexWhere((i) => i.id == installation.id);
    if (index >= 0) {
      list[index] = installation;
    } else {
      list.add(installation);
    }
    
    await _saveList(list);
    notifyListeners();
  }

  Future<void> deleteInstallation(String id) async {
    final list = await getInstallations();
    list.removeWhere((i) => i.id == id);
    await _saveList(list);
    notifyListeners();
  }

  Future<void> _saveList(List<Installation> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_key, data);
  }

  /// Stream adapter for cloud-like interface (returns local data as stream)
  Stream<List<Installation>> getInstallerInstallations(String installerId) {
    // For local-first mode, we just return our local installations as a stream
    // In hybrid mode, this would merge with CloudInstallationService
    return Stream.fromFuture(getInstallations());
  }

  /// Returns installations owned by a homeowner (local-first: returns all local)
  Stream<List<Installation>> getHomeownerInstallations(String homeownerId) {
    return Stream.fromFuture(getInstallations());
  }

  /// Get installations assigned to an email (stub for local-first mode)
  Future<List<Installation>> getAssignedInstallations(String email) async {
    // Local mode doesn't support email-based assignment
    return [];
  }

  /// Claim an installation (stub for local-first mode)
  Future<bool> claimInstallation(String installationId, String userId) async {
    // In local mode, installations are already "claimed" by virtue of being on device
    return true;
  }
}
