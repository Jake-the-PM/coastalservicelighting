import 'dart:async';
import '../../data/repositories/lighting_repository.dart';
import '../../domain/contracts/schemas.dart';

/// Service compliant with "App Is Executor" invariant.
/// Handles inbound actions from Integration Engine (Rocket.new)
class AutomationService {
  final LightingRepository _lightingRepo;

  AutomationService(this._lightingRepo);

  /// Receives an Action Payload (e.g. via HTTP/Webhook or Local Listener)
  Future<void> executeAction(AutomationAction action) async {
    debugPrint("Executing Action: ${action.commandType} on ${action.targetZones}");

    // 1. Check Security Policy
    if (!_lightingRepo.securityModeEnabled) {
       if (action.commandType != 'POWER') {
          debugPrint("Automation Blocked: Security Mode is DISABLED.");
          return;
       }
    }

    // 2. Resolve Target Zone IDs
    List<int> zoneIds = [];
    if (action.targetZones.contains('ALL') || action.targetZones.contains('ALL_ZONES')) {
      zoneIds = [1, 2, 3];
    } else {
      for (var label in action.targetZones) {
        if (label == 'ZONE_1') zoneIds.add(1);
        if (label == 'ZONE_2') zoneIds.add(2);
        if (label == 'ZONE_3') zoneIds.add(3);
      }
    }

    // 3. Execute Primary Command
    
    // Global Presets
    if (action.commandType == 'APPLY_PRESET') {
       final presetId = action.value as int?;
       if (presetId != null) {
         await _lightingRepo.applyPreset(presetId);
       }
       return;
    }

    // Zone-Specific Commands (iterate all controllers)
    for (var entry in _lightingRepo.controllers.entries) {
      final ip = entry.key;
      // final state = entry.value; // Not used here, just need IP
      
      for (var zoneId in zoneIds) {
        switch (action.commandType) {
          case 'SET_EFFECT':
             // Effects are applied via presets in this implementation
             break;
          case 'POWER':
             bool isOn = action.value == true || action.value == 'ON';
             await _lightingRepo.setZoneBrightness(ip, zoneId, isOn ? 128 : 0); 
             break;
          case 'SET_BRIGHTNESS':
            final val = action.value as int?;
            if (val != null) {
               await _lightingRepo.setZoneBrightness(ip, zoneId, val);
            }
            break;
        }
      }
    }

    // 4. Enforce Brightness Policy (Return-to-State Hook)
    if (action.brightnessPolicy == 'OVERRIDE' && action.brightnessOverride != null) {
      _saveSnapshot(zoneIds);

      for (var entry in _lightingRepo.controllers.entries) {
        final ip = entry.key;
        final state = entry.value;
        for (var seg in state.segments) {
          if (zoneIds.contains(seg.id)) {
            await _lightingRepo.setZoneBrightness(ip, seg.id, action.brightnessOverride!);
          }
        }
      }
      
      _scheduleRestore(const Duration(seconds: 15));
    }
  }

  // --- Return-to-State Logic ---
  
  Map<String, int>? _snapshotBrightness; // key = "ip:zoneId"
  Timer? _restoreTimer;

  void _saveSnapshot(List<int> targetZones) {
    if (_snapshotBrightness != null) return;
    
    debugPrint("Automation: Snapshotting state before override...");
    _snapshotBrightness = {};
    for (var z in _lightingRepo.zones) {
       if (targetZones.contains(z.id)) {
          // Store brightness keyed by controller IP + zone ID
          for (var entry in _lightingRepo.controllers.entries) {
            _snapshotBrightness!["${entry.key}:${z.id}"] = z.brightness;
          }
       }
    }
  }

  void _scheduleRestore(Duration delay) {
    _restoreTimer?.cancel();
    _restoreTimer = Timer(delay, () {
       _restoreState();
    });
  }

  Future<void> _restoreState() async {
    if (_snapshotBrightness == null) return;
    
    debugPrint("Automation: Restoring state...");
    for (var entry in _snapshotBrightness!.entries) {
       final parts = entry.key.split(':');
       if (parts.length == 2) {
         final ip = parts[0];
         final zoneId = int.tryParse(parts[1]) ?? 1;
         await _lightingRepo.setZoneBrightness(ip, zoneId, entry.value);
       }
    }
    _snapshotBrightness = null;
    _restoreTimer = null;
  }
}

void debugPrint(String message) {
  // Use Flutter's debugPrint in debug mode only
  assert(() {
    // ignore: avoid_print
    print(message);
    return true;
  }());
}
