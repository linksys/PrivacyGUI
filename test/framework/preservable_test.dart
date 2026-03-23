import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';

// --- Test Data and Mocks ---

class TestSettings extends Equatable {
  final String value;
  const TestSettings(this.value);

  @override
  List<Object?> get props => [value];

  Map<String, dynamic> toMap() {
    return {'value': value};
  }

  factory TestSettings.fromMap(Map<String, dynamic> map) {
    return TestSettings(map['value'] as String);
  }
}

class TestStatus extends Equatable {
  const TestStatus();

  @override
  List<Object?> get props => [];

  Map<String, dynamic> toMap() {
    return {};
  }

  factory TestStatus.fromMap(Map<String, dynamic> map) {
    return const TestStatus();
  }
}

class TestState extends FeatureState<TestSettings, TestStatus> {
  const TestState({required super.settings, required super.status});

  @override
  TestState copyWith({
    Preservable<TestSettings>? settings,
    TestStatus? status,
  }) {
    return TestState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'settings': settings.toMap((value) => value.toMap()),
      'status': status.toMap(),
    };
  }

  factory TestState.fromMap(Map<String, dynamic> map) {
    return TestState(
      settings: Preservable.fromMap(
        map['settings'],
        (map) => TestSettings.fromMap(map),
      ),
      status: TestStatus.fromMap(map['status']),
    );
  }
}

/// A status that carries an optional message for testing error display paths.
class TestStatusWithMessage extends Equatable {
  final String? message;
  const TestStatusWithMessage([this.message]);

  @override
  List<Object?> get props => [message];

  Map<String, dynamic> toMap() => {'message': message};

  factory TestStatusWithMessage.fromMap(Map<String, dynamic> map) =>
      TestStatusWithMessage(map['message'] as String?);
}

class TestNotifier extends Notifier<TestState>
    with PreservableNotifierMixin<TestSettings, TestStatus, TestState> {
  /// Hook to control performFetch behavior from tests.
  Future<(TestSettings?, TestStatus?)> Function({
    bool forceRemote,
    bool updateStatusOnly,
  })? fetchOverride;

  /// Hook to control performSave behavior from tests.
  Future<void> Function()? saveOverride;

  /// Tracks how many times performFetch was actually called.
  int fetchCallCount = 0;

  @override
  TestState build() {
    return const TestState(
      settings: Preservable(
          original: TestSettings('initial'), current: TestSettings('initial')),
      status: TestStatus(),
    );
  }

  void updateValue(String newValue) {
    state = state.copyWith(
      settings: state.settings.update(TestSettings(newValue)),
    );
  }

  @override
  Future<(TestSettings?, TestStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    fetchCallCount++;
    if (fetchOverride != null) {
      return fetchOverride!(
          forceRemote: forceRemote, updateStatusOnly: updateStatusOnly);
    }
    if (updateStatusOnly) {
      return (null, const TestStatus());
    }
    return (const TestSettings('fetched'), const TestStatus());
  }

  @override
  Future<void> performSave() async {
    if (saveOverride != null) {
      return saveOverride!();
    }
  }
}

void main() {
  group('Preservable Data Wrapper', () {
    const initialData = TestSettings('initial');
    const updatedData = TestSettings('updated');

    test('isDirty should be false after initialization', () {
      final state = Preservable(original: initialData, current: initialData);
      expect(state.isDirty, isFalse);
    }, tags: 'dirty-guard-framework');

    test('isDirty should be true after update() is called with different data',
        () {
      final state = Preservable(original: initialData, current: initialData);
      final newState = state.update(updatedData);
      expect(newState.isDirty, isTrue);
    }, tags: 'dirty-guard-framework');

    test('isDirty should be false after saved() is called', () {
      final state = Preservable(original: initialData, current: updatedData);
      expect(state.isDirty, isTrue);
      final newState = state.saved();
      expect(newState.isDirty, isFalse);
      expect(newState.original, equals(updatedData));
    }, tags: 'dirty-guard-framework');
  });

  group('PreservableNotifierMixin', () {
    late ProviderContainer container;
    late TestNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      final provider =
          NotifierProvider<TestNotifier, TestState>(TestNotifier.new);
      notifier = container.read(provider.notifier);
    });

    test('isDirty() is false initially', () {
      expect(notifier.isDirty(), isFalse);
    }, tags: 'dirty-guard-framework');

    test('isDirty() is true after updating state', () {
      notifier.updateValue('new value');
      expect(notifier.isDirty(), isTrue);
    }, tags: 'dirty-guard-framework');

    test('revert() makes state not dirty and restores current value', () {
      notifier.updateValue('new value');
      expect(notifier.isDirty(), isTrue);

      notifier.revert();

      expect(notifier.isDirty(), isFalse);
      expect(notifier.state.settings.current.value, 'initial');
    }, tags: 'dirty-guard-framework');

    test('markAsSaved() makes state not dirty and updates original value', () {
      notifier.updateValue('new value');
      expect(notifier.isDirty(), isTrue);

      notifier.markAsSaved();

      expect(notifier.isDirty(), isFalse);
      expect(notifier.state.settings.original.value, 'new value');
    }, tags: 'dirty-guard-framework');

    test('fetch() calls performFetch and updates state correctly', () async {
      // isDirty should be false initially
      expect(notifier.isDirty(), isFalse);
      // state should be 'initial'
      expect(notifier.state.settings.current.value, 'initial');

      await notifier.fetch();

      // isDirty should still be false after a fetch
      expect(notifier.isDirty(), isFalse);
      // both original and current should be updated to 'fetched'
      expect(notifier.state.settings.original.value, 'fetched');
      expect(notifier.state.settings.current.value, 'fetched');
    }, tags: 'dirty-guard-framework');

    test('save() calls performSave, marks state as saved, and then fetches',
        () async {
      notifier.updateValue('new value');
      expect(notifier.isDirty(), isTrue);

      await notifier.save();

      // isDirty should be false after save + fetch
      expect(notifier.isDirty(), isFalse);
      // The final state should be the one from fetch(), not the one from markAsSaved()
      expect(notifier.state.settings.original.value, 'fetched');
    }, tags: 'dirty-guard-framework');
  });

  // ---------------------------------------------------------------------------
  // _PreservableDelegate gap coverage
  // ---------------------------------------------------------------------------

  group('_PreservableDelegate — updateStatusOnly path', () {
    late ProviderContainer container;
    late TestNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      final provider =
          NotifierProvider<TestNotifier, TestState>(TestNotifier.new);
      notifier = container.read(provider.notifier);
    });

    test('fetch(updateStatusOnly: true) updates status only', () async {
      // Start with known state
      await notifier.fetch();
      expect(notifier.state.settings.current.value, 'fetched');

      // Override fetch to return only a new status
      notifier.fetchOverride =
          ({forceRemote = false, updateStatusOnly = false}) async {
        return (null, const TestStatus());
      };

      await notifier.fetch(updateStatusOnly: true);

      // Settings should remain 'fetched', not be overwritten
      expect(notifier.state.settings.current.value, 'fetched');
      expect(notifier.state.settings.original.value, 'fetched');
      expect(notifier.isDirty(), isFalse);
    }, tags: 'dirty-guard-framework');

    test('fetch(updateStatusOnly: true) with null status is no-op', () async {
      await notifier.fetch();
      final stateBefore = notifier.state;

      notifier.fetchOverride =
          ({forceRemote = false, updateStatusOnly = false}) async {
        return (null, null);
      };

      await notifier.fetch(updateStatusOnly: true);

      // State unchanged when both returns are null
      expect(notifier.state, equals(stateBefore));
    }, tags: 'dirty-guard-framework');
  });

  group('_PreservableDelegate — onSseInvalidation', () {
    late ProviderContainer container;
    late TestNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      final provider =
          NotifierProvider<TestNotifier, TestState>(TestNotifier.new);
      notifier = container.read(provider.notifier);
    });

    test('onSseInvalidation() skips fetch when dirty', () async {
      notifier.updateValue('unsaved edit');
      expect(notifier.isDirty(), isTrue);

      final countBefore = notifier.fetchCallCount;
      notifier.onSseInvalidation();
      await Future.delayed(Duration.zero);

      // performFetch should NOT have been called
      expect(notifier.fetchCallCount, equals(countBefore));
      // Unsaved edit preserved
      expect(notifier.state.settings.current.value, 'unsaved edit');
    }, tags: 'dirty-guard-framework');

    test('onSseInvalidation() triggers fetch when clean', () async {
      expect(notifier.isDirty(), isFalse);

      final countBefore = notifier.fetchCallCount;
      notifier.onSseInvalidation();
      await Future.delayed(Duration.zero);

      // performFetch SHOULD have been called
      expect(notifier.fetchCallCount, greaterThan(countBefore));
      expect(notifier.state.settings.current.value, 'fetched');
    }, tags: 'dirty-guard-framework');

    test('onSseInvalidation() fetch error is caught gracefully', () async {
      expect(notifier.isDirty(), isFalse);

      notifier.fetchOverride =
          ({forceRemote = false, updateStatusOnly = false}) async {
        throw Exception('network error');
      };

      // Should not throw — error is caught by catchError in delegate
      notifier.onSseInvalidation();
      await Future.delayed(Duration.zero);

      // State should remain as initial (error was caught, not propagated)
      expect(notifier.state.settings.current.value, 'initial');
    }, tags: 'dirty-guard-framework');
  });

  group('_PreservableDelegate — error display path', () {
    late ProviderContainer container;
    late TestNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      final provider =
          NotifierProvider<TestNotifier, TestState>(TestNotifier.new);
      notifier = container.read(provider.notifier);
    });

    test(
        'performFetch returns (null, status) — settings unchanged, status updated',
        () async {
      // Set initial state via a normal fetch
      await notifier.fetch();
      expect(notifier.state.settings.current.value, 'fetched');

      // Override: simulate an error — settings null, only status returned
      notifier.fetchOverride =
          ({forceRemote = false, updateStatusOnly = false}) async {
        return (null, const TestStatus());
      };

      await notifier.fetch();

      // Settings should be unchanged (still 'fetched')
      expect(notifier.state.settings.current.value, 'fetched');
      expect(notifier.state.settings.original.value, 'fetched');
    }, tags: 'dirty-guard-framework');

    test('performFetch returns (null, null) — state completely unchanged',
        () async {
      await notifier.fetch();
      final stateBefore = notifier.state;

      notifier.fetchOverride =
          ({forceRemote = false, updateStatusOnly = false}) async {
        return (null, null);
      };

      await notifier.fetch();

      expect(notifier.state, equals(stateBefore));
    }, tags: 'dirty-guard-framework');
  });

  group('_PreservableDelegate — save re-fetch failure', () {
    late ProviderContainer container;
    late TestNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      final provider =
          NotifierProvider<TestNotifier, TestState>(TestNotifier.new);
      notifier = container.read(provider.notifier);
    });

    test('save() re-fetch failure still leaves state as saved (not dirty)',
        () async {
      notifier.updateValue('edited');
      expect(notifier.isDirty(), isTrue);

      // Save succeeds, but subsequent fetch throws
      bool saveCalled = false;
      notifier.saveOverride = () async {
        saveCalled = true;
      };
      notifier.fetchOverride =
          ({forceRemote = false, updateStatusOnly = false}) async {
        throw Exception('re-fetch failed');
      };

      // save() should propagate the error
      expect(() => notifier.save(), throwsA(isA<Exception>()));
      await Future.delayed(Duration.zero);

      expect(saveCalled, isTrue);
      // markAsSaved() was called before the re-fetch, so isDirty should be false
      expect(notifier.isDirty(), isFalse);
      // Original should have been updated to the edited value by markAsSaved
      expect(notifier.state.settings.original.value, 'edited');
    }, tags: 'dirty-guard-framework');
  });

  group('_PreservableDelegate — fetch with forceRemote', () {
    late ProviderContainer container;
    late TestNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      final provider =
          NotifierProvider<TestNotifier, TestState>(TestNotifier.new);
      notifier = container.read(provider.notifier);
    });

    test('fetch(forceRemote: true) updates both settings and status', () async {
      bool forceRemoteReceived = false;
      notifier.fetchOverride =
          ({forceRemote = false, updateStatusOnly = false}) async {
        forceRemoteReceived = forceRemote;
        return (const TestSettings('remote'), const TestStatus());
      };

      await notifier.fetch(forceRemote: true);

      expect(forceRemoteReceived, isTrue);
      expect(notifier.state.settings.current.value, 'remote');
      expect(notifier.state.settings.original.value, 'remote');
      expect(notifier.isDirty(), isFalse);
    }, tags: 'dirty-guard-framework');

    test('fetch() with settings resets dirty state', () async {
      notifier.updateValue('dirty edit');
      expect(notifier.isDirty(), isTrue);

      await notifier.fetch();

      // After fetch, original and current are both 'fetched' — clean
      expect(notifier.isDirty(), isFalse);
      expect(notifier.state.settings.current.value, 'fetched');
    }, tags: 'dirty-guard-framework');
  });
}
