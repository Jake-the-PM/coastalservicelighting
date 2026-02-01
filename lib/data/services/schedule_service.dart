import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Represents a scheduled lighting event
class LightingSchedule {
  final String id;
  final String name;
  final ScheduleTrigger trigger;
  final ScheduleAction action;
  final List<int> daysOfWeek; // 1=Mon, 7=Sun (empty = every day)
  final bool enabled;
  final DateTime? lastTriggered;

  LightingSchedule({
    required this.id,
    required this.name,
    required this.trigger,
    required this.action,
    this.daysOfWeek = const [],
    this.enabled = true,
    this.lastTriggered,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'trigger': trigger.toJson(),
    'action': action.toJson(),
    'daysOfWeek': daysOfWeek,
    'enabled': enabled,
    'lastTriggered': lastTriggered?.toIso8601String(),
  };

  factory LightingSchedule.fromJson(Map<String, dynamic> json) => LightingSchedule(
    id: json['id'],
    name: json['name'],
    trigger: ScheduleTrigger.fromJson(json['trigger']),
    action: ScheduleAction.fromJson(json['action']),
    daysOfWeek: List<int>.from(json['daysOfWeek'] ?? []),
    enabled: json['enabled'] ?? true,
    lastTriggered: json['lastTriggered'] != null 
        ? DateTime.parse(json['lastTriggered']) 
        : null,
  );

  LightingSchedule copyWith({
    String? id,
    String? name,
    ScheduleTrigger? trigger,
    ScheduleAction? action,
    List<int>? daysOfWeek,
    bool? enabled,
    DateTime? lastTriggered,
  }) => LightingSchedule(
    id: id ?? this.id,
    name: name ?? this.name,
    trigger: trigger ?? this.trigger,
    action: action ?? this.action,
    daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    enabled: enabled ?? this.enabled,
    lastTriggered: lastTriggered ?? this.lastTriggered,
  );
}

/// When to trigger the schedule
class ScheduleTrigger {
  final TriggerType type;
  final DateTime? fixedTime; // For TIME_FIXED
  final int offsetMinutes; // For SUNRISE/SUNSET (e.g., -30 = 30 min before)

  ScheduleTrigger({
    required this.type,
    this.fixedTime,
    this.offsetMinutes = 0,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'fixedTime': fixedTime?.toIso8601String(),
    'offsetMinutes': offsetMinutes,
  };

  factory ScheduleTrigger.fromJson(Map<String, dynamic> json) => ScheduleTrigger(
    type: TriggerType.values.firstWhere((t) => t.name == json['type']),
    fixedTime: json['fixedTime'] != null ? DateTime.parse(json['fixedTime']) : null,
    offsetMinutes: json['offsetMinutes'] ?? 0,
  );
}

enum TriggerType { sunrise, sunset, fixedTime }

/// What to do when triggered
class ScheduleAction {
  final ActionType type;
  final int? brightness; // 0-255
  final int? presetId;
  final List<String>? targetZones; // null = all zones

  ScheduleAction({
    required this.type,
    this.brightness,
    this.presetId,
    this.targetZones,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'brightness': brightness,
    'presetId': presetId,
    'targetZones': targetZones,
  };

  factory ScheduleAction.fromJson(Map<String, dynamic> json) => ScheduleAction(
    type: ActionType.values.firstWhere((a) => a.name == json['type']),
    brightness: json['brightness'],
    presetId: json['presetId'],
    targetZones: json['targetZones'] != null 
        ? List<String>.from(json['targetZones']) 
        : null,
  );
}

enum ActionType { turnOn, turnOff, setBrightness, applyPreset }

/// Service to manage and execute lighting schedules
class ScheduleService extends ChangeNotifier {
  static const String _storageKey = 'coastal_schedules';
  
  List<LightingSchedule> _schedules = [];
  Timer? _evaluationTimer;
  
  // Location for sunrise/sunset calculation (default: Miami, FL)
  double _latitude = 25.7617;
  double _longitude = -80.1918;

  List<LightingSchedule> get schedules => List.unmodifiable(_schedules);
  
  // Callback for when a schedule should execute
  final LightingRepository _repo;

  ScheduleService(this._repo) {
    _loadSchedules();
    _startEvaluationLoop();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    
    if (data != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data);
        _schedules = jsonList.map((j) => LightingSchedule.fromJson(j)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to load schedules: $e');
      }
    }
  }

  Future<void> _saveSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_schedules.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  void _startEvaluationLoop() {
    // Check every minute
    _evaluationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _evaluateSchedules();
    });
  }

  void _evaluateSchedules() {
    final now = DateTime.now();
    
    for (final schedule in _schedules) {
      if (!schedule.enabled) continue;
      
      // Check day of week filter
      if (schedule.daysOfWeek.isNotEmpty) {
        if (!schedule.daysOfWeek.contains(now.weekday)) continue;
      }
      
      // Check if trigger time matches
      final triggerTime = _getTriggerTime(schedule.trigger, now);
      if (triggerTime == null) continue;
      
      // Check if within the evaluation window (same hour and minute)
      if (now.hour == triggerTime.hour && now.minute == triggerTime.minute) {
        // Prevent double-triggering within the same minute
        if (schedule.lastTriggered != null) {
          final diff = now.difference(schedule.lastTriggered!);
          if (diff.inMinutes < 2) continue;
        }
        
        // Execute!
        _executeSchedule(schedule);
      }
    }
  }

  DateTime? _getTriggerTime(ScheduleTrigger trigger, DateTime date) {
    switch (trigger.type) {
      case TriggerType.fixedTime:
        if (trigger.fixedTime == null) return null;
        return DateTime(
          date.year, date.month, date.day,
          trigger.fixedTime!.hour, trigger.fixedTime!.minute,
        );
        
      case TriggerType.sunrise:
        final sunrise = _calculateSunrise(date);
        return sunrise.add(Duration(minutes: trigger.offsetMinutes));
        
      case TriggerType.sunset:
        final sunset = _calculateSunset(date);
        return sunset.add(Duration(minutes: trigger.offsetMinutes));
    }
  }

  /// Simplified sunrise calculation (actual implementation would use astronomy lib)
  DateTime _calculateSunrise(DateTime date) {
    // Rough approximation for demonstration
    // Real implementation: https://en.wikipedia.org/wiki/Sunrise_equation
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final hourOffset = 6 + (2 * (dayOfYear - 172).abs() / 365); // Rough seasonal adjustment
    return DateTime(date.year, date.month, date.day, hourOffset.round(), 30);
  }

  /// Simplified sunset calculation
  DateTime _calculateSunset(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final hourOffset = 18 + (2 * (172 - dayOfYear).abs() / 365);
    return DateTime(date.year, date.month, date.day, hourOffset.round(), 0);
  }

  void _executeSchedule(LightingSchedule schedule) {
    debugPrint('Executing schedule: ${schedule.name}');
    
    // Update last triggered
    final updatedSchedule = schedule.copyWith(lastTriggered: DateTime.now());
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      _schedules[index] = updatedSchedule;
      _saveSchedules();
    }
    
    // Protocol Delta: Real-world hardware execution
    final action = schedule.action;
    switch (action.type) {
      case ActionType.turnOn:
        _repo.setPower(true);
        break;
      case ActionType.turnOff:
        _repo.setPower(false);
        break;
      case ActionType.setBrightness:
        if (action.brightness != null) {
          _repo.setGlobalBrightness(action.brightness!);
        }
        break;
      case ActionType.applyPreset:
        if (action.presetId != null) {
          _repo.applyPreset(action.presetId!);
        }
        break;
    }
    
    notifyListeners();
  }

  // CRUD Operations
  
  Future<void> addSchedule(LightingSchedule schedule) async {
    _schedules.add(schedule);
    await _saveSchedules();
    notifyListeners();
  }

  Future<void> updateSchedule(LightingSchedule schedule) async {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      _schedules[index] = schedule;
      await _saveSchedules();
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    _schedules.removeWhere((s) => s.id == id);
    await _saveSchedules();
    notifyListeners();
  }

  Future<void> toggleSchedule(String id, bool enabled) async {
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index >= 0) {
      _schedules[index] = _schedules[index].copyWith(enabled: enabled);
      await _saveSchedules();
      notifyListeners();
    }
  }

  void setLocation(double latitude, double longitude) {
    _latitude = latitude;
    _longitude = longitude;
    notifyListeners();
  }

  /// Get next trigger time for a schedule
  DateTime? getNextTriggerTime(LightingSchedule schedule) {
    if (!schedule.enabled) return null;
    
    var checkDate = DateTime.now();
    
    // Check next 7 days
    for (int i = 0; i < 7; i++) {
      if (schedule.daysOfWeek.isEmpty || 
          schedule.daysOfWeek.contains(checkDate.weekday)) {
        final time = _getTriggerTime(schedule.trigger, checkDate);
        if (time != null && time.isAfter(DateTime.now())) {
          return time;
        }
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }
    
    return null;
  }

  @override
  void dispose() {
    _evaluationTimer?.cancel();
    super.dispose();
  }
}
