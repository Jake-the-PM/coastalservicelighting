import 'package:flutter_test/flutter_test.dart';
import 'package:coastal_services_lighting/data/services/schedule_service.dart';

void main() {
  group('ScheduleService - Trigger Time Calculation', () {
    late ScheduleService service;

    setUp(() {
      service = ScheduleService();
    });

    tearDown(() {
      service.dispose();
    });

    test('calculates next trigger for sunset schedule', () {
      final schedule = LightingSchedule(
        id: 'sunset-test',
        name: 'Sunset Test',
        trigger: ScheduleTrigger(
          type: TriggerType.sunset,
          offsetMinutes: 0,
        ),
        action: ScheduleAction(type: ActionType.turnOn),
        enabled: true,
      );

      final nextTrigger = service.getNextTriggerTime(schedule);
      
      expect(nextTrigger, isNotNull);
      // Sunset should be in the evening (typically after 5 PM)
      expect(nextTrigger!.hour, greaterThanOrEqualTo(16));
    });

    test('calculates next trigger for sunrise schedule', () {
      final schedule = LightingSchedule(
        id: 'sunrise-test',
        name: 'Sunrise Test',
        trigger: ScheduleTrigger(
          type: TriggerType.sunrise,
          offsetMinutes: 0,
        ),
        action: ScheduleAction(type: ActionType.turnOff),
        enabled: true,
      );

      final nextTrigger = service.getNextTriggerTime(schedule);
      
      expect(nextTrigger, isNotNull);
      // Sunrise should be in the morning (typically 5-8 AM)
      expect(nextTrigger!.hour, lessThan(12));
    });

    test('applies offset to sunset trigger', () {
      final scheduleNoOffset = LightingSchedule(
        id: 'no-offset',
        name: 'No Offset',
        trigger: ScheduleTrigger(type: TriggerType.sunset, offsetMinutes: 0),
        action: ScheduleAction(type: ActionType.turnOn),
        enabled: true,
      );

      final scheduleWithOffset = LightingSchedule(
        id: 'with-offset',
        name: 'With Offset',
        trigger: ScheduleTrigger(type: TriggerType.sunset, offsetMinutes: -30),
        action: ScheduleAction(type: ActionType.turnOn),
        enabled: true,
      );

      final noOffset = service.getNextTriggerTime(scheduleNoOffset);
      final withOffset = service.getNextTriggerTime(scheduleWithOffset);

      if (noOffset != null && withOffset != null) {
        // The offset schedule should be 30 minutes earlier
        final difference = noOffset.difference(withOffset);
        expect(difference.inMinutes, equals(30));
      }
    });

    test('respects day-of-week filter', () {
      final today = DateTime.now();
      final schedule = LightingSchedule(
        id: 'weekday-only',
        name: 'Weekday Only',
        trigger: ScheduleTrigger(type: TriggerType.sunset),
        action: ScheduleAction(type: ActionType.turnOn),
        daysOfWeek: [1, 2, 3, 4, 5], // Monday-Friday only
        enabled: true,
      );

      final nextTrigger = service.getNextTriggerTime(schedule);
      
      if (nextTrigger != null) {
        // Next trigger should be on a weekday
        expect(nextTrigger.weekday, lessThanOrEqualTo(5));
      }
    });

    test('returns null for disabled schedule', () {
      final schedule = LightingSchedule(
        id: 'disabled',
        name: 'Disabled Schedule',
        trigger: ScheduleTrigger(type: TriggerType.sunset),
        action: ScheduleAction(type: ActionType.turnOn),
        enabled: false, // Disabled
      );

      final nextTrigger = service.getNextTriggerTime(schedule);
      expect(nextTrigger, isNull);
    });
  });

  group('LightingSchedule Model', () {
    test('toJson and fromJson round-trip correctly', () {
      final original = LightingSchedule(
        id: 'roundtrip-test',
        name: 'Roundtrip Test',
        trigger: ScheduleTrigger(
          type: TriggerType.sunset,
          offsetMinutes: -15,
        ),
        action: ScheduleAction(
          type: ActionType.setBrightness,
          brightness: 128,
        ),
        daysOfWeek: [1, 3, 5],
        enabled: true,
      );

      final json = original.toJson();
      final restored = LightingSchedule.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.trigger.type, equals(original.trigger.type));
      expect(restored.trigger.offsetMinutes, equals(original.trigger.offsetMinutes));
      expect(restored.action.type, equals(original.action.type));
      expect(restored.action.brightness, equals(original.action.brightness));
      expect(restored.daysOfWeek, equals(original.daysOfWeek));
      expect(restored.enabled, equals(original.enabled));
    });

    test('copyWith creates modified copy', () {
      final original = LightingSchedule(
        id: 'original',
        name: 'Original Name',
        trigger: ScheduleTrigger(type: TriggerType.sunrise),
        action: ScheduleAction(type: ActionType.turnOn),
        enabled: true,
      );

      final modified = original.copyWith(
        name: 'Modified Name',
        enabled: false,
      );

      expect(modified.id, equals(original.id)); // Unchanged
      expect(modified.name, equals('Modified Name')); // Changed
      expect(modified.enabled, isFalse); // Changed
    });
  });

  group('ScheduleAction Model', () {
    test('toJson includes all fields', () {
      final action = ScheduleAction(
        type: ActionType.applyPreset,
        presetId: 5,
        targetZones: ['zone1', 'zone2'],
      );

      final json = action.toJson();

      expect(json['type'], equals('applyPreset'));
      expect(json['presetId'], equals(5));
      expect(json['targetZones'], contains('zone1'));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'type': 'turnOn',
      };

      final action = ScheduleAction.fromJson(json);

      expect(action.type, equals(ActionType.turnOn));
      expect(action.brightness, isNull);
      expect(action.presetId, isNull);
      expect(action.targetZones, isNull);
    });
  });

  group('ScheduleTrigger Model', () {
    test('handles fixed time trigger', () {
      final trigger = ScheduleTrigger(
        type: TriggerType.fixedTime,
        fixedTime: DateTime(2026, 1, 15, 18, 30),
      );

      final json = trigger.toJson();
      final restored = ScheduleTrigger.fromJson(json);

      expect(restored.type, equals(TriggerType.fixedTime));
      expect(restored.fixedTime?.hour, equals(18));
      expect(restored.fixedTime?.minute, equals(30));
    });

    test('handles sunset trigger with offset', () {
      final trigger = ScheduleTrigger(
        type: TriggerType.sunset,
        offsetMinutes: 45,
      );

      expect(trigger.type, equals(TriggerType.sunset));
      expect(trigger.offsetMinutes, equals(45));
      expect(trigger.fixedTime, isNull);
    });
  });
}
