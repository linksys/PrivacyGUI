import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_feature_state.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_settings.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_status.dart';
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
  // InstantSafetySettings
  // ---------------------------------------------------------------------------

  group('InstantSafetySettings', () {
    test('isEnabled true when type is openDNS', () {
      const settings = InstantSafetySettings(type: SafeBrowsingType.openDNS);
      expect(settings.isEnabled, isTrue);
    });

    test('isEnabled false when type is off', () {
      const settings = InstantSafetySettings(type: SafeBrowsingType.off);
      expect(settings.isEnabled, isFalse);
    });

    test('copyWith updates type', () {
      const settings = InstantSafetySettings(type: SafeBrowsingType.off);
      final updated = settings.copyWith(type: SafeBrowsingType.openDNS);
      expect(updated.type, SafeBrowsingType.openDNS);
    });
  });

  // ---------------------------------------------------------------------------
  // InstantSafetyFeatureState
  // ---------------------------------------------------------------------------

  group('InstantSafetyFeatureState', () {
    test('isDirty false when current matches original', () {
      final state = InstantSafetyFeatureState(
        settings: Preservable(
          original: const InstantSafetySettings(type: SafeBrowsingType.off),
          current: const InstantSafetySettings(type: SafeBrowsingType.off),
        ),
        status: const InstantSafetyStatus(isLoading: false),
      );
      expect(state.isDirty, isFalse);
    });

    test('isDirty true when current differs from original', () {
      final state = InstantSafetyFeatureState(
        settings: Preservable(
          original: const InstantSafetySettings(type: SafeBrowsingType.off),
          current: const InstantSafetySettings(type: SafeBrowsingType.openDNS),
        ),
        status: const InstantSafetyStatus(isLoading: false),
      );
      expect(state.isDirty, isTrue);
    });

    test('initial factory creates loading state', () {
      final state = InstantSafetyFeatureState.initial();
      expect(state.status.isLoading, isTrue);
      expect(state.isDirty, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // UspInstantSafetyNotifier
  // ---------------------------------------------------------------------------

  group('UspInstantSafetyNotifier', () {
    // -----------------------------------------------------------------------
    // build
    // -----------------------------------------------------------------------

    test('build fetches and initializes state', () async {
      when(() => mockService.fetch()).thenAnswer((_) async =>
          const SafeBrowsingUIModel(
              type: SafeBrowsingType.openDNS,
              currentDnsServers: '208.67.222.222,208.67.220.220'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspInstantSafetyProvider);
      expect(state.status.isLoading, isFalse);
      expect(state.settings.current.type, SafeBrowsingType.openDNS);
      expect(state.isDirty, isFalse);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // setEnabled
    // -----------------------------------------------------------------------

    test('setEnabled(true) sets current type to openDNS', () async {
      when(() => mockService.fetch()).thenAnswer(
          (_) async => const SafeBrowsingUIModel(type: SafeBrowsingType.off));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      container.read(uspInstantSafetyProvider.notifier).setEnabled(true);

      final state = container.read(uspInstantSafetyProvider);
      expect(state.settings.current.type, SafeBrowsingType.openDNS);
      expect(state.isDirty, isTrue);
      container.dispose();
    });

    test('setEnabled(false) sets current type to off', () async {
      when(() => mockService.fetch()).thenAnswer((_) async =>
          const SafeBrowsingUIModel(type: SafeBrowsingType.openDNS));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      container.read(uspInstantSafetyProvider.notifier).setEnabled(false);

      final state = container.read(uspInstantSafetyProvider);
      expect(state.settings.current.type, SafeBrowsingType.off);
      expect(state.isDirty, isTrue);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // save
    // -----------------------------------------------------------------------

    test('save calls service with current type', () async {
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
      when(() => mockService.save(any()))
          .thenThrow(const NetworkError(detail: 'save failed'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInstantSafetyProvider.notifier);
      notifier.setEnabled(true);

      expect(
        () => notifier.save(),
        throwsA(isA<ServiceError>()),
      );

      await Future.delayed(Duration.zero);
      final state = container.read(uspInstantSafetyProvider);
      expect(state.status.isSaving, isFalse);
      container.dispose();
    });
  });
}
