import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/retry_strategy/retry.dart';

void main() {
  group('RetryStrategy', () {
    test('should execute successfully on first attempt', () async {
      final strategy = ExponentialBackoffRetryStrategy(maxRetries: 3);
      final result = await strategy.execute(() async => 'success');
      expect(result, 'success');
    });

    test('should retry until success', () async {
      int attempt = 0;
      final strategy = ExponentialBackoffRetryStrategy(maxRetries: 3);

      final result = await strategy.execute(
        () async {
          if (attempt++ < 2) {
            throw Exception('Temporary failure');
          }
          return 'success';
        },
      );

      expect(result, 'success');
      expect(attempt, 3);
    });

    test('should throw MaxRetriesExceededException when max retries reached',
        () async {
      final strategy = ExponentialBackoffRetryStrategy(maxRetries: 2);

      expect(
        () => strategy.execute(
          () async => throw Exception('Permanent failure'),
        ),
        throwsA(isA<MaxRetriesExceededException>()),
      );
    });

    test('should call onRetry callback for each retry', () async {
      int retryCount = 0;
      final strategy = ExponentialBackoffRetryStrategy(maxRetries: 3);

      try {
        await strategy.execute(
          () async => throw Exception('Failure'),
          onRetry: (attempt) => retryCount++,
        );
      } catch (_) {}

      expect(retryCount, 3);
    });
  });

  group('ExponentialBackoffRetryStrategy', () {
    test('should calculate correct delays', () {
      final strategy = ExponentialBackoffRetryStrategy(
        initialDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 30),
      );

      expect(strategy.calculateDelay(0).inSeconds, 1); // 1 * 2^0 = 1
      expect(strategy.calculateDelay(1).inSeconds, 2); // 1 * 2^1 = 2
      expect(strategy.calculateDelay(2).inSeconds, 4); // 1 * 2^2 = 4
      expect(strategy.calculateDelay(3).inSeconds, 8); // 1 * 2^3 = 8
    });

    test('should respect maxDelay', () {
      final strategy = ExponentialBackoffRetryStrategy(
        initialDelay: const Duration(seconds: 10),
        maxDelay: const Duration(seconds: 15),
      );

      expect(strategy.calculateDelay(0).inSeconds, 10); // 10 * 2^0 = 10
      expect(strategy.calculateDelay(1).inSeconds,
          15); // 10 * 2^1 = 20, but capped at 15
      expect(strategy.calculateDelay(2).inSeconds,
          15); // 10 * 2^2 = 40, but capped at 15
    });
  });

  group('ExponentialBackoffWithJitterRetryStrategy', () {
    test('should return delay within expected range', () {
      final strategy = ExponentialBackoffWithJitterRetryStrategy(
        initialDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 30),
      );

      for (int i = 0; i < 10; i++) {
        final delay =
            strategy.calculateDelay(2); // 1 * 2^2 = 4 seconds theoretical max
        expect(delay.inSeconds, greaterThanOrEqualTo(0));
        expect(delay.inSeconds, lessThanOrEqualTo(4));
      }
    });
  });

  group('LinearBackoffRetryStrategy', () {
    test('should calculate correct delays', () {
      final strategy = LinearBackoffRetryStrategy(
        initialDelay: const Duration(seconds: 1),
        increment: const Duration(seconds: 2),
        maxDelay: const Duration(seconds: 10),
      );

      expect(strategy.calculateDelay(0).inSeconds, 1); // 1 + (2 * 0) = 1
      expect(strategy.calculateDelay(1).inSeconds, 3); // 1 + (2 * 1) = 3
      expect(strategy.calculateDelay(2).inSeconds, 5); // 1 + (2 * 2) = 5
    });
  });

  group('FibonacciBackoffRetryStrategy', () {
    test('should calculate correct delays', () {
      final strategy = FibonacciBackoffRetryStrategy(
        initialDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 100),
      );

      // Fibonacci sequence: 0, 1, 1, 2, 3, 5, 8, 13...
      // We use retryAttempt + 1 to get: 1, 1, 2, 3, 5, 8, 13...
      expect(strategy.calculateDelay(0).inSeconds, 1); // 1 * 1 = 1
      expect(strategy.calculateDelay(1).inSeconds, 1); // 1 * 1 = 1
      expect(strategy.calculateDelay(2).inSeconds, 2); // 1 * 2 = 2
      expect(strategy.calculateDelay(3).inSeconds, 3); // 1 * 3 = 3
      expect(strategy.calculateDelay(4).inSeconds, 5); // 1 * 5 = 5
    });
  });

  group('PolynomialGrowthRetryStrategy', () {
    test('should calculate correct delays with power of 2', () {
      final strategy = PolynomialGrowthRetryStrategy(
        initialDelay: const Duration(seconds: 1),
        power: 2.0,
        maxDelay: const Duration(seconds: 100),
      );

      expect(strategy.calculateDelay(0).inSeconds, 1); // 1 * (0+1)^2 = 1
      expect(strategy.calculateDelay(1).inSeconds, 4); // 1 * (1+1)^2 = 4
      expect(strategy.calculateDelay(2).inSeconds, 9); // 1 * (2+1)^2 = 9
      expect(strategy.calculateDelay(3).inSeconds, 16); // 1 * (3+1)^2 = 16
    });

    test('should respect custom power value', () {
      final strategy = PolynomialGrowthRetryStrategy(
        initialDelay: const Duration(seconds: 1),
        power: 3.0, // Cubic growth
        maxDelay: const Duration(seconds: 100),
      );

      expect(strategy.calculateDelay(0).inSeconds, 1); // 1 * (0+1)^3 = 1
      expect(strategy.calculateDelay(1).inSeconds, 8); // 1 * (1+1)^3 = 8
      expect(strategy.calculateDelay(2).inSeconds, 27); // 1 * (2+1)^3 = 27
    });
  });

  test('should use shouldRetry callback to determine retry', () async {
    int attempt = 0;
    final strategy = ExponentialBackoffRetryStrategy(maxRetries: 3);

    final result = await strategy.execute(
      () async => attempt++,
      shouldRetry: (result) => result < 2, // Retry if result is less than 2
    );

    expect(result, 2); // Should stop when result is 2 (3rd attempt: 0, 1, 2)
    expect(attempt, 3);
  });

  test('should throw ShouldRetryException when shouldRetry returns true',
      () async {
    final strategy = ExponentialBackoffRetryStrategy(maxRetries: 0);

    expect(
      () => strategy.execute(
        () async => 'retry',
        shouldRetry: (result) => result == 'retry',
      ),
      throwsA(isA<MaxRetriesExceededException>()),
    );
  });

  group('Max Delay Tests', () {
    test('ExponentialBackoffRetryStrategy should respect maxDelay', () {
      final strategy = ExponentialBackoffRetryStrategy(
        initialDelay: const Duration(seconds: 10),
        maxDelay: const Duration(seconds: 15),
      );

      // Test multiple attempts to ensure maxDelay is consistently applied
      for (int i = 0; i < 5; i++) {
        final delay = strategy.calculateDelay(i);
        expect(delay.inSeconds, lessThanOrEqualTo(15));
      }
    });

    test('ExponentialBackoffWithJitterRetryStrategy should respect maxDelay',
        () {
      final strategy = ExponentialBackoffWithJitterRetryStrategy(
        initialDelay: const Duration(seconds: 10),
        maxDelay: const Duration(seconds: 15),
      );

      // Test multiple attempts to ensure maxDelay is consistently applied
      for (int i = 0; i < 5; i++) {
        final delay = strategy.calculateDelay(i);
        expect(delay.inSeconds, lessThanOrEqualTo(15));
      }
    });

    test('LinearBackoffRetryStrategy should respect maxDelay', () {
      final strategy = LinearBackoffRetryStrategy(
        initialDelay: const Duration(seconds: 10),
        increment: const Duration(seconds: 5),
        maxDelay: const Duration(seconds: 20),
      );

      // Test multiple attempts to ensure maxDelay is consistently applied
      for (int i = 0; i < 10; i++) {
        final delay = strategy.calculateDelay(i);
        expect(delay.inSeconds, lessThanOrEqualTo(20));
      }
    });

    test('FibonacciBackoffRetryStrategy should respect maxDelay', () {
      final strategy = FibonacciBackoffRetryStrategy(
        initialDelay: const Duration(seconds: 5),
        maxDelay: const Duration(seconds: 20),
      );

      // Test multiple attempts to ensure maxDelay is consistently applied
      for (int i = 0; i < 10; i++) {
        final delay = strategy.calculateDelay(i);
        expect(delay.inSeconds, lessThanOrEqualTo(20));
      }
    });

    test('PolynomialGrowthRetryStrategy should respect maxDelay', () {
      final strategy = PolynomialGrowthRetryStrategy(
        initialDelay: const Duration(seconds: 1),
        power: 3.0,
        maxDelay: const Duration(seconds: 10),
      );

      // Test multiple attempts to ensure maxDelay is consistently applied
      for (int i = 0; i < 10; i++) {
        final delay = strategy.calculateDelay(i);
        expect(delay.inSeconds, lessThanOrEqualTo(10));
      }
    });
  });
}
