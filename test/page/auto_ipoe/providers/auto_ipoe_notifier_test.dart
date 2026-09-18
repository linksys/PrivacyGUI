// Unit tests for AutoIPoENotifier, the single coordination point of the
// feature. Three surfaces reach it — Internet Settings, the optional pane and
// the troubleshooter views — so every branch here is shared behaviour.
//
// The one that most needs pinning is the support gate in fetchAll(). Internet
// Settings fetches on entry for every router, so on a router that does not
// advertise the AutoIPoE service the four Get actions would all fail and take
// the page's initial load down with them. The gate has to do more than return
// early: it must not touch the service at all, which is why the fake here
// records its calls and the gated test asserts that record is empty.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_notifier.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_state.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_service.dart';

import '../../../common/di.dart';
import '../../../test_data/auto_ipoe_state_data.dart';

/// Records every call so the tests can assert what the notifier did *not* do as
/// well as what it did.
class _RecordingService extends Fake implements AutoIPoEService {
  _RecordingService(this.seed);

  final AutoIPoEState seed;
  final calls = <String>[];

  AutoIPoESettings? lastSavedSettings;
  AutoIPoESettings? lastAppliedSettings;
  bool? lastResetFirst;

  @override
  Future<AutoIPoECapabilities> getCapabilities() async {
    calls.add('getCapabilities');
    return seed.capabilities;
  }

  @override
  Future<AutoIPoESettings> getSettings() async {
    calls.add('getSettings');
    return seed.settings;
  }

  @override
  Future<AutoIPoEStatus> getStatus() async {
    calls.add('getStatus');
    return seed.status;
  }

  @override
  Future<AutoIPoELog> getLog() async {
    calls.add('getLog');
    return seed.log;
  }

  @override
  Future<void> setSettings(AutoIPoESettings settings) async {
    calls.add('setSettings');
    lastSavedSettings = settings;
  }

  @override
  Future<AutoIPoEStatus> apply({
    bool resetFirst = false,
    bool pnpReflectAfterApply = false,
    AutoIPoESettings? settings,
  }) async {
    calls.add('apply');
    lastResetFirst = resetFirst;
    lastAppliedSettings = settings;
    return seed.status;
  }

  @override
  Future<AutoIPoEStatus> reset() async {
    calls.add('reset');
    return seed.status;
  }
}

void main() {
  mockDependencyRegister();
  final ServiceHelper mockServiceHelper = GetIt.I<ServiceHelper>();

  final seed = AutoIPoEState.fromMap(autoIPoEStateV6Plus);

  late _RecordingService service;
  late ProviderContainer container;
  late AutoIPoENotifier notifier;

  void build({required bool serviceAdvertised}) {
    when(mockServiceHelper.isSupportAutoIPoE()).thenReturn(serviceAdvertised);
    container = ProviderContainer(overrides: [
      autoIPoEServiceProvider.overrideWithValue(service),
    ]);
    notifier = container.read(autoIPoEProvider.notifier);
  }

  setUp(() {
    service = _RecordingService(seed);
  });

  tearDown(() {
    container.dispose();
    reset(mockServiceHelper);
  });

  test('starts at the init state', () {
    build(serviceAdvertised: true);

    expect(container.read(autoIPoEProvider), const AutoIPoEState.init());
  });

  group('fetchAll', () {
    test('sends nothing and stays at init when the service is not advertised',
        () async {
      build(serviceAdvertised: false);

      final result = await notifier.fetchAll();

      expect(result, const AutoIPoEState.init());
      expect(result.capabilities.isSupported, isFalse);
      // The whole point of the gate: not one action goes out.
      expect(service.calls, isEmpty);
    });

    test('populates all four parts when the service is advertised', () async {
      build(serviceAdvertised: true);

      final result = await notifier.fetchAll();

      expect(service.calls,
          ['getCapabilities', 'getSettings', 'getStatus', 'getLog']);
      expect(result, seed);
      expect(container.read(autoIPoEProvider), seed);
    });
  });

  group('fetchCapabilities', () {
    test('reads only the capabilities and leaves the rest alone', () async {
      build(serviceAdvertised: true);

      final capabilities = await notifier.fetchCapabilities();

      // The troubleshooter asks before the user has chosen anything, and must
      // not adopt whatever mode the router happens to be configured with.
      expect(service.calls, ['getCapabilities']);
      expect(capabilities, seed.capabilities);
      expect(container.read(autoIPoEProvider).capabilities, seed.capabilities);
      expect(container.read(autoIPoEProvider).settings,
          const AutoIPoESettings.init());
      expect(
          container.read(autoIPoEProvider).status, const AutoIPoEStatus.init());
    });
  });

  group('runtime refreshes', () {
    test('refreshStatus touches only the status', () async {
      build(serviceAdvertised: true);

      final result = await notifier.refreshStatus();

      expect(service.calls, ['getStatus']);
      expect(result.status, seed.status);
      // Capabilities and settings were never fetched, so they must be untouched.
      expect(result.capabilities, const AutoIPoECapabilities.init());
      expect(result.settings, const AutoIPoESettings.init());
    });

    test('refreshRuntime touches status and log only', () async {
      build(serviceAdvertised: true);

      final result = await notifier.refreshRuntime();

      expect(service.calls, ['getStatus', 'getLog']);
      expect(result.status, seed.status);
      expect(result.log, seed.log);
      expect(result.capabilities, const AutoIPoECapabilities.init());
    });

    test('updateRuntime writes through without calling the router', () {
      build(serviceAdvertised: true);

      notifier.updateRuntime(seed.status, seed.log);

      expect(service.calls, isEmpty);
      expect(container.read(autoIPoEProvider).status, seed.status);
      expect(container.read(autoIPoEProvider).log, seed.log);
    });
  });

  group('mutations', () {
    test('saveSettings writes the settings then re-reads status', () async {
      build(serviceAdvertised: true);

      final result = await notifier.saveSettings(seed.settings);

      // The status re-read matters: Apply state changes as a result of the save,
      // so returning the pre-save status would show a stale one.
      expect(service.calls, ['setSettings', 'getStatus']);
      expect(service.lastSavedSettings, seed.settings);
      expect(result.settings, seed.settings);
      expect(result.status, seed.status);
    });

    test('apply forwards resetFirst and the current settings', () async {
      build(serviceAdvertised: true);
      notifier.updateSettings(seed.settings);

      await notifier.apply(resetFirst: true);

      expect(service.lastResetFirst, isTrue);
      expect(service.lastAppliedSettings, seed.settings);
    });

    test('apply defaults to not resetting first', () async {
      build(serviceAdvertised: true);

      await notifier.apply();

      expect(service.lastResetFirst, isFalse);
    });

    test('reset disables the settings alongside the new status', () async {
      build(serviceAdvertised: true);
      notifier.updateSettings(seed.settings);

      final result = await notifier.reset();

      expect(service.calls, ['reset']);
      expect(result.settings.isEnabled, isFalse);
      expect(result.settings.selectedMode, AutoIPoEMode.disabled);
      expect(result.status, seed.status);
    });

    test('updateSettings writes through without calling the router', () {
      build(serviceAdvertised: true);

      notifier.updateSettings(seed.settings);

      expect(service.calls, isEmpty);
      expect(container.read(autoIPoEProvider).settings, seed.settings);
    });
  });
}
