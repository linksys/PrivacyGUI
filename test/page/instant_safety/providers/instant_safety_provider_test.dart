import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/page/instant_safety/services/instant_safety_service.dart';

class MockInstantSafetyService extends Mock
    implements UspInstantSafetyService {}

void main() {
  late MockInstantSafetyService mockService;

  setUpAll(() {
    registerFallbackValue(SafeBrowsingType.off);
  });

  setUp(() {
    mockService = MockInstantSafetyService();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspInstantSafetyServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
    );
    container.listen(uspInstantSafetyProvider, (_, __) {});
    return container;
  }

  // ---------------------------------------------------------------------------
  // UspInstantSafetyState
  // ---------------------------------------------------------------------------

  group('UspInstantSafetyState', () {
    test('isDirty false when pendingType matches uiModel type', () {
      const state = UspInstantSafetyState(
        uiModel: SafeBrowsingUIModel(type: SafeBrowsingType.off),
        pendingType: SafeBrowsingType.off,
      );
      expect(state.isDirty, isFalse);
    });

    test('isDirty true when pendingType differs from uiModel type', () {
      const state = UspInstantSafetyState(
        uiModel: SafeBrowsingUIModel(type: SafeBrowsingType.off),
        pendingType: SafeBrowsingType.openDNS,
      );
      expect(state.isDirty, isTrue);
    });

    test('isEnabled true when pendingType is openDNS', () {
      const state = UspInstantSafetyState(
        uiModel: SafeBrowsingUIModel(type: SafeBrowsingType.off),
        pendingType: SafeBrowsingType.openDNS,
      );
      expect(state.isEnabled, isTrue);
    });

    test('isEnabled false when pendingType is off', () {
      const state = UspInstantSafetyState(
        uiModel: SafeBrowsingUIModel(type: SafeBrowsingType.openDNS),
        pendingType: SafeBrowsingType.off,
      );
      expect(state.isEnabled, isFalse);
    });

    test('copyWith updates specified fields only', () {
      const state = UspInstantSafetyState(
        uiModel: SafeBrowsingUIModel(type: SafeBrowsingType.off),
        pendingType: SafeBrowsingType.off,
      );
      final updated = state.copyWith(
        pendingType: SafeBrowsingType.openDNS,
        isSaving: true,
      );

      expect(updated.pendingType, SafeBrowsingType.openDNS);
      expect(updated.isSaving, isTrue);
      expect(updated.uiModel.type, SafeBrowsingType.off);
    });
  });

  // ---------------------------------------------------------------------------
  // UspInstantSafetyNotifier
  // ---------------------------------------------------------------------------

  group('UspInstantSafetyNotifier', () {
    // -----------------------------------------------------------------------
    // build
    // -----------------------------------------------------------------------

    test('build fetches and initializes state with matching pendingType',
        () async {
      when(() => mockService.fetch()).thenAnswer((_) async =>
          const SafeBrowsingUIModel(
              type: SafeBrowsingType.openDNS,
              currentDnsServers: '208.67.222.222,208.67.220.220'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspInstantSafetyProvider);
      expect(state.hasValue, isTrue);
      expect(state.requireValue.uiModel.type, SafeBrowsingType.openDNS);
      expect(state.requireValue.pendingType, SafeBrowsingType.openDNS);
      expect(state.requireValue.isDirty, isFalse);
      container.dispose();
    });

    test('build sets error state when service throws', () async {
      when(() => mockService.fetch()).thenThrow(Exception('network error'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspInstantSafetyProvider);
      expect(state.hasError, isTrue);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // setEnabled
    // -----------------------------------------------------------------------

    test('setEnabled(true) sets pendingType to openDNS', () async {
      when(() => mockService.fetch()).thenAnswer(
          (_) async => const SafeBrowsingUIModel(type: SafeBrowsingType.off));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      container.read(uspInstantSafetyProvider.notifier).setEnabled(true);

      final state = container.read(uspInstantSafetyProvider).requireValue;
      expect(state.pendingType, SafeBrowsingType.openDNS);
      expect(state.isDirty, isTrue);
      container.dispose();
    });

    test('setEnabled(false) sets pendingType to off', () async {
      when(() => mockService.fetch()).thenAnswer((_) async =>
          const SafeBrowsingUIModel(type: SafeBrowsingType.openDNS));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      container.read(uspInstantSafetyProvider.notifier).setEnabled(false);

      final state = container.read(uspInstantSafetyProvider).requireValue;
      expect(state.pendingType, SafeBrowsingType.off);
      expect(state.isDirty, isTrue);
      container.dispose();
    });

    test('setEnabled does nothing when state is loading', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => Future.delayed(
            const Duration(seconds: 10),
            () => const SafeBrowsingUIModel(type: SafeBrowsingType.off),
          ));

      final container = createContainer();
      // Don't await — state is still loading
      container.read(uspInstantSafetyProvider.notifier).setEnabled(true);

      // Should not crash or change state
      final state = container.read(uspInstantSafetyProvider);
      expect(state.hasValue, isFalse);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // save
    // -----------------------------------------------------------------------

    test('save calls service with pendingType', () async {
      when(() => mockService.fetch()).thenAnswer(
          (_) async => const SafeBrowsingUIModel(type: SafeBrowsingType.off));
      when(() => mockService.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInstantSafetyProvider.notifier);
      notifier.setEnabled(true);
      await notifier.save();

      verify(() => mockService.save(SafeBrowsingType.openDNS)).called(1);
      container.dispose();
    });

    test('save skips when not dirty', () async {
      when(() => mockService.fetch()).thenAnswer(
          (_) async => const SafeBrowsingUIModel(type: SafeBrowsingType.off));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      await container.read(uspInstantSafetyProvider.notifier).save();

      verifyNever(() => mockService.save(any()));
      container.dispose();
    });

    test('save resets isSaving on error', () async {
      when(() => mockService.fetch()).thenAnswer(
          (_) async => const SafeBrowsingUIModel(type: SafeBrowsingType.off));
      when(() => mockService.save(any())).thenThrow(Exception('save failed'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInstantSafetyProvider.notifier);
      notifier.setEnabled(true);

      expect(
        () => notifier.save(),
        throwsA(isA<Exception>()),
      );

      await Future.delayed(Duration.zero);
      final state = container.read(uspInstantSafetyProvider).requireValue;
      expect(state.isSaving, isFalse);
      container.dispose();
    });
  });
}
