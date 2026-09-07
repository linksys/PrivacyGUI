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
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/local_network/services/usp_lan_data_service.dart';

class MockInstantSafetyService extends Mock
    implements UspInstantSafetyService {}

class MockLanDataService extends Mock implements UspLanDataService {}

const _fetchError = NetworkError(detail: 'fetch failed');
const _saveError = NetworkError(detail: 'save failed');

void main() {
  late MockInstantSafetyService mockService;
  late MockLanDataService mockLanService;

  setUpAll(() {
    registerFallbackValue(SafeBrowsingType.off);
  });

  setUp(() {
    mockService = MockInstantSafetyService();
    mockLanService = MockLanDataService();
    when(() => mockLanService.fetch()).thenAnswer((_) async =>
        const LanInfoUIModel(
            ipAddress: '192.168.1.1',
            subnetMask: '255.255.255.0',
            dhcpEnabled: true,
            minAddress: '192.168.1.20',
            maxAddress: '192.168.1.200'));
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspInstantSafetyServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        // save() invalidates lanDataProvider, which builds it and reaches
        // uspLanDataServiceProvider — no lanDataProvider listener needed. Today
        // that fails safe (the real provider throws ServiceNotInitializedError
        // because uspClientProvider is null in tests, and the throw is captured
        // as an AsyncValue error), but the moment a test here overrides
        // uspClientProvider it would silently hit the real service instead.
        uspLanDataServiceProvider.overrideWithValue(mockLanService),
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
  // InstantSafetyStatus
  // ---------------------------------------------------------------------------

  group('InstantSafetyStatus', () {
    test('isLoading defaults to false so an omitted flag fails safe', () {
      // The view checks isLoading before error, so a default of true would turn
      // any status that carries an error into an endless loader (#1274).
      const status = InstantSafetyStatus(error: _fetchError);
      expect(status.isLoading, isFalse);
      expect(status.error, _fetchError);
    });

    test('copyWith(clearError: true) drops the error', () {
      const status = InstantSafetyStatus(error: _fetchError);
      expect(status.copyWith(clearError: true).error, isNull);
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
      await pumpEventQueue();

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
      await pumpEventQueue();

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
      await pumpEventQueue();

      container.read(uspInstantSafetyProvider.notifier).setEnabled(false);

      final state = container.read(uspInstantSafetyProvider);
      expect(state.settings.current.type, SafeBrowsingType.off);
      expect(state.isDirty, isTrue);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // fetch — error path (#1274)
    //
    // Two conventions hold for every async test in this file:
    //
    // 1. pumpEventQueue(), never Future.delayed(Duration.zero). A single
    //    Duration.zero only flushes build()'s Future.microtask, so it happens
    //    to work with a synchronous thenThrow and silently stops working the
    //    moment the mock gains an async hop — the assertions then run against
    //    the initial isLoading == true state and still pass. Failures are
    //    stubbed as thenAnswer((_) async => throw ...) for the same reason:
    //    the real service always throws across an await.
    //
    // 2. Let build()'s boot microtask be the only fetch. Calling fetch()
    //    explicitly on top of it races: the later completion overwrites
    //    settings and would clobber a pending edit mid-test.
    // -----------------------------------------------------------------------

    test('fetch failure surfaces the error on status', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => throw _fetchError);

      final container = createContainer();
      await pumpEventQueue();

      final state = container.read(uspInstantSafetyProvider);
      expect(state.status.error, _fetchError);
      container.dispose();
    });

    test('fetch failure clears isLoading so the error view is reachable',
        () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => throw _fetchError);

      final container = createContainer();
      await pumpEventQueue();

      // The view checks isLoading before error; leaving it true hangs the page
      // on its loader and the Retry button never renders.
      final state = container.read(uspInstantSafetyProvider);
      expect(state.status.isLoading, isFalse);
      container.dispose();
    });

    test('fetch failure leaves settings untouched and clean', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => throw _fetchError);

      final container = createContainer();
      await pumpEventQueue();

      final state = container.read(uspInstantSafetyProvider);
      expect(state.settings.current, InstantSafetySettings.empty());
      expect(state.isDirty, isFalse);
      container.dispose();
    });

    test('fetch failure preserves unsaved edits', () async {
      when(() => mockService.fetch()).thenAnswer(
          (_) async => const SafeBrowsingUIModel(type: SafeBrowsingType.off));

      final container = createContainer();
      await pumpEventQueue();
      final notifier = container.read(uspInstantSafetyProvider.notifier);
      notifier.setEnabled(true);

      when(() => mockService.fetch())
          .thenAnswer((_) async => throw _fetchError);
      await notifier.fetch(forceRemote: true);

      // performFetch returns null settings on failure, so the mixin takes the
      // status-only branch and the pending edit survives.
      final state = container.read(uspInstantSafetyProvider);
      expect(state.settings.current.type, SafeBrowsingType.openDNS);
      expect(state.isDirty, isTrue);
      container.dispose();
    });

    test('non-ServiceError is wrapped rather than left uncaught', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => throw StateError('client was null'));

      final container = createContainer();
      await pumpEventQueue();

      final state = container.read(uspInstantSafetyProvider);
      expect(state.status.error, isA<UnexpectedError>());
      expect(state.status.isLoading, isFalse);
      container.dispose();
    });

    test('successful retry clears a prior error', () async {
      when(() => mockService.fetch())
          .thenAnswer((_) async => throw _fetchError);

      final container = createContainer();
      await pumpEventQueue();
      final notifier = container.read(uspInstantSafetyProvider.notifier);
      expect(container.read(uspInstantSafetyProvider).status.error, isNotNull);

      when(() => mockService.fetch()).thenAnswer((_) async =>
          const SafeBrowsingUIModel(type: SafeBrowsingType.openDNS));
      await notifier.fetch(forceRemote: true);

      final state = container.read(uspInstantSafetyProvider);
      expect(state.status.error, isNull);
      expect(state.settings.current.type, SafeBrowsingType.openDNS);
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
      await pumpEventQueue();

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
      await pumpEventQueue();

      await container.read(uspInstantSafetyProvider.notifier).save();

      verifyNever(() => mockService.save(any()));
      container.dispose();
    });

    test('save reports a failed post-save re-fetch without a full-page error',
        () async {
      var calls = 0;
      when(() => mockService.fetch()).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          return const SafeBrowsingUIModel(type: SafeBrowsingType.off);
        }
        throw _fetchError;
      });
      when(() => mockService.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      await pumpEventQueue();
      final notifier = container.read(uspInstantSafetyProvider.notifier);
      notifier.setEnabled(true);

      // The SET succeeded and only the re-fetch failed. The caller must hear
      // about it (snackbar) — silently returning would pair a success toast
      // with a full-page ServiceErrorView.
      await expectLater(notifier.save(), throwsA(same(_fetchError)));

      // ...and status.error must stay clear, or the page turns into an error
      // view for a write that actually landed.
      final state = container.read(uspInstantSafetyProvider);
      expect(state.status.error, isNull);
      expect(state.status.isSaving, isFalse);
      container.dispose();
    });

    test('save invalidates L1 LAN data even when the re-fetch fails', () async {
      // The mixin runs performSave() + markAsSaved() before its post-save
      // re-fetch, so once save() returns the SET has landed and L1 holds a
      // stale applied value regardless of how the confirming read went.
      // Skipping the invalidate here would strand the menu badge on the old
      // value: markAsSaved() has cleaned the state, so save()'s isDirty()
      // guard makes the user's retry a silent no-op.
      var fetchCalls = 0;
      when(() => mockService.fetch()).thenAnswer((_) async {
        fetchCalls++;
        if (fetchCalls == 1) {
          return const SafeBrowsingUIModel(type: SafeBrowsingType.off);
        }
        throw _fetchError;
      });
      when(() => mockService.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      // The invalidate is observed through the L1 service: LanDataNotifier
      // calls fetch() on every build, so a rebuild shows up as a second call.
      // The listener keeps lanDataProvider alive between the two verifies —
      // without it the autoDispose provider is torn down after each read and
      // the counts stop meaning "was it invalidated".
      container.listen(lanDataProvider, (_, __) {});

      await pumpEventQueue();
      verify(() => mockLanService.fetch()).called(1);

      final notifier = container.read(uspInstantSafetyProvider.notifier);
      notifier.setEnabled(true);
      await expectLater(notifier.save(), throwsA(same(_fetchError)));
      await pumpEventQueue();

      verify(() => mockLanService.fetch()).called(1);
      container.dispose();
    });

    test('save resets isSaving on error', () async {
      when(() => mockService.fetch()).thenAnswer(
          (_) async => const SafeBrowsingUIModel(type: SafeBrowsingType.off));
      when(() => mockService.save(any()))
          .thenAnswer((_) async => throw _saveError);

      final container = createContainer();
      await pumpEventQueue();

      final notifier = container.read(uspInstantSafetyProvider.notifier);
      notifier.setEnabled(true);

      // expectLater, not the unawaited expect(() => ...) form: this must be
      // sequenced before the isSaving read so the assertion sees the state the
      // finally block left, not the one before save() ran.
      await expectLater(notifier.save(), throwsA(same(_saveError)));

      final state = container.read(uspInstantSafetyProvider);
      expect(state.status.isSaving, isFalse);
      container.dispose();
    });
  });
}
