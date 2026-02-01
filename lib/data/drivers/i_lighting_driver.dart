import '../wled/wled_models.dart';

/// Interface for WLED Lighting Drivers.
/// Abstracts the difference between Real Hardware (HTTP) and Demo Mode (Memory).
abstract class ILightingDriver {
  /// Fetches the full status of the device.
  Future<(WledInfo, WledState)?> getStatus(String ip);

  /// Sets the raw JSON state of the device.
  Future<bool> setJsonState(String ip, Map<String, dynamic> state);

  /// Triggers a temporary reaction (e.g. Doorbell/Motion).
  Future<void> triggerReaction({
    required String ip,
    required int start,
    required int count,
    required List<int> color,
    required int effectId,
    required int durationSeconds,
    required int priorityId,
  });

  /// Discovery helper (Real only, Demo returns mock).
  Future<List<String>> scanForDevices();
}
