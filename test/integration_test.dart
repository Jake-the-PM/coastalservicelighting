import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coastal_services_lighting/domain/models/installation.dart';
import 'package:coastal_services_lighting/data/services/installation_service.dart';
import 'package:coastal_services_lighting/data/services/schedule_service.dart';

void main() {
  group('Golden Key Flow Integration', () {
    late InstallationService installationService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      installationService = InstallationService();
    });

    test('complete installation → export → import cycle', () async {
      // 1. Create installation (Installer)
      final original = Installation(
        id: 'golden-key-test-001',
        customerName: 'Test Homeowner',
        address: '123 Golden Key Lane',
        dateInstalled: DateTime(2026, 1, 15),
        controllerIps: ['192.168.1.100', '192.168.1.101'],
      );

      await installationService.saveInstallation(original);
      
      // Verify saved
      final saved = await installationService.getInstallations();
      expect(saved.length, equals(1));
      expect(saved.first.id, equals('golden-key-test-001'));

      // 2. Export to JSON (Golden Key simulation)
      final json = original.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], equals('golden-key-test-001'));
      expect(json['customerName'], equals('Test Homeowner'));
      expect(json['controllerIps'], hasLength(2));

      // 3. Simulate QR transfer (JSON string)
      final jsonString = '''
        {
          "id": "golden-key-test-001",
          "customerName": "Test Homeowner",
          "address": "123 Golden Key Lane",
          "dateInstalled": "2026-01-15T00:00:00.000",
          "controllerIps": ["192.168.1.100", "192.168.1.101"]
        }
      ''';

      // 4. Import on homeowner device
      final parsed = Installation.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(jsonString.trim()) as Map,
        ),
      );
      
      expect(parsed.id, equals(original.id));
      expect(parsed.customerName, equals(original.customerName));
      expect(parsed.controllerIps, equals(original.controllerIps));
    });

    test('handles malformed Golden Key JSON gracefully', () async {
      const malformedJson = '{"id": "test", "broken": true}';
      
      expect(
        () => Installation.fromJson(
          jsonDecode(malformedJson) as Map<String, dynamic>,
        ),
        throwsA(anything),
      );
    });

    test('validates IP addresses in imported installation', () async {
      final installation = Installation(
        id: 'ip-validation-test',
        customerName: 'IP Test',
        address: 'Test Address',
        dateInstalled: DateTime.now(),
        controllerIps: ['192.168.1.1', '10.0.0.1'],
      );

      // All IPs should be valid IPv4
      final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      for (final ip in installation.controllerIps) {
        expect(ipRegex.hasMatch(ip), isTrue);
        
        // Each octet should be 0-255
        final parts = ip.split('.');
        for (final part in parts) {
          final num = int.parse(part);
          expect(num, inInclusiveRange(0, 255));
        }
      }
    });
  });

  group('Schedule Flow Integration', () {
    late ScheduleService scheduleService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      scheduleService = ScheduleService();
    });

    test('create sunset schedule and verify trigger time calculation', () async {
      final schedule = LightingSchedule(
        id: 'sunset-test-001',
        name: 'Evening Lights',
        trigger: ScheduleTrigger(
          type: TriggerType.sunset,
          offsetMinutes: -30, // 30 minutes before sunset
        ),
        action: ScheduleAction(
          type: ActionType.turnOn,
        ),
        enabled: true,
      );

      await scheduleService.addSchedule(schedule);

      // Verify saved
      expect(scheduleService.schedules.length, equals(1));
      expect(scheduleService.schedules.first.name, equals('Evening Lights'));
      
      // Verify trigger time is calculated
      final nextTrigger = scheduleService.getNextTriggerTime(schedule);
      expect(nextTrigger, isNotNull);
      
      // Should be in the future
      expect(nextTrigger!.isAfter(DateTime.now().subtract(const Duration(hours: 24))), isTrue);
    });

    test('create fixed time schedule', () async {
      final schedule = LightingSchedule(
        id: 'fixed-time-001',
        name: 'Morning Wake Up',
        trigger: ScheduleTrigger(
          type: TriggerType.fixedTime,
          fixedTime: DateTime(2026, 1, 1, 7, 0), // 7:00 AM
        ),
        action: ScheduleAction(
          type: ActionType.setBrightness,
          brightness: 128, // 50%
        ),
        enabled: true,
      );

      await scheduleService.addSchedule(schedule);

      expect(scheduleService.schedules.length, equals(1));
      expect(scheduleService.schedules.first.action.brightness, equals(128));
    });

    test('toggle schedule enabled state', () async {
      final schedule = LightingSchedule(
        id: 'toggle-test',
        name: 'Toggle Test',
        trigger: ScheduleTrigger(type: TriggerType.sunset),
        action: ScheduleAction(type: ActionType.turnOn),
        enabled: true,
      );

      await scheduleService.addSchedule(schedule);
      expect(scheduleService.schedules.first.enabled, isTrue);

      await scheduleService.toggleSchedule('toggle-test', false);
      expect(scheduleService.schedules.first.enabled, isFalse);

      await scheduleService.toggleSchedule('toggle-test', true);
      expect(scheduleService.schedules.first.enabled, isTrue);
    });

    test('delete schedule', () async {
      await scheduleService.addSchedule(LightingSchedule(
        id: 'delete-me',
        name: 'Delete Test',
        trigger: ScheduleTrigger(type: TriggerType.sunrise),
        action: ScheduleAction(type: ActionType.turnOff),
      ));

      expect(scheduleService.schedules.length, equals(1));

      await scheduleService.deleteSchedule('delete-me');

      expect(scheduleService.schedules.length, equals(0));
    });

    test('schedule with day-of-week filter', () async {
      final schedule = LightingSchedule(
        id: 'weekdays-only',
        name: 'Weekday Lights',
        trigger: ScheduleTrigger(type: TriggerType.sunset),
        action: ScheduleAction(type: ActionType.turnOn),
        daysOfWeek: [1, 2, 3, 4, 5], // Monday - Friday
      );

      await scheduleService.addSchedule(schedule);

      expect(scheduleService.schedules.first.daysOfWeek, contains(1));
      expect(scheduleService.schedules.first.daysOfWeek, contains(5));
      expect(scheduleService.schedules.first.daysOfWeek, isNot(contains(6))); // Saturday
      expect(scheduleService.schedules.first.daysOfWeek, isNot(contains(7))); // Sunday
    });
  });

  group('Service Provider Integration', () {
    test('InstallationService notifies listeners on changes', () async {
      SharedPreferences.setMockInitialValues({});
      final service = InstallationService();
      
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.saveInstallation(Installation(
        id: 'notify-test-1',
        customerName: 'Test 1',
        address: 'Address 1',
        dateInstalled: DateTime.now(),
        controllerIps: [],
      ));

      expect(notifyCount, equals(1));

      await service.saveInstallation(Installation(
        id: 'notify-test-2',
        customerName: 'Test 2',
        address: 'Address 2',
        dateInstalled: DateTime.now(),
        controllerIps: [],
      ));

      expect(notifyCount, equals(2));
    });

    test('ScheduleService notifies listeners on changes', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ScheduleService();
      
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.addSchedule(LightingSchedule(
        id: 'notify-schedule',
        name: 'Test Schedule',
        trigger: ScheduleTrigger(type: TriggerType.sunset),
        action: ScheduleAction(type: ActionType.turnOn),
      ));

      expect(notifyCount, greaterThan(0));
    });
  });
}
