import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_specs.dart';
import 'wled_models.dart';

class WledClient {
  final http.Client _client;

  WledClient({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches strict device status for validation.
  /// Throws if unreachable or invalid JSON.
  Future<(WledInfo, WledState)?> getDeviceStatus(String ip) async {
    final url = Uri.parse('http://$ip/json');
    try {
      final response = await _client.get(url).timeout(AppSpecs.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final info = WledInfo.fromJson(data['info']);
        final state = WledState.fromJson(data['state']);
        return (info, state);
      }
      return null;
    } catch (e) {
      print('WLED Status Check Failed: $e');
      return null;
    }
  }

  /// Sends a raw JSON state update to the WLED controller.
  Future<bool> setJsonState(String ip, Map<String, dynamic> state) async {
    final url = Uri.parse('http://$ip/json/state');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(state),
      ).timeout(AppSpecs.connectionTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('WLED Client Error: $e');
      return false;
    }
  }

  /// Convenience: Set global power and brightness
  Future<bool> setGlobalState(String ip, {bool? on, int? brightness}) async {
    final Map<String, dynamic> body = {};
    if (on != null) body['on'] = on;
    if (brightness != null) body['bri'] = brightness;
    
    return setJsonState(ip, body);
  }

  /// Convenience: Set a specific segment (Zone)
  /// STRICT API: 'ps' (preset) is NOT supported inside a segment. 
  /// Use 'effectId' (fx) and 'paletteId' (pal) for per-zone styling.
  Future<bool> setSegmentState(String ip, int segmentId, {
    bool? on, 
    int? brightness, 
    int? effectId, 
    int? paletteId,
    int? speed,
    int? intensity,
    List<int>? rgb, // [255, 0, 0]
  }) async {
    final Map<String, dynamic> seg = {'id': segmentId};
    
    if (on != null) seg['on'] = on;
    if (brightness != null) seg['bri'] = brightness;
    if (effectId != null) seg['fx'] = effectId;
    if (paletteId != null) seg['pal'] = paletteId;
    if (speed != null) seg['sx'] = speed;
    if (intensity != null) seg['ix'] = intensity;
    if (rgb != null) seg['col'] = [rgb]; // WLED expects array of arrays [[R,G,B], [Sec], [Ter]]

    return setJsonState(ip, {'seg': [seg]});
  }

  /// Loads a Global Preset (Scene)
  Future<bool> applyPreset(String ip, int presetId) async {
    return setJsonState(ip, {'ps': presetId});
  }

  /// Fetches the list of available effects
  Future<List<String>> getEffects(String ip) async {
    final url = Uri.parse('http://$ip/json/eff');
    try {
      final response = await _client.get(url).timeout(AppSpecs.connectionTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      }
    } catch (e) {
      print('Failed to load effects: $e');
    }
    return []; // Return empty if failed
  }

  /// Fetches the list of available palettes
  Future<List<String>> getPalettes(String ip) async {
    final url = Uri.parse('http://$ip/json/pal');
    try {
      final response = await _client.get(url).timeout(AppSpecs.connectionTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      }
    } catch (e) {
      print('Failed to load palettes: $e');
    }
    return [];
  }

  // === Bridge Mode Convenience Methods ===

  /// Set global power state
  Future<bool> setPower(String ip, bool on) async {
    return setGlobalState(ip, on: on);
  }

  /// Set global brightness (0-255)
  Future<bool> setBrightness(String ip, int brightness) async {
    return setGlobalState(ip, brightness: brightness.clamp(0, 255));
  }

  /// Set global color (RGB)
  Future<bool> setColor(String ip, int r, int g, int b) async {
    return setJsonState(ip, {
      'seg': [{'col': [[r, g, b]]}]
    });
  }

  /// Set global effect
  Future<bool> setEffect(String ip, int effectId) async {
    return setJsonState(ip, {
      'seg': [{'fx': effectId}]
    });
  }
}
