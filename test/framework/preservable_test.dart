import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equatable/equatable.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_notifier.dart';

// --- Test Data and Mocks ---

class TestSettings extends Equatable {
  final String value;
  const TestSettings(this.value);

  @override
  List<Object?> get props => [value];
}

class TestStatus extends Equatable {
  const TestStatus();
  @override
  List<Object?> get props => [];
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
}

class TestNotifier extends Notifier<TestState>
    with PreservableNotifierMixin<TestSettings, TestStatus, TestState> {
  @override
  TestState build() {
    return const TestState(
      settings: Preservable(original: TestSettings('initial'), current: TestSettings('initial')),
      status: TestStatus(),
    );
  }

  void updateValue(String newValue) {
    state = state.copyWith(
      settings: state.settings.update(TestSettings(newValue)),
    );
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

    test('isDirty should be true after update() is called with different data', () {
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
      final provider = NotifierProvider<TestNotifier, TestState>(TestNotifier.new);
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
  });
}
