import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/administration/models/administration_settings.dart';
import 'package:privacy_gui/page/administration/providers/usp_administration_notifier.dart';
import 'package:privacy_gui/page/administration/services/usp_administration_service.dart';

class MockUspAdministrationService extends Mock
    implements UspAdministrationService {}

AdministrationSettings _settings({
  bool upnp = true,
  bool sip = false,
  bool? mgmt = true,
}) =>
    AdministrationSettings(
        upnpEnabled: upnp, sipAlgEnabled: sip, mgmtWifiEnabled: mgmt);

void main() {
  late MockUspAdministrationService svc;

  setUp(() {
    svc = MockUspAdministrationService();
  });

  /// [load] over whole settings, for the cases that edit more than UPnP.
  Future<ProviderContainer> loadSettings(
      List<AdministrationSettings> reads) async {
    final queue = [...reads];
    when(() => svc.fetch()).thenAnswer(
        (_) async => queue.length > 1 ? queue.removeAt(0) : queue.first);
    final container = ProviderContainer(overrides: [
      uspAdministrationServiceProvider.overrideWithValue(svc),
      uspMutationLockProvider.overrideWithValue(UspMutationLock()),
    ]);
    addTearDown(container.dispose);
    container.listen(uspAdministrationProvider, (_, __) {});
    await Future.delayed(Duration.zero);
    return container;
  }

  /// [reads] are the successive UPnP values each `fetch()` returns: the
  /// page-entry read first, then whatever a save re-reads. SIP ALG reads off.
  Future<ProviderContainer> load(List<bool> reads) =>
      loadSettings([for (final upnp in reads) _settings(upnp: upnp)]);

  group('UspAdministrationNotifier - fetch', () {
    test('starts loading, then shows the device value', () async {
      when(() => svc.fetch()).thenAnswer((_) async => _settings(upnp: true));
      final container = ProviderContainer(overrides: [
        uspAdministrationServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);
      container.listen(uspAdministrationProvider, (_, __) {});

      expect(
          container.read(uspAdministrationProvider).status.isLoading, isTrue);
      await Future.delayed(Duration.zero);

      final state = container.read(uspAdministrationProvider);
      expect(state.status.isLoading, isFalse);
      expect(state.settings.current.upnpEnabled, isTrue);
      expect(state.isDirty, isFalse);
      verify(() => svc.fetch()).called(1);
    });

    test('a failed read lands on status.error', () async {
      when(() => svc.fetch()).thenThrow(const NetworkError(detail: 'timeout'));
      final container = ProviderContainer(overrides: [
        uspAdministrationServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);
      container.listen(uspAdministrationProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      final state = container.read(uspAdministrationProvider);
      expect(state.status.error, isA<NetworkError>());
      expect(state.status.isLoading, isFalse);
    });
  });

  group('UspAdministrationNotifier - setUpnpEnabled', () {
    test('buffers the change and writes nothing', () async {
      final container = await load([true]);

      container.read(uspAdministrationProvider.notifier).setUpnpEnabled(false);

      final state = container.read(uspAdministrationProvider);
      expect(state.settings.current.upnpEnabled, isFalse);
      expect(state.isDirty, isTrue);
      verifyNever(() => svc.setUpnpEnabled(any()));
    });

    test('flipping back clears dirty', () async {
      final container = await load([true]);
      final notifier = container.read(uspAdministrationProvider.notifier);

      notifier.setUpnpEnabled(false);
      notifier.setUpnpEnabled(true);

      expect(container.read(uspAdministrationProvider).isDirty, isFalse);
    });

    test('revert restores the device value', () async {
      final container = await load([true]);
      final notifier = container.read(uspAdministrationProvider.notifier);

      notifier.setUpnpEnabled(false);
      notifier.revert();

      final state = container.read(uspAdministrationProvider);
      expect(state.settings.current.upnpEnabled, isTrue);
      expect(state.isDirty, isFalse);
    });
  });

  group('UspAdministrationNotifier - setSipAlgEnabled', () {
    test('buffers the change and writes nothing', () async {
      final container = await load([true]);

      container.read(uspAdministrationProvider.notifier).setSipAlgEnabled(true);

      final state = container.read(uspAdministrationProvider);
      expect(state.settings.current.sipAlgEnabled, isTrue);
      expect(state.isDirty, isTrue);
      verifyNever(() => svc.setSipAlgEnabled(any()));
    });
  });

  group('UspAdministrationNotifier - setMgmtWifiEnabled', () {
    test('buffers the change and writes nothing', () async {
      final container = await load([true]);

      container
          .read(uspAdministrationProvider.notifier)
          .setMgmtWifiEnabled(false);

      final state = container.read(uspAdministrationProvider);
      expect(state.settings.current.mgmtWifiEnabled, isFalse);
      expect(state.isDirty, isTrue);
      verifyNever(() => svc.setMgmtWifiEnabled(any()));
    });
  });

  group('UspAdministrationNotifier - save', () {
    test('sends one Set of the new value, then re-reads the device', () async {
      when(() => svc.setUpnpEnabled(any())).thenAnswer((_) async {});
      final container = await load([true, false]);
      final notifier = container.read(uspAdministrationProvider.notifier);

      notifier.setUpnpEnabled(false);
      await notifier.save();

      verify(() => svc.setUpnpEnabled(false)).called(1);
      verify(() => svc.fetch()).called(2);
      final state = container.read(uspAdministrationProvider);
      expect(state.settings.current.upnpEnabled, isFalse);
      expect(state.isDirty, isFalse);
      expect(state.status.isSaving, isFalse);
    });

    test('isSaving is true while the Set is in flight', () async {
      final saving = <bool>[];
      final container = await load([true, false]);
      when(() => svc.setUpnpEnabled(any())).thenAnswer((_) async {
        saving.add(container.read(uspAdministrationProvider).status.isSaving);
      });
      final notifier = container.read(uspAdministrationProvider.notifier);

      notifier.setUpnpEnabled(false);
      await notifier.save();

      expect(saving, [isTrue]);
      expect(
          container.read(uspAdministrationProvider).status.isSaving, isFalse);
    });

    test('a refused Set rethrows and leaves the switch at the device value',
        () async {
      when(() => svc.setUpnpEnabled(any()))
          .thenThrow(const UnexpectedError(detail: 'refused (9007)'));
      // The re-read after the failure still says on.
      final container = await load([true, true]);
      final notifier = container.read(uspAdministrationProvider.notifier);

      notifier.setUpnpEnabled(false);
      await expectLater(notifier.save(), throwsA(isA<UnexpectedError>()));

      final state = container.read(uspAdministrationProvider);
      expect(state.settings.current.upnpEnabled, isTrue,
          reason: 'the switch shows what the router holds, not the refused '
              'value');
      expect(state.isDirty, isFalse,
          reason: 'nothing is left pending, so leaving the page asks nothing');
      expect(state.status.isSaving, isFalse);
      verify(() => svc.fetch()).called(2);
    });

    test('an unchanged switch is not written', () async {
      // UPnP and SIP ALG are owned by different USP services, and SIP ALG's
      // Set alone takes ~9 s. Rewriting the one the user did not touch would
      // add that wait to every UPnP save.
      when(() => svc.setSipAlgEnabled(any())).thenAnswer((_) async {});
      final container = await loadSettings([
        _settings(upnp: true, sip: false),
        _settings(upnp: true, sip: true),
      ]);
      final notifier = container.read(uspAdministrationProvider.notifier);

      notifier.setSipAlgEnabled(true);
      await notifier.save();

      verify(() => svc.setSipAlgEnabled(true)).called(1);
      verifyNever(() => svc.setUpnpEnabled(any()));
      expect(container.read(uspAdministrationProvider).settings.current,
          _settings(upnp: true, sip: true));
    });

    test('with both switches changed, one Save writes both, under one lock',
        () async {
      final calls = <String>[];
      when(() => svc.setUpnpEnabled(any())).thenAnswer((_) async {
        calls.add('upnp');
      });
      when(() => svc.setSipAlgEnabled(any())).thenAnswer((_) async {
        calls.add('sip');
      });
      final lock = _CountingLock();
      when(() => svc.fetch()).thenAnswer((_) async => _settings());
      final container = ProviderContainer(overrides: [
        uspAdministrationServiceProvider.overrideWithValue(svc),
        uspMutationLockProvider.overrideWithValue(lock),
      ]);
      addTearDown(container.dispose);
      container.listen(uspAdministrationProvider, (_, __) {});
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspAdministrationProvider.notifier);

      notifier.setUpnpEnabled(false);
      notifier.setSipAlgEnabled(true);
      await notifier.save();

      verify(() => svc.setUpnpEnabled(false)).called(1);
      verify(() => svc.setSipAlgEnabled(true)).called(1);
      expect(calls, hasLength(2));
      expect(lock.entries, 1,
          reason: 'one window for the page, so no other write slips between');
    });

    test('a refused SIP ALG Set reports its error after UPnP was written',
        () async {
      // Both are sent; the device's values are re-read so the page shows what
      // landed (UPnP) and what did not (SIP ALG).
      when(() => svc.setUpnpEnabled(any())).thenAnswer((_) async {});
      when(() => svc.setSipAlgEnabled(any()))
          .thenThrow(const UnexpectedError(detail: 'refused (9007)'));
      final container = await loadSettings([
        _settings(upnp: true, sip: false),
        _settings(upnp: false, sip: false),
      ]);
      final notifier = container.read(uspAdministrationProvider.notifier);

      notifier.setUpnpEnabled(false);
      notifier.setSipAlgEnabled(true);
      await expectLater(notifier.save(), throwsA(isA<UnexpectedError>()));

      final state = container.read(uspAdministrationProvider);
      expect(state.settings.current, _settings(upnp: false, sip: false));
      expect(state.isDirty, isFalse);
    });

    test('a management change is written alone', () async {
      when(() => svc.setMgmtWifiEnabled(any())).thenAnswer((_) async {});
      final container = await loadSettings([
        _settings(mgmt: true),
        _settings(mgmt: false),
      ]);
      final notifier = container.read(uspAdministrationProvider.notifier);

      notifier.setMgmtWifiEnabled(false);
      await notifier.save();

      verify(() => svc.setMgmtWifiEnabled(false)).called(1);
      verifyNever(() => svc.setUpnpEnabled(any()));
      verifyNever(() => svc.setSipAlgEnabled(any()));
      expect(container.read(uspAdministrationProvider).isDirty, isFalse);
    });

    test('a firmware without the rule never writes it', () async {
      // The switch is hidden there, so nothing can change it; editing the
      // other switches must not reach for a rule that is not on the router.
      when(() => svc.setUpnpEnabled(any())).thenAnswer((_) async {});
      final container = await loadSettings([
        _settings(upnp: true, mgmt: null),
        _settings(upnp: false, mgmt: null),
      ]);
      final notifier = container.read(uspAdministrationProvider.notifier);

      notifier.setUpnpEnabled(false);
      await notifier.save();

      verify(() => svc.setUpnpEnabled(false)).called(1);
      verifyNever(() => svc.setMgmtWifiEnabled(any()));
    });

    test('a Set that outlasts the lock is a TimeoutError and is re-read',
        () async {
      // The lock throws a bare TimeoutException at its window. Left as one it
      // skipped the re-read (only ServiceError was caught) and reached the view
      // as an unexpected error, with the switch still showing the unsent value.
      // A hung write is the case where nobody knows what the router holds,
      // which is what the re-read is for.
      when(() => svc.setUpnpEnabled(any())).thenAnswer((_) async {});
      var reads = 0;
      when(() => svc.fetch()).thenAnswer((_) async {
        reads++;
        return _settings(upnp: true);
      });
      final container = ProviderContainer(overrides: [
        uspAdministrationServiceProvider.overrideWithValue(svc),
        // What the real lock throws at its 30 s window, without waiting 30 s.
        uspMutationLockProvider.overrideWithValue(_TimingOutLock()),
      ]);
      addTearDown(container.dispose);
      container.listen(uspAdministrationProvider, (_, __) {});
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspAdministrationProvider.notifier);

      notifier.setUpnpEnabled(false);
      await expectLater(notifier.save(), throwsA(isA<TimeoutError>()));

      final state = container.read(uspAdministrationProvider);
      expect(state.settings.current.upnpEnabled, isTrue);
      expect(state.isDirty, isFalse);
      expect(reads, 2, reason: 'on entry, and to settle the hung write');
    });

    test('a failure whose re-read also fails keeps the edit pending', () async {
      when(() => svc.setUpnpEnabled(any()))
          .thenThrow(const NetworkError(detail: 'unreachable'));
      var reads = 0;
      when(() => svc.fetch()).thenAnswer((_) async {
        if (reads++ == 0) {
          return _settings(upnp: true);
        }
        throw const NetworkError(detail: 'unreachable');
      });
      final container = ProviderContainer(overrides: [
        uspAdministrationServiceProvider.overrideWithValue(svc),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ]);
      addTearDown(container.dispose);
      container.listen(uspAdministrationProvider, (_, __) {});
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspAdministrationProvider.notifier);

      notifier.setUpnpEnabled(false);
      await expectLater(notifier.save(), throwsA(isA<NetworkError>()),
          reason: "the Set's error is the one reported, not the re-read's");

      final state = container.read(uspAdministrationProvider);
      expect(state.settings.current.upnpEnabled, isFalse);
      expect(state.isDirty, isTrue,
          reason: 'nobody knows what the router holds, so the edit is kept '
              'and Save can be tried again');
    });
  });
}

/// A lock whose action never finishes inside its window: throws what
/// [UspMutationLock.withLock] throws when the window closes, at once.
class _TimingOutLock extends UspMutationLock {
  @override
  Future<T> withLock<T>(Future<T> Function() action,
          {Duration timeout = UspMutationLock.defaultTimeout}) =>
      Future.error(TimeoutException(
          'USP mutation timed out after ${timeout.inSeconds}s', timeout));
}

/// A real lock that counts how many times it is entered.
class _CountingLock extends UspMutationLock {
  int entries = 0;

  @override
  Future<T> withLock<T>(Future<T> Function() action,
      {Duration timeout = UspMutationLock.defaultTimeout}) {
    entries++;
    return super.withLock(action, timeout: timeout);
  }
}
