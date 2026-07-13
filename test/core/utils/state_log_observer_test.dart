import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/state_log_observer.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

// --- Test Models ---

class TestLoggableState extends Equatable with DiagnosticLoggable {
  final String value;

  const TestLoggableState(this.value);

  @override
  Map<String, Object?> get namedProps => {'value': value};
}

class TestSensitiveState extends Equatable with DiagnosticLoggable {
  final String macAddress;
  final String serialNumber;
  final String password;

  const TestSensitiveState({
    required this.macAddress,
    required this.serialNumber,
    required this.password,
  });

  @override
  Map<String, Object?> get namedProps => {
        'macAddress': macAddress,
        'serialNumber': serialNumber,
        'password': password,
      };
}

class TestNonLoggableState extends Equatable with DiagnosticLoggable {
  final String value;

  const TestNonLoggableState(this.value);

  @override
  Map<String, Object?> get namedProps => {'value': value};

  @override
  bool get loggable => false;
}

class TestPlainState extends Equatable {
  final String value;

  const TestPlainState(this.value);

  @override
  List<Object?> get props => [value];
}

// --- Test Providers (Async) ---

final asyncLoggableProvider =
    AsyncNotifierProvider<AsyncLoggableNotifier, TestLoggableState>(
  AsyncLoggableNotifier.new,
);

class AsyncLoggableNotifier extends AsyncNotifier<TestLoggableState> {
  @override
  Future<TestLoggableState> build() async {
    return const TestLoggableState('initial');
  }

  void setValue(String value) {
    state = AsyncData(TestLoggableState(value));
  }
}

final asyncNonLoggableProvider =
    AsyncNotifierProvider<AsyncNonLoggableNotifier, TestNonLoggableState>(
  AsyncNonLoggableNotifier.new,
);

class AsyncNonLoggableNotifier extends AsyncNotifier<TestNonLoggableState> {
  @override
  Future<TestNonLoggableState> build() async {
    return const TestNonLoggableState('initial');
  }

  void setValue(String value) {
    state = AsyncData(TestNonLoggableState(value));
  }
}

final asyncPlainProvider =
    AsyncNotifierProvider<AsyncPlainNotifier, TestPlainState>(
  AsyncPlainNotifier.new,
);

class AsyncPlainNotifier extends AsyncNotifier<TestPlainState> {
  @override
  Future<TestPlainState> build() async {
    return const TestPlainState('initial');
  }
}

// --- Test Providers (Sync) ---

final syncLoggableProvider =
    NotifierProvider<SyncLoggableNotifier, TestLoggableState>(
  SyncLoggableNotifier.new,
);

class SyncLoggableNotifier extends Notifier<TestLoggableState> {
  @override
  TestLoggableState build() {
    return const TestLoggableState('sync-initial');
  }

  void setValue(String value) {
    state = TestLoggableState(value);
  }
}

// --- Test Helpers ---

/// Tracks calls to updateStateLog for verification
class StateLogTracker {
  final List<(String, String)> calls = [];

  void track(String typeName, String state) {
    calls.add((typeName, state));
  }

  void clear() => calls.clear();

  bool hasCall(String typeName) => calls.any((c) => c.$1 == typeName);

  String? getState(String typeName) =>
      calls.where((c) => c.$1 == typeName).lastOrNull?.$2;
}

// --- Tests ---

void main() {
  group('StateLogObserver', () {
    late StateLogObserver observer;
    late ProviderContainer container;

    setUp(() {
      clearStateLogCacheForTest();
      observer = StateLogObserver();
      container = ProviderContainer(observers: [observer]);
    });

    tearDown(() {
      container.dispose();
      clearStateLogCacheForTest();
    });

    group('AsyncValue providers', () {
      test('captures DiagnosticLoggable state with loggable=true', () async {
        // Trigger build and wait
        await container.read(asyncLoggableProvider.future);

        // Verify initial state is cached
        expect(stateLogCacheForTest['TestLoggableState'], isNotNull);
        expect(
          stateLogCacheForTest['TestLoggableState'],
          equals('{"value":"initial"}'),
        );

        // Update state
        container.read(asyncLoggableProvider.notifier).setValue('updated');

        // Verify updated state is cached
        expect(
          stateLogCacheForTest['TestLoggableState'],
          equals('{"value":"updated"}'),
        );
      });

      test('skips DiagnosticLoggable state with loggable=false', () async {
        await container.read(asyncNonLoggableProvider.future);
        container.read(asyncNonLoggableProvider.notifier).setValue('updated');

        // Observer should skip due to loggable=false — not in cache
        expect(stateLogCacheForTest['TestNonLoggableState'], isNull);
      });

      test('skips non-DiagnosticLoggable state', () async {
        await container.read(asyncPlainProvider.future);

        // Observer should skip because TestPlainState doesn't have mixin
        expect(stateLogCacheForTest['TestPlainState'], isNull);
      });

      test('skips AsyncLoading state', () async {
        // Read provider while it's loading (don't await)
        container.read(asyncLoggableProvider);

        // At this point state is AsyncLoading — should not be cached yet
        // (cache should be empty since loading state is skipped)
        expect(stateLogCacheForTest['TestLoggableState'], isNull);
      });

      test('skips AsyncError state', () async {
        // Create a provider that errors
        final errorProvider =
            AsyncNotifierProvider<ErrorNotifier, TestLoggableState>(
          ErrorNotifier.new,
        );
        final errorContainer = ProviderContainer(observers: [observer]);

        try {
          await errorContainer.read(errorProvider.future);
        } catch (_) {
          // Expected
        }

        // Observer should skip error states — not in cache
        expect(stateLogCacheForTest['TestLoggableState'], isNull);

        errorContainer.dispose();
      });
    });

    group('Sync providers', () {
      test('captures sync DiagnosticLoggable state on update', () {
        // Read triggers build — but didUpdateProvider is NOT called on initial build
        final state = container.read(syncLoggableProvider);
        expect(state.value, equals('sync-initial'));

        // Initial state is NOT cached (didUpdateProvider only fires on state changes)
        expect(stateLogCacheForTest['TestLoggableState'], isNull);

        // Update — this triggers didUpdateProvider
        container.read(syncLoggableProvider.notifier).setValue('sync-updated');

        // Now updated state is cached
        expect(
          stateLogCacheForTest['TestLoggableState'],
          equals('{"value":"sync-updated"}'),
        );
      });
    });

    group('didUpdateProvider behavior', () {
      test('extracts value from AsyncData correctly', () async {
        await container.read(asyncLoggableProvider.future);

        final state = container.read(asyncLoggableProvider);
        expect(state.hasValue, isTrue);
        expect(state.value?.value, equals('initial'));
      });

      test('handles null value in AsyncData', () async {
        // Create provider that can have null
        final nullableProvider =
            AsyncNotifierProvider<NullableNotifier, TestLoggableState?>(
                NullableNotifier.new);
        final nullContainer = ProviderContainer(observers: [observer]);

        await nullContainer.read(nullableProvider.future);

        // Observer should skip null values — cache should be empty
        expect(stateLogCacheForTest.isEmpty, isTrue);

        nullContainer.dispose();
      });
    });
  });

  group('Integration: DiagnosticLoggable + StateLogObserver', () {
    test('complex nested state produces valid JSON', () async {
      final container = ProviderContainer(observers: [StateLogObserver()]);

      await container.read(asyncLoggableProvider.future);

      final state = container.read(asyncLoggableProvider).value!;
      final json = state.toString();

      expect(json, equals('{"value":"initial"}'));

      container.dispose();
    });
  });

  group('Sensitive data masking', () {
    late StateLogObserver observer;
    late ProviderContainer container;

    setUp(() {
      clearStateLogCacheForTest();
      observer = StateLogObserver();
      container = ProviderContainer(observers: [observer]);
    });

    tearDown(() {
      container.dispose();
      clearStateLogCacheForTest();
    });

    test('masks MAC addresses in state log cache', () async {
      // Use async provider so initial build triggers didUpdateProvider
      final sensitiveProvider =
          AsyncNotifierProvider<AsyncSensitiveNotifier, TestSensitiveState>(
        AsyncSensitiveNotifier.new,
      );

      // Await initial build — this triggers didUpdateProvider for async providers
      await container.read(sensitiveProvider.future);

      final cached = stateLogCacheForTest['TestSensitiveState'];
      expect(cached, isNotNull);

      // MAC address should be masked (XX:XX:XX:XX:EE:FF pattern)
      expect(cached, contains('XX:XX:XX:XX'));
      expect(cached, isNot(contains('AA:BB:CC:DD')));

      // Serial number should be masked (only last 4 visible)
      expect(cached, contains('****5678'));
      expect(cached, isNot(contains('SN12345678')));

      // Password should be masked
      expect(cached, contains('***'));
      expect(cached, isNot(contains('secret123')));
    });
  });
}

// --- Additional Test Notifiers ---

class AsyncSensitiveNotifier extends AsyncNotifier<TestSensitiveState> {
  @override
  Future<TestSensitiveState> build() async {
    return const TestSensitiveState(
      macAddress: 'AA:BB:CC:DD:EE:FF',
      serialNumber: 'SN12345678',
      password: 'secret123',
    );
  }
}

// --- Additional Test Notifiers ---

class ErrorNotifier extends AsyncNotifier<TestLoggableState> {
  @override
  Future<TestLoggableState> build() async {
    throw Exception('Test error');
  }
}

class NullableNotifier extends AsyncNotifier<TestLoggableState?> {
  @override
  Future<TestLoggableState?> build() async {
    return null;
  }
}
