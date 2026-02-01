import '../wled/wled_client.dart';
import '../wled/wled_models.dart';
import 'i_lighting_driver.dart';

/// Production driver that speaks HTTP to real WLED devices.
class WledRealDriver implements ILightingDriver {
  final WledClient _client;

  WledRealDriver(this._client);

  @override
  Future<(WledInfo, WledState)?> getStatus(String ip) {
    return _client.getDeviceStatus(ip);
  }

  @override
  Future<bool> setJsonState(String ip, Map<String, dynamic> state) {
    return _client.setJsonState(ip, state);
  }

  @override
  Future<void> triggerReaction({
    required String ip,
    required int start,
    required int count,
    required List<int> color,
    required int effectId,
    required int durationSeconds,
    required int priorityId,
  }) async {
    // 1. Apply Layer
    final startPayload = {
      "seg": [
        {
          "id": priorityId,
          "start": start,
          "stop": start + count,
          "n": priorityId == 12 ? "Doorbell Overlay" : "Motion Overlay",
          "on": true,
          "bri": 255,
          "col": [color, [0,0,0], [0,0,0]],
          "fx": effectId,
          "sx": 200, 
          "ix": 200, 
        }
      ]
    };
    
    await _client.setJsonState(ip, startPayload);

    // 2. Schedule Removal
    Future.delayed(Duration(seconds: durationSeconds), () async {
       await _client.setJsonState(ip, {
         "seg": [{"id": priorityId, "on": false}]
       });
    });
  }

  @override
  Future<List<String>> scanForDevices() async {
    // In a real app, this would use mDNS.
    // For now we assume the Repository handles the scanning logic via DeviceDiscoveryService.
    return []; 
  }
}
