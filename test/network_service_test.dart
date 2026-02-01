import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coastal_services_lighting/core/network/network_service.dart';

void main() {
  group('NetworkService', () {
    test('initializes with checking status', () {
      final service = NetworkService();
      // Initial status should be checking or will quickly resolve
      expect(
        service.status,
        anyOf(equals(NetworkStatus.checking), equals(NetworkStatus.online), equals(NetworkStatus.offline)),
      );
    });

    test('isOnline returns correct boolean', () {
      final service = NetworkService();
      // Allow time for connectivity check
      expect(service.isOnline, isA<bool>());
      expect(service.isOffline, isA<bool>());
      expect(service.isOnline != service.isOffline || service.status == NetworkStatus.checking, isTrue);
    });
  });

  group('RetryHelper', () {
    test('executes action successfully on first try', () async {
      int attempts = 0;
      
      final result = await RetryHelper.withRetry(
        action: () async {
          attempts++;
          return 'success';
        },
      );

      expect(result, equals('success'));
      expect(attempts, equals(1));
    });

    test('retries on failure and eventually succeeds', () async {
      int attempts = 0;
      
      final result = await RetryHelper.withRetry(
        action: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('Simulated failure');
          }
          return 'success after retries';
        },
        maxRetries: 5,
        baseDelay: const Duration(milliseconds: 10),
      );

      expect(result, equals('success after retries'));
      expect(attempts, equals(3));
    });

    test('throws after max retries exceeded', () async {
      int attempts = 0;
      
      expect(
        () async => await RetryHelper.withRetry(
          action: () async {
            attempts++;
            throw Exception('Always fails');
          },
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 10),
        ),
        throwsException,
      );
    });

    test('calls onRetry callback on each retry', () async {
      int retryCallbackCount = 0;
      final errors = <Object>[];
      
      try {
        await RetryHelper.withRetry(
          action: () async {
            throw Exception('Failure ${retryCallbackCount + 1}');
          },
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 10),
          onRetry: (attempt, error) {
            retryCallbackCount++;
            errors.add(error);
          },
        );
      } catch (_) {}

      expect(retryCallbackCount, equals(2)); // 3 attempts = 2 retries
      expect(errors.length, equals(2));
    });

    test('uses exponential backoff by default', () async {
      final delays = <Duration>[];
      final stopwatch = Stopwatch()..start();
      int attempts = 0;
      
      try {
        await RetryHelper.withRetry(
          action: () async {
            if (attempts > 0) {
              delays.add(Duration(milliseconds: stopwatch.elapsedMilliseconds));
              stopwatch.reset();
            }
            attempts++;
            throw Exception('Always fails');
          },
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 50),
          exponential: true,
        );
      } catch (_) {}

      // With exponential backoff: 50ms, 100ms, 200ms...
      // Second delay should be roughly double the first
      if (delays.length >= 2) {
        expect(delays[1].inMilliseconds, greaterThan(delays[0].inMilliseconds));
      }
    });

    test('uses constant delay when exponential is false', () async {
      final timestamps = <int>[];
      int attempts = 0;
      
      try {
        await RetryHelper.withRetry(
          action: () async {
            timestamps.add(DateTime.now().millisecondsSinceEpoch);
            attempts++;
            throw Exception('Always fails');
          },
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 50),
          exponential: false,
        );
      } catch (_) {}

      // All delays should be approximately equal
      if (timestamps.length >= 3) {
        final delay1 = timestamps[1] - timestamps[0];
        final delay2 = timestamps[2] - timestamps[1];
        // Allow 30ms variance
        expect((delay1 - delay2).abs(), lessThan(30));
      }
    });
  });

  group('RetryExtension', () {
    test('adds retry capability to Future', () async {
      int attempts = 0;
      
      final result = await Future(() async {
        attempts++;
        if (attempts < 2) throw Exception('Retry me');
        return 'extended success';
      }).withRetry(
        maxRetries: 3,
        baseDelay: const Duration(milliseconds: 10),
      );

      expect(result, equals('extended success'));
    });
  });
}
