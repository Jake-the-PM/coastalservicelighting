import '../wled/wled_models.dart';
import 'i_lighting_driver.dart';

/// Simulation driver for Demo Mode.
/// Keeps state in memory and mimics WLED behavior (e.g. segments, overrides).
class WledDemoDriver implements ILightingDriver {
  // In-Memory State
  WledState _state = WledState(
    on: true,
    brightness: 128,
    activePreset: 1,
    segments: [
      WledSegment(id: 0, start: 0, stop: 150, name: "Main Zone", on: true, brightness: 255, colors: [[255,147,41], [0,0,0], [0,0,0]])
    ],
  );

  @override
  Future<(WledInfo, WledState)?> getStatus(String ip) async {
    // Return fake info and current state
    return (
      WledInfo(
        ver: "0.14.0-Demo",
        mac: "DE:AD:BE:EF:CA:FE",
        ledCount: 150,
        maxPower: 850,
        maxSegments: 16,
        name: "Coastal Demo",
        arch: "esp32",
      ),
      _state.copyWith() // Return copy to prevent external mutation
    );
  }

  @override
  Future<bool> setJsonState(String ip, Map<String, dynamic> json) async {
    print("DEMO_DRIVER: Receiving Update: $json");
    
    // Parse partial update and merge into _state
    // 1. Global On/Off
    bool? newOn = json['on'];
    int? newBri = json['bri'];
    int? newPs = json['ps'];
    
    List<WledSegment> currentSegs = List.from(_state.segments);
    
    // 2. Segment Updates
    if (json['seg'] != null) {
      final List<dynamic> updates = json['seg'];
      for (var update in updates) {
        if (update is Map<String, dynamic>) {
          int id = update['id'] ?? 0;
          
          // Check if segment exists
          int index = currentSegs.indexWhere((s) => s.id == id);
          if (index != -1) {
            // Update existing
            WledSegment existing = currentSegs[index];
            currentSegs[index] = _mergeSegment(existing, update);
          } else {
             // Create new (if it's an overlay)
             // Only allow if ID is provided
             currentSegs.add(WledSegment.fromJson(update));
          }
        }
      }
    }

    _state = _state.copyWith(
      on: newOn ?? _state.on,
      brightness: newBri ?? _state.brightness,
      activePreset: newPs ?? _state.activePreset,
      segments: currentSegs,
    );
    
    return true;
  }
  
  // Helper to merge partial JSON into Segment
  WledSegment _mergeSegment(WledSegment original, Map<String, dynamic> update) {
    // Parse colors if present
    List<List<int>>? newCols;
    if (update['col'] != null) {
       newCols = [];
       for(var c in update['col']) {
         if (c is List) newCols.add(c.cast<int>());
       }
    }

    return original.copyWith(
      on: update['on'] ?? original.on,
      brightness: update['bri'] ?? original.brightness,
      effectId: update['fx'] ?? original.effectId,
      paletteId: update['pal'] ?? original.paletteId,
      start: update['start'] ?? original.start,
      stop: update['stop'] ?? original.stop,
      colors: newCols ?? original.colors,
    );
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
    print("DEMO_DRIVER: Trigger Reaction ID $priorityId");

    // 1. Apply Overlay Segment
    final overlay = WledSegment(
      id: priorityId,
      start: start,
      stop: start + count,
      name: priorityId == 12 ? "Doorbell Overlay" : "Motion Overlay",
      on: true,
      brightness: 255,
      colors: [[color[0], color[1], color[2]], [0,0,0], [0,0,0]],
      effectId: effectId,
      speed: 128,
      intensity: 128,
    );
    
    // Add or Replace in State
    List<WledSegment> segs = List.from(_state.segments);
    segs.removeWhere((s) => s.id == priorityId);
    segs.add(overlay);
    
    _state = _state.copyWith(segments: segs);
    // (In a real app, we'd fire a stream controller here to notify listeners immediately)

    // 2. Schedule Removal
    Future.delayed(Duration(seconds: durationSeconds), () {
       print("DEMO_DRIVER: Clearing Reaction ID $priorityId");
       List<WledSegment> cleaned = List.from(_state.segments);
       cleaned.removeWhere((s) => s.id == priorityId);
       _state = _state.copyWith(segments: cleaned);
    });
  }

  @override
  Future<List<String>> scanForDevices() async {
    return ["demo"];
  }
}
