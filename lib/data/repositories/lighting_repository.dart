import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/installation.dart';
import '../../core/constants/app_specs.dart';
import '../wled/wled_client.dart';
import '../wled/wled_models.dart';
import '../drivers/i_lighting_driver.dart';
import '../drivers/wled_real_driver.dart';
import '../drivers/wled_demo_driver.dart';

import '../services/device_discovery_service.dart';

class LightingRepository extends ChangeNotifier {
  final WledClient _client; // Keep for dependency injection structure
  final _secureStorage = const FlutterSecureStorage();
  DeviceDiscoveryService? _discoveryService;
  
  // Driver Pattern: Decoupled Implementation (Multiplexed)
  late final ILightingDriver _realDriver;
  late final ILightingDriver _demoDriver;

  ILightingDriver _getDriver(String ip) {
    return ip.toLowerCase() == 'demo' ? _demoDriver : _realDriver;
  }

  // Multi-Controller State: Map<IP Address, Last Known State>
  final Map<String, WledState> _controllers = {};
  final Map<String, WledInfo> _controllerInfos = {}; 
  final Map<String, List<String>> _effects = {}; 
  final Map<String, List<String>> _palettes = {}; 

  // Local State Cache (Optimistic UI)
  int _globalBrightness = 128; 
  bool _securityModeEnabled = true;
  int _lastPresetId = 0; 
  final Set<int> _securityZoneIds = {1, 2, 3}; 
  List<int> _securityColor = [255, 0, 0]; 

  // Scene Configurations (Persisted)
  final Map<String, SceneConfig> _sceneConfigs = {};
  
  String? _activeInstallationId;
  String? get activeInstallationId => _activeInstallationId;
  
  // Debouncing for slider spam
  final Map<String, Timer> _debounceTimers = {};

  bool get securityModeEnabled => _securityModeEnabled;
  int get lastPresetId => _lastPresetId;
  int get globalBrightness => _globalBrightness;
  List<int> get securityColor => _securityColor;
  
  void setDiscoveryService(DeviceDiscoveryService service) {
    _discoveryService = service;
  }
  
  LightingRepository(this._client) {
    _realDriver = WledRealDriver(_client);
    _demoDriver = WledDemoDriver();
    _loadPreferences();
  }

  // Returns the IP of the first connected controller
  String? get currentIp => _controllers.keys.isNotEmpty ? _controllers.keys.first : null;
  bool get isOffline => _controllers.isEmpty;
  Map<String, WledState> get controllers => _controllers;

  // Getters for specific controller data
  WledState? getState(String ip) => _controllers[ip];
  WledInfo? getInfo(String ip) => _controllerInfos[ip];
  List<String> getEffects(String ip) => _effects[ip] ?? [];
  List<String> getPalettes(String ip) => _palettes[ip] ?? [];

  /// Add a controller to the repository (Connect)
  Future<bool> addController(String ip) async {
    final driver = _getDriver(ip);

    try {
      final result = await driver.getStatus(ip).timeout(const Duration(seconds: 3));
      if (result != null) {
        _controllers[ip] = result.$2;
        _controllerInfos[ip] = result.$1;
        
        // Fetch Metadata (Lazy)
        if (!_effects.containsKey(ip)) {
           if (ip != 'demo') {
             _effects[ip] = await _client.getEffects(ip);
             _palettes[ip] = await _client.getPalettes(ip);
           } else {
             _effects[ip] = ["Solid", "Blink", "Breathe", "Rainbow", "Chase", "Tetrix", "Tri-Color Chase", "Android", "Scanner"];
             _palettes[ip] = ["Default", "Ocean", "Lava", "Forest", "Party", "Cloud"];
           }
        }

        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Failed to add controller $ip: $e');
      // FALLBACK: Self-Healing Trigger (Conceptual for now, will be wired in Cycle 3)
      if (ip != 'demo') {
        _attemptSelfHealing(ip);
      }
    }
    return false;
  }

  Future<void> _attemptSelfHealing(String failedIp) async {
    if (_discoveryService == null || _discoveryService!.isScanning) return;
    
    print("SELF-HEALING: Connection to $failedIp lost. Scanning local network...");
    
    // Start discovery
    await _discoveryService!.startDiscovery();
    
    // WLED devices are discovered with names. 
    // If we find a device that has a name matching a stored one (future improvement)
    // or if we just want to update our internal map with any newly found WLED.
    
    // For now: Simple IP-Shift Support
    // If we find a device and it wasn't in our map, we try to see if it's the one we lost.
    for (final device in _discoveryService!.devices) {
      if (!_controllers.containsKey(device.ip)) {
        // Try adding it. If it responds and it was the only one offline, we've healed.
        final success = await addController(device.ip);
        if (success) {
          print("SELF-HEALING: Recovered connection at new IP: ${device.ip}");
          // We could potentially remove the old failedIp if we are sure it moved
          _controllers.remove(failedIp);
          _controllerInfos.remove(failedIp);
        }
      }
    }
  }

  /// Remove a controller
  void removeController(String ip) {
    _controllers.remove(ip);
    _controllerInfos.remove(ip);
    notifyListeners();
  }

  /// Gate 2: Triage - Activate an installation and lock it as the default session
  Future<void> activateInstallation(Installation installation) async {
    _activeInstallationId = installation.id;
    
    // Clear current controllers to prevent "session bleed"
    _controllers.clear();
    _controllerInfos.clear();
    
    // Add all controllers from the installation (PARALLEL HYDRATION)
    await Future.wait(
      installation.controllerIps.map((ip) => addController(ip))
    );
    
    // Persist for next launch (SECURE STORAGE)
    await _secureStorage.write(key: 'last_active_installation_id', value: installation.id);
    
    notifyListeners();
  }

  /// Gate 1: Audit - Clear the locked session (e.g. on logout)
  Future<void> clearActiveSession() async {
    _activeInstallationId = null;
    _controllers.clear();
    _controllerInfos.clear();
    
    await _secureStorage.delete(key: 'last_active_installation_id');
    
    notifyListeners();
  }

  // ===========================================================================
  // CORE ACTIONS (Delegated to Driver)
  // ===========================================================================

  Future<void> setPower(bool on) async {
    if (currentIp == null) return;
    await _getDriver(currentIp!).setJsonState(currentIp!, {'on': on});
    await addController(currentIp!);
  }

  Future<void> setGlobalBrightness(int brightness) async {
     // Apply to ALL controllers
     _globalBrightness = brightness;
     notifyListeners(); // Optimistic
     
     // Parallelized Broadcast
     await Future.wait(_controllers.keys.map((ip) async {
        await _getDriver(ip).setJsonState(ip, {'bri': brightness});
     }));
  }

  Future<void> applyPreset(int presetId) async {
    _lastPresetId = presetId;
    notifyListeners();

    if (currentIp == null) return;
    await _getDriver(currentIp!).setJsonState(currentIp!, {'ps': presetId});
    await addController(currentIp!);
  }
  
  Future<void> setSegmentState(int segmentId, {
    bool? on,
    int? brightness,
    int? effectId,
    int? paletteId,
    int? speed,
    int? intensity,
    List<int>? rgb,
    bool immediate = false,
  }) async {
    if (currentIp == null) return;

    final key = "seg_$segmentId";
    _debounceTimers[key]?.cancel();

    if (immediate) {
      await _executeSegmentCommand(segmentId, on, brightness, effectId, paletteId, speed, intensity, rgb);
    } else {
      _debounceTimers[key] = Timer(const Duration(milliseconds: 50), () async {
        await _executeSegmentCommand(segmentId, on, brightness, effectId, paletteId, speed, intensity, rgb);
      });
    }
  }

  Future<void> _executeSegmentCommand(int segmentId, bool? on, int? brightness, int? effectId, int? paletteId, int? speed, int? intensity, List<int>? rgb) async {
    final seg = <String, dynamic>{'id': segmentId};
    if (on != null) seg['on'] = on;
    if (brightness != null) seg['bri'] = brightness;
    if (effectId != null) seg['fx'] = effectId;
    if (paletteId != null) seg['pal'] = paletteId;
    if (speed != null) seg['sx'] = speed;
    if (intensity != null) seg['ix'] = intensity;
    if (rgb != null) seg['col'] = [rgb];

    await _getDriver(currentIp!).setJsonState(currentIp!, {'seg': [seg]});
    
    // Auto-refresh after 800ms to allow WLED internal state to settle
    Timer(const Duration(milliseconds: 800), () => addController(currentIp!));
  }

  // ===========================================================================
  // ZONE LOGIC (Merged into Class)
  // ===========================================================================

  List<ZoneEntity> get zones {
    final List<ZoneEntity> list = [];
    controllers.forEach((ip, state) {
      for (var seg in state.segments) {
        // Filter out overlay segments (ID > 10)
        if (seg.id <= 10) {
          list.add(ZoneEntity(
            id: seg.id,
            label: seg.name,
            isOn: seg.on,
            brightness: seg.brightness,
            controllerIp: ip,
          ));
        }
      }
    });
    return list;
  }

  Future<void> setZoneBrightness(String ip, int zoneId, int brightness) async {
    // Determine on/off state based on brightness
    final bool? isOn = brightness > 0 ? true : (brightness == 0 ? false : null);
    
    final driver = _getDriver(ip);
    if (isOn != null) {
       await driver.setJsonState(ip, {'seg': [{'id': zoneId, 'bri': brightness, 'on': isOn}]});
    } else {
       await driver.setJsonState(ip, {'seg': [{'id': zoneId, 'bri': brightness}]});
    }
    await addController(ip);
  }

  // ===========================================================================
  // ADVANCED FEATURES (Delegated)
  // ===========================================================================

  Future<void> triggerReaction({
    required String ip,
    required int start,
    required int count,
    required List<int> color,
    required int effectId,
    required int durationSeconds,
    required int priorityId,
  }) async {
    // PURE DELEGATION - NO LOGIC HERE
    await _getDriver(ip).triggerReaction(
      ip: ip,
      start: start,
      count: count,
      color: color,
      effectId: effectId,
      durationSeconds: durationSeconds,
      priorityId: priorityId
    );
    
    // Refresh to update UI with the new temporary state
    await addController(ip);
      
    // Refresh again after duration to show revert
    Future.delayed(Duration(seconds: durationSeconds + 1), () {
       addController(ip);
    });
  }

  // Toggle Security Mode (Red Blink Override)
  Future<void> toggleSecurityMode(bool enable) async {
    _securityModeEnabled = enable;
    notifyListeners();

    if (currentIp == null) return;
    
    final config = getSceneConfig('security');

    if (enable) {
       // Apply Security Overlay Permanent
       final payload = {
         "seg": [{
            "id": 11,
            "on": true,
            "n": "Security Mode",
            "start": config.start,
            "stop": config.start + config.count,
            "col": [config.color, [0,0,0], [0,0,0]],
            "fx": config.effectId, 
            "sx": 200, "ix": 200
         }]
       };
       await _getDriver(currentIp!).setJsonState(currentIp!, payload);
    } else {
       // Disable Overlay
       await _getDriver(currentIp!).setJsonState(currentIp!, {"seg": [{"id": 11, "on": false}]});
       await applyPreset(_lastPresetId);
    }
    await addController(currentIp!);
  }

  Future<void> applySeasonalTheme() async {
    final DateTime now = DateTime.now();
    final int month = now.month;
    final int day = now.day;

    // Default: Coastal Warmth (Gold/White)
    List<List<int>> colors = [[255, 147, 41], [0, 0, 0], [0, 0, 0]]; 
    int effectId = 0; // Solid
    int paletteId = 0;
    String themeName = "Coastal Night";

    // 1. Christmas (Dec 1 - Dec 31)
    if (month == 12) {
      themeName = "Christmas";
      colors = [[255, 0, 0], [0, 255, 0], [255, 255, 255]];
      effectId = 44; 
      paletteId = 5; 
    } 
    // ... Other seasons ...
    
    if (currentIp != null) {
      final payload = {
        "seg": [
          {
            "id": 0,
            "on": true,
            "col": colors,
            "fx": effectId,
            "pal": paletteId,
            "sx": 128,
            "ix": 128,
            "n": themeName
          }
        ]
      };
      await _getDriver(currentIp!).setJsonState(currentIp!, payload);
      await addController(currentIp!);
    }
  }

  // ===========================================================================
  // LEGACY COMPATIBILITY LAYER (For ZoneDetailSheet & Onboarding)
  // ===========================================================================

  Future<void> flashZone(String ip, int zoneId) async {
     await setZoneBrightness(ip, zoneId, 255);
     await Future.delayed(const Duration(milliseconds: 500));
     await setZoneBrightness(ip, zoneId, 0);
  }

  Future<void> configureZoneCounts(String ip, List<int> counts) async {
     if (counts.length < 3) return;
     int z1 = counts[0];
     int z2 = counts[1];
     int z3 = counts[2];
     
     final segs = [
       {"id": 1, "start": 0, "stop": z1, "n": "Zone 1"},
       {"id": 2, "start": z1, "stop": z1 + z2, "n": "Zone 2"},
       {"id": 3, "start": z1 + z2, "stop": z1 + z2 + z3, "n": "Zone 3"},
     ];

     // ATOMIC SYNC LOOP: No Shortcuts
     bool verified = false;
     int retries = 0;
     
     while (!verified && retries < 3) {
       await _getDriver(ip).setJsonState(ip, {"seg": segs});
       await Future.delayed(const Duration(milliseconds: 500)); // Wait for ESP to commit
       
       await addController(ip);
       final state = getState(ip);
       
       if (state != null) {
         // Check if segments 1, 2, 3 have correct start/stop
         bool match1 = state.segments.any((s) => s.id == 1 && s.start == 0 && s.stop == z1);
         bool match2 = state.segments.any((s) => s.id == 2 && s.start == z1 && s.stop == z1 + z2);
         bool match3 = state.segments.any((s) => s.id == 3 && s.start == z1 + z2 && s.stop == z1 + z2 + z3);
         
         if (match1 && match2 && match3) {
           verified = true;
         } else {
           retries++;
           print("Hardware Sync Mismatch on $ip. Retry $retries...");
         }
       }
     }
     
     if (!verified) {
       throw Exception("Failed to verify hardware segments after 3 attempts on $ip");
     }
  }

  Future<void> toggleSecurityZone(String ip, int zoneId, bool enable) async {
     await setZoneBrightness(ip, zoneId, enable ? 255 : 0);
  }

  // Updated to match ZoneMappingScreen call: setSecurityColor([r,g,b])
  Future<void> setSecurityColor(List<int> colors) async {
     if (colors.length >= 3) {
       _securityColor = colors;
       notifyListeners();
     }
  }
  
  // Helpers for ZoneDetailSheet
  WledSegment? getSegment(String ip, int id) {
    return getState(ip)?.segments.firstWhere((s) => s.id == id, orElse: () => WledSegment(id: id, on: false, brightness: 0, start: 0, stop: 0, name: "?"));
  }

  Future<void> setZoneColor(String ip, int zoneId, List<int> rgb) => setSegmentState(zoneId, rgb: rgb);
  Future<void> setZoneEffect(String ip, int zoneId, int effectId) => setSegmentState(zoneId, effectId: effectId);
  Future<void> setZonePalette(String ip, int zoneId, int paletteId) => setSegmentState(zoneId, paletteId: paletteId);
  Future<void> setZoneSpeed(String ip, int zoneId, int speed) => setSegmentState(zoneId, speed: speed);
  Future<void> setZoneIntensity(String ip, int zoneId, int intensity) => setSegmentState(zoneId, intensity: intensity);
  
  // Bridge / Diagnostics Stubs
  bool get isBridgeActive => false;
  Future<void> enableBridgeMode(String id, bool enable) async {}
  Future<int> checkNetworkHealth() async => 98;
  Future<void> applyGranularConfig(String ip, List<dynamic> points) async {
     print("Granular config applied (STUB)");
  }

  // ===========================================================================
  // PERSISTENCE & CONFIG
  // ===========================================================================

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _securityModeEnabled = prefs.getBool('security_mode') ?? true;
    _activeInstallationId = await _secureStorage.read(key: 'last_active_installation_id');
    // Load Scene Configs (Simplified for now)
  }
  
  SceneConfig getSceneConfig(String id) => _sceneConfigs[id] ?? SceneConfig.defaults(id);
  
  Future<void> saveSceneConfig(String id, SceneConfig config) async {
    _sceneConfigs[id] = config;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scene_config_$id', config.toJsonString());
  }

  @override
  void dispose() {
    for (var timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}

// Configuration Model
class SceneConfig {
  final int start;
  final int count;
  final int durationSeconds;
  final int effectId;
  final List<int> color;

  SceneConfig({
    required this.start,
    required this.count,
    required this.durationSeconds,
    required this.effectId,
    required this.color,
  });

  factory SceneConfig.defaults(String id) {
    if (id == 'welcome') {
      return SceneConfig(start: 0, count: 20, durationSeconds: 10, effectId: 0, color: [255, 147, 41]); // Warm White
    }
    if (id == 'security') {
      return SceneConfig(start: 0, count: 50, durationSeconds: 30, effectId: 1, color: [255, 0, 0]); // Red Blink
    }
    return SceneConfig(start: 0, count: 20, durationSeconds: 10, effectId: 0, color: [255, 255, 255]);
  }

  String toJsonString() {
    return '{"start":$start,"count":$count,"dur":$durationSeconds,"fx":$effectId,"col":[${color[0]},${color[1]},${color[2]}]}';
  }
}

/// Helper model for UI consumption (Legacy 3-Zone contract)
class ZoneEntity {
  final int id;
  final String label;
  final bool isOn;
  final int brightness;
  final String controllerIp;

  ZoneEntity({
    required this.id,
    required this.label,
    required this.isOn,
    required this.brightness,
    required this.controllerIp,
  });
}
