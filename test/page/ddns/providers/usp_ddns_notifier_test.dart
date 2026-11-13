import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/ddns/models/ddns_rules.dart';
import 'package:privacy_gui/page/ddns/models/ddns_settings.dart';
import 'package:privacy_gui/page/ddns/models/ddns_status.dart';
import 'package:privacy_gui/page/ddns/models/ddns_update_status.dart';
import 'package:privacy_gui/page/ddns/providers/ddns_status_data_provider.dart';
import 'package:privacy_gui/page/ddns/providers/usp_ddns_notifier.dart';
import 'package:privacy_gui/page/ddns/services/usp_ddns_service.dart';
import 'package:privacy_gui/page/ddns/services/usp_ddns_status_data_service.dart';

import '../../../mocks/test_data/ddns_test_data.dart';

class MockUspDdnsService extends Mock implements UspDdnsService {}

class MockUspDdnsStatusDataService extends Mock
    implements UspDdnsStatusDataService {}

void main() {
  late MockUspDdnsService service;
  late MockUspDdnsStatusDataService statusService;
  late UspMutationLock lock;

  const loaded = DdnsStatus(isLoading: false);

  setUpAll(() {
    registerFallbackValue(DdnsTestData.settings());
  });

  setUp(() {
    service = MockUspDdnsService();
    statusService = MockUspDdnsStatusDataService();
    lock = UspMutationLock();
    when(() => service.fetch())
        .thenAnswer((_) async => (DdnsTestData.settings(), loaded));
    when(() => service.save(any())).thenAnswer((_) async {});
    when(() => statusService.fetch(fresh: any(named: 'fresh')))
        .thenAnswer((_) async => DdnsUpdateStatus.disabled);
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(overrides: [
      uspDdnsServiceProvider.overrideWithValue(service),
      uspDdnsStatusDataServiceProvider.overrideWithValue(statusService),
      uspMutationLockProvider.overrideWithValue(lock),
    ]);
    // Keep the autoDispose page provider alive, and watch the status as the
    // page does.
    container.listen(uspDdnsProvider, (_, __) {});
    container.listen(ddnsStatusDataProvider, (_, __) {});
    addTearDown(container.dispose);
    return container;
  }

  /// Lets the build's microtask fetch, and the status read it triggers, run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('UspDdnsNotifier - fetch', () {
    test('starts loading, then holds what the router has', () async {
      when(() => service.fetch())
          .thenAnswer((_) async => (DdnsTestData.configuredSettings(), loaded));
      final container = createContainer();

      expect(container.read(uspDdnsProvider).status.isLoading, isTrue);
      await settle();

      final state = container.read(uspDdnsProvider);
      expect(state.status.isLoading, isFalse);
      expect(state.settings.current, DdnsTestData.configuredSettings());
      expect(state.isDirty, isFalse);
    });

    test('a failed read shows its error and keeps the empty settings',
        () async {
      when(() => service.fetch())
          .thenThrow(const NetworkError(detail: 'read failed'));
      final container = createContainer();
      await settle();

      final state = container.read(uspDdnsProvider);
      expect(state.status.error, isA<NetworkError>());
      expect(state.settings.current, const DdnsSettings.empty());
    });

    test('a read of the settings re-reads the status with them', () async {
      final container = createContainer();
      await settle();
      clearInteractions(statusService);

      await container.read(uspDdnsProvider.notifier).fetch(forceRemote: true);
      await settle();

      verify(() => statusService.fetch(fresh: any(named: 'fresh'))).called(1);
    });
  });

  group('UspDdnsNotifier - edits', () {
    test('choosing a provider makes the page dirty', () async {
      final container = createContainer();
      await settle();

      container
          .read(uspDdnsProvider.notifier)
          .selectProvider(DdnsTestData.dynDnsPath);

      final state = container.read(uspDdnsProvider);
      expect(state.settings.current.providerPath, DdnsTestData.dynDnsPath);
      expect(state.isDirty, isTrue);
    });

    test(
        'choosing a provider raises no field error before a field loses '
        'focus', () async {
      final container = createContainer();
      await settle();

      container
          .read(uspDdnsProvider.notifier)
          .selectProvider(DdnsTestData.noIpPath);

      expect(container.read(uspDdnsProvider).status.fieldErrors, isEmpty);
    });

    test('choosing "Disabled" clears the field errors on screen', () async {
      final container = createContainer();
      await settle();
      final notifier = container.read(uspDdnsProvider.notifier)
        ..selectProvider(DdnsTestData.noIpPath)
        ..validate();
      expect(container.read(uspDdnsProvider).status.fieldErrors, isNotEmpty);

      notifier.selectProvider(null);

      expect(container.read(uspDdnsProvider).status.fieldErrors, isEmpty);
    });

    test('typing does not check the field; losing focus does', () async {
      final container = createContainer();
      await settle();
      final notifier = container.read(uspDdnsProvider.notifier)
        ..selectProvider(DdnsTestData.noIpPath)
        ..updateSetting((s) => s.copyWith(
              username: 'user',
              password: 'secret',
              hostname: 'bad_name',
            ));
      expect(container.read(uspDdnsProvider).status.fieldErrors, isEmpty);

      notifier.validate();

      expect(container.read(uspDdnsProvider).status.fieldErrors,
          {DdnsField.hostname});
    });

    test('revert puts back what the router has', () async {
      final container = createContainer();
      await settle();
      final notifier = container.read(uspDdnsProvider.notifier)
        ..selectProvider(DdnsTestData.noIpPath);

      notifier.revert();

      final state = container.read(uspDdnsProvider);
      expect(state.isDirty, isFalse);
      expect(state.settings.current.providerPath, isNull);
    });
  });

  group('UspDdnsNotifier - field checks', () {
    test('a field that loses focus shows only its own error', () async {
      // Fresh router: type a user name and move on. The password and host
      // name are still empty, and the user has not reached them yet.
      final container = createContainer();
      await settle();
      final notifier = container.read(uspDdnsProvider.notifier)
        ..selectProvider(DdnsTestData.noIpPath)
        ..updateSetting((s) => s.copyWith(username: 'user'));

      notifier.validateField(DdnsField.username);

      expect(container.read(uspDdnsProvider).status.fieldErrors, isEmpty);
    });

    test('a field shows its error, then clears it once corrected', () async {
      final container = createContainer();
      await settle();
      final notifier = container.read(uspDdnsProvider.notifier)
        ..selectProvider(DdnsTestData.noIpPath)
        ..updateSetting((s) => s.copyWith(hostname: 'bad_name'))
        ..validateField(DdnsField.hostname);
      expect(container.read(uspDdnsProvider).status.fieldErrors,
          {DdnsField.hostname});

      notifier
        ..updateSetting((s) => s.copyWith(hostname: 'home.example.net'))
        ..validateField(DdnsField.hostname);

      expect(container.read(uspDdnsProvider).status.fieldErrors, isEmpty);
    });

    test('revert clears the errors the edit showed', () async {
      when(() => service.fetch())
          .thenAnswer((_) async => (DdnsTestData.configuredSettings(), loaded));
      final container = createContainer();
      await settle();
      final notifier = container.read(uspDdnsProvider.notifier)
        ..updateSetting((s) => s.copyWith(hostname: ''))
        ..validateField(DdnsField.hostname);
      expect(container.read(uspDdnsProvider).status.fieldErrors, isNotEmpty);

      notifier.revert();

      final state = container.read(uspDdnsProvider);
      expect(state.settings.current.hostname, 'home.example.net');
      expect(state.status.fieldErrors, isEmpty);
    });

    test('a new provider keeps only the errors still true under it', () async {
      final container = createContainer();
      await settle();
      final notifier = container.read(uspDdnsProvider.notifier)
        ..selectProvider(DdnsTestData.noIpPath)
        ..updateSetting((s) => s.copyWith(hostname: 'bad_name'))
        ..validateField(DdnsField.hostname);

      notifier.selectProvider(DdnsTestData.dynDnsPath);

      expect(container.read(uspDdnsProvider).status.fieldErrors,
          {DdnsField.hostname},
          reason: 'the empty user name and password were never shown red');
    });
  });

  group('UspDdnsNotifier - "Disabled"', () {
    test('drops edits made in the fields it hides', () async {
      final container = createContainer();
      await settle();
      final notifier = container.read(uspDdnsProvider.notifier)
        ..selectProvider(DdnsTestData.noIpPath)
        ..updateSetting((s) => s.copyWith(username: 'typed then hidden'));

      notifier.selectProvider(null);

      final state = container.read(uspDdnsProvider);
      expect(state.settings.current.username, '');
      expect(state.isDirty, isFalse,
          reason: 'a save would send only Enable, and report the edit saved');
    });

    test('turns off a client on a provider the router no longer offers',
        () async {
      // Enabled, on a Server row that was since disabled: the dropdown has no
      // item for it and reads "Disabled" already.
      when(() => service.fetch()).thenAnswer((_) async => (
            DdnsTestData.settings(
              clientEnabled: true,
              username: 'user@example.com',
              storedUsername: 'user@example.com',
              storedServerPath: DdnsTestData.noIpPath,
            ),
            loaded,
          ));
      final container = createContainer();
      await settle();
      final notifier = container.read(uspDdnsProvider.notifier);
      expect(
          container.read(uspDdnsProvider).settings.current.isEnabled, isFalse);

      notifier.selectProvider(null);
      expect(container.read(uspDdnsProvider).canSave, isTrue);
      await notifier.save();

      final saved = verify(() => service.save(captureAny())).captured.single
          as DdnsSettings;
      expect(saved.clientEnabled, isFalse);
      expect(saved.isEnabled, isFalse);
    });
  });

  group('UspDdnsNotifier - save', () {
    test('saves the working copy under the mutation lock, then reads it back',
        () async {
      final container = createContainer();
      await settle();
      final notifier = container.read(uspDdnsProvider.notifier)
        ..selectProvider(DdnsTestData.noIpPath)
        ..updateSetting((s) => s.copyWith(
              username: 'user@example.com',
              password: 'secret',
              hostname: 'home.example.net',
            ));
      final pending = container.read(uspDdnsProvider).settings.current;
      // The read after the save: the router never returns the password.
      when(() => service.fetch()).thenAnswer((_) async => (
            DdnsTestData.configuredSettings(),
            loaded,
          ));
      clearInteractions(statusService);

      bool? lockedDuringSave;
      when(() => service.save(any())).thenAnswer((_) async {
        lockedDuringSave = lock.isLocked;
      });

      await notifier.save();
      await settle();

      verify(() => service.save(pending)).called(1);
      expect(lockedDuringSave, isTrue,
          reason: 'the WASM client takes one call at a time');
      final state = container.read(uspDdnsProvider);
      expect(state.isDirty, isFalse);
      expect(state.settings.current.password, '');
      expect(state.status.isSaving, isFalse);
      verify(() => statusService.fetch(fresh: any(named: 'fresh'))).called(1);
    });

    test('a failed save is rethrown and leaves the edit in place', () async {
      when(() => service.save(any()))
          .thenThrow(const NetworkError(detail: 'set failed'));
      final container = createContainer();
      await settle();
      final notifier = container.read(uspDdnsProvider.notifier)
        ..selectProvider(DdnsTestData.dynDnsPath);

      await expectLater(notifier.save(), throwsA(isA<NetworkError>()));

      final state = container.read(uspDdnsProvider);
      expect(state.isDirty, isTrue);
      expect(state.settings.current.providerPath, DdnsTestData.dynDnsPath);
      expect(state.status.isSaving, isFalse);
    });

    test('a failed read after a landed save is SavedButUnconfirmedError',
        () async {
      final container = createContainer();
      await settle();
      final notifier = container.read(uspDdnsProvider.notifier)
        ..selectProvider(DdnsTestData.dynDnsPath);
      when(() => service.fetch())
          .thenThrow(const NetworkError(detail: 'read failed'));

      await expectLater(
          notifier.save(), throwsA(isA<SavedButUnconfirmedError>()));
      verify(() => service.save(any())).called(1);
    });
  });
}
