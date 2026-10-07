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

void main() {
  late MockUspAdministrationService svc;

  setUp(() {
    svc = MockUspAdministrationService();
  });

  /// [reads] are the successive values each `fetch()` returns: the page-entry
  /// read first, then whatever a save re-reads.
  Future<ProviderContainer> load(List<bool> reads) async {
    final queue = [...reads];
    when(() => svc.fetch()).thenAnswer((_) async => AdministrationSettings(
        upnpEnabled: queue.length > 1 ? queue.removeAt(0) : queue.first));
    final container = ProviderContainer(overrides: [
      uspAdministrationServiceProvider.overrideWithValue(svc),
      uspMutationLockProvider.overrideWithValue(UspMutationLock()),
    ]);
    addTearDown(container.dispose);
    container.listen(uspAdministrationProvider, (_, __) {});
    await Future.delayed(Duration.zero);
    return container;
  }

  group('UspAdministrationNotifier - fetch', () {
    test('starts loading, then shows the device value', () async {
      when(() => svc.fetch()).thenAnswer(
          (_) async => const AdministrationSettings(upnpEnabled: true));
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

    test('a failure whose re-read also fails keeps the edit pending', () async {
      when(() => svc.setUpnpEnabled(any()))
          .thenThrow(const NetworkError(detail: 'unreachable'));
      var reads = 0;
      when(() => svc.fetch()).thenAnswer((_) async {
        if (reads++ == 0) {
          return const AdministrationSettings(upnpEnabled: true);
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
