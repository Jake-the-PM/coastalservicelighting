class WledInfo {
  final String ver;
  final String mac;
  final int ledCount;
  final int maxPower;
  final int maxSegments;
  final String name;
  final String arch;

  WledInfo({
    required this.ver,
    required this.mac,
    required this.ledCount,
    required this.maxPower,
    required this.maxSegments,
    required this.name,
    required this.arch,
  });

  factory WledInfo.fromJson(Map<String, dynamic> json) {
    final leds = json['leds'] as Map<String, dynamic>? ?? {};
    return WledInfo(
      ver: json['ver'] as String? ?? 'unknown',
      mac: json['mac'] as String? ?? '',
      ledCount: leds['count'] as int? ?? 0,
      maxPower: leds['maxpwr'] as int? ?? 0,
      maxSegments: leds['maxseg'] as int? ?? 1,
      name: json['name'] as String? ?? 'WLED',
      arch: json['arch'] as String? ?? 'unknown',
    );
  }
}

class WledState {
  final bool on;
  final int brightness;
  final int activePreset;
  final List<WledSegment> segments;
  
  WledState({
    required this.on,
    required this.brightness,
    required this.activePreset,
    required this.segments,
  });

  factory WledState.fromJson(Map<String, dynamic> json) {
    var segList = <WledSegment>[];
    if (json['seg'] != null) {
      json['seg'].forEach((v) {
        segList.add(WledSegment.fromJson(v));
      });
    }

    return WledState(
      on: json['on'] as bool? ?? false,
      brightness: json['bri'] as int? ?? 0,
      activePreset: json['ps'] as int? ?? -1,
      segments: segList,
    );
  }

  /// Deep copy with overrides
  WledState copyWith({
    bool? on,
    int? brightness,
    int? activePreset,
    List<WledSegment>? segments,
  }) {
    return WledState(
      on: on ?? this.on,
      brightness: brightness ?? this.brightness,
      activePreset: activePreset ?? this.activePreset,
      segments: segments ?? this.segments.map((s) => s.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'on': on,
      'bri': brightness,
      'seg': segments.map((s) => s.toJson()).toList(),
      // 'ps': activePreset // Don't restore preset ID, just the active segments/colors
    };
  }
}

class WledSegment {
  final int id;
  final bool on;
  final int brightness;
  final int start;
  final int stop;
  final String name;
  final int effectId;
  final int paletteId;
  final int speed;
  final int intensity;
  final List<List<int>> colors; // Primary, Secondary, Tertiary

  WledSegment({
    required this.id,
    required this.on,
    required this.brightness,
    required this.start,
    required this.stop,
    required this.name,
    this.effectId = 0, // Solid
    this.paletteId = 0, // Default
    this.speed = 128,
    this.intensity = 128,
    this.colors = const [[255, 160, 0], [0, 0, 0], [0, 0, 0]],
  });

  factory WledSegment.fromJson(Map<String, dynamic> json) {
    // Parse color array safety
    List<List<int>> parsedColors = [];
    if (json['col'] != null) {
      for (var c in json['col']) {
        if (c is List) {
          parsedColors.add(c.cast<int>());
        }
      }
    }
    if (parsedColors.isEmpty) {
      parsedColors = [[255, 160, 0], [0, 0, 0], [0, 0, 0]];
    }

    return WledSegment(
      id: json['id'] as int? ?? 0,
      on: json['on'] as bool? ?? true,
      brightness: json['bri'] as int? ?? 255,
      start: json['start'] as int? ?? 0,
      stop: json['stop'] as int? ?? 0,
      name: json['n'] as String? ?? 'Zone ${json['id'] != null ? (json['id'] as int) + 1 : "?"}',
      effectId: json['fx'] as int? ?? 0,
      paletteId: json['pal'] as int? ?? 0,
      speed: json['sx'] as int? ?? 128,
      intensity: json['ix'] as int? ?? 128,
      colors: parsedColors,
    );
  }

  WledSegment copyWith({
    int? id,
    bool? on,
    int? brightness,
    int? start,
    int? stop,
    String? name,
    int? effectId,
    int? paletteId,
    int? speed,
    int? intensity,
    List<List<int>>? colors,
  }) {
    return WledSegment(
      id: id ?? this.id,
      on: on ?? this.on,
      brightness: brightness ?? this.brightness,
      start: start ?? this.start,
      stop: stop ?? this.stop,
      name: name ?? this.name,
      effectId: effectId ?? this.effectId,
      paletteId: paletteId ?? this.paletteId,
      speed: speed ?? this.speed,
      intensity: intensity ?? this.intensity,
      colors: colors ?? this.colors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'on': on,
      'bri': brightness,
      'start': start,
      'stop': stop,
      'n': name,
      'fx': effectId,
      'pal': paletteId,
      'sx': speed,
      'ix': intensity,
      'col': colors,
    };
  }
}
