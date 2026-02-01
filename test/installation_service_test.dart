import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coastal_services_lighting/data/services/installation_service.dart';
import 'package:coastal_services_lighting/domain/models/installation.dart';

void main() {
  group('InstallationService', () {
    late InstallationService service;

    setUp(() {
      // Initialize SharedPreferences with empty values
      SharedPreferences.setMockInitialValues({});
      service = InstallationService();
    });

    test('getInstallations returns empty list when no data exists', () async {
      final installations = await service.getInstallations();
      expect(installations, isEmpty);
    });

    test('saveInstallation adds new installation', () async {
      final installation = Installation(
        id: 'test-1',
        customerName: 'Test Customer',
        address: '123 Test St',
        dateInstalled: DateTime(2026, 1, 15),
        controllerIps: ['192.168.1.100'],
      );

      await service.saveInstallation(installation);
      final installations = await service.getInstallations();

      expect(installations.length, equals(1));
      expect(installations.first.id, equals('test-1'));
      expect(installations.first.customerName, equals('Test Customer'));
    });

    test('saveInstallation updates existing installation', () async {
      final original = Installation(
        id: 'update-test',
        customerName: 'Original Name',
        address: 'Original Address',
        dateInstalled: DateTime(2026, 1, 1),
        controllerIps: [],
      );

      await service.saveInstallation(original);

      final updated = Installation(
        id: 'update-test', // Same ID
        customerName: 'Updated Name',
        address: 'Updated Address',
        dateInstalled: DateTime(2026, 1, 1),
        controllerIps: ['10.0.0.1'],
      );

      await service.saveInstallation(updated);
      final installations = await service.getInstallations();

      expect(installations.length, equals(1));
      expect(installations.first.customerName, equals('Updated Name'));
      expect(installations.first.address, equals('Updated Address'));
      expect(installations.first.controllerIps, contains('10.0.0.1'));
    });

    test('deleteInstallation removes installation by ID', () async {
      final installation = Installation(
        id: 'delete-test',
        customerName: 'To Be Deleted',
        address: 'Nowhere',
        dateInstalled: DateTime.now(),
        controllerIps: [],
      );

      await service.saveInstallation(installation);
      var installations = await service.getInstallations();
      expect(installations.length, equals(1));

      await service.deleteInstallation('delete-test');
      installations = await service.getInstallations();
      expect(installations, isEmpty);
    });

    test('deleteInstallation with non-existent ID does not throw', () async {
      expect(
        () async => await service.deleteInstallation('non-existent'),
        returnsNormally,
      );
    });

    test('handles multiple installations correctly', () async {
      for (int i = 0; i < 5; i++) {
        await service.saveInstallation(Installation(
          id: 'multi-$i',
          customerName: 'Customer $i',
          address: 'Address $i',
          dateInstalled: DateTime.now(),
          controllerIps: [],
        ));
      }

      final installations = await service.getInstallations();
      expect(installations.length, equals(5));

      // Verify all IDs are unique
      final ids = installations.map((i) => i.id).toSet();
      expect(ids.length, equals(5));
    });

    test('getInstallerInstallations returns stream', () async {
      final installation = Installation(
        id: 'stream-test',
        customerName: 'Stream Test',
        address: 'Stream Address',
        dateInstalled: DateTime.now(),
        controllerIps: [],
      );

      await service.saveInstallation(installation);

      final stream = service.getInstallerInstallations('any-uid');
      final result = await stream.first;

      expect(result, isNotEmpty);
      expect(result.first.id, equals('stream-test'));
    });

    test('getHomeownerInstallations returns stream', () async {
      final stream = service.getHomeownerInstallations('any-uid');
      expect(stream, isA<Stream<List<Installation>>>());
    });

    test('getAssignedInstallations returns empty list (local mode)', () async {
      final result = await service.getAssignedInstallations('test@example.com');
      expect(result, isEmpty);
    });

    test('claimInstallation returns true (local mode)', () async {
      final result = await service.claimInstallation('any-id', 'any-user');
      expect(result, isTrue);
    });

    test('notifies listeners on save', () async {
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.saveInstallation(Installation(
        id: 'notify-test',
        customerName: 'Notify',
        address: 'Test',
        dateInstalled: DateTime.now(),
        controllerIps: [],
      ));

      expect(notifyCount, equals(1));
    });

    test('notifies listeners on delete', () async {
      await service.saveInstallation(Installation(
        id: 'delete-notify',
        customerName: 'Delete Notify',
        address: 'Test',
        dateInstalled: DateTime.now(),
        controllerIps: [],
      ));

      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.deleteInstallation('delete-notify');

      expect(notifyCount, equals(1));
    });
  });

  group('InstallationService Resilience', () {
    test('handles corrupted SharedPreferences data gracefully', () async {
      // Simulate corrupted data
      SharedPreferences.setMockInitialValues({
        'coastal_installations_registry': 'not-valid-json',
      });

      final service = InstallationService();
      final installations = await service.getInstallations();

      // Should return empty list, not throw
      expect(installations, isEmpty);
    });

    test('handles malformed JSON array gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'coastal_installations_registry': '[{"broken": true}]',
      });

      final service = InstallationService();
      
      // This will fail if Installation.fromJson throws on missing fields
      // The test documents the current behavior
      expect(
        () async => await service.getInstallations(),
        throwsA(anything), // Documents that we DON'T handle this gracefully yet
      );
    });
  });
}
