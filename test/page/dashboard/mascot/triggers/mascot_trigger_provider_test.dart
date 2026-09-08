import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/dashboard/mascot/triggers/mascot_trigger.dart';
import 'package:privacy_gui/page/dashboard/mascot/triggers/mascot_trigger_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

import '../../../../mocks/test_data/firewall_test_data.dart';
import '../../../../mocks/test_data/mascot_test_data.dart';
import '../../../../mocks/test_data/system_health_test_data.dart';
import '../../../../mocks/test_data/wifi_settings_test_data.dart';

/// The four L1 providers the trigger notifier reads, each swapped for a
/// mutable stand-in so a test can change the router's state between SSE events.
///
/// `build()` is overridden wholesale (not calling `super.build()`), which also
/// strips each L1 provider's own SSE listener — these tests must observe only
/// the mascot notifier's reaction, not a cascade of L1 re-fetches.
class _MutableWanNotifier extends WanDataNotifier {
  _MutableWanNotifier(this._data);
  WanData _data;

  @override
  Future<WanData> build() async => _data;

  void setData(WanData data) {
    _data = data;
    state = AsyncData(data);
  }
}

class _MutableDevicesNotifier extends DevicesDataNotifier {
  _MutableDevicesNotifier(this._data);
  DevicesData _data;

  @override
  Future<DevicesData> build() async => _data;

  void setData(DevicesData data) {
    _data = data;
    state = AsyncData(data);
  }
}

class _MutableFirewallNotifier extends FirewallDataNotifier {
  _MutableFirewallNotifier(this._data);
  FirewallData _data;

  @override
  Future<FirewallData> build() async => _data;

  void setData(FirewallData data) {
    _data = data;
    state = AsyncData(data);
  }
}

class _MutableWifiNotifier extends WifiDataNotifier {
  _MutableWifiNotifier(this._data);
  WifiData _data;

  @override
  Future<WifiData> build() async => _data;

  void setData(WifiData data) {
    _data = data;
    state = AsyncData(data);
  }
}

void main() {
  late _MutableWanNotifier wan;
  late _MutableDevicesNotifier devices;
  late _MutableFirewallNotifier firewall;
  late _MutableWifiNotifier wifi;
  late StreamController<InvalidationEvent> sse;
  late List<MascotTrigger> fired;

  setUp(() {
    wan = _MutableWanNotifier(SystemHealthTestData.createWanData(isUp: true));
    devices = _MutableDevicesNotifier(MascotTestData.createDevicesData());
    firewall = _MutableFirewallNotifier(FirewallTestData.createFirewallData());
    wifi = _MutableWifiNotifier(WifiSettingsTestData.createWifiData(
      radioModels: WifiSettingsTestData.createRadioUIModels(),
    ));
    sse = StreamController<InvalidationEvent>.broadcast();
    fired = [];
  });

  /// Builds the container, resolves the L1 providers, then mounts the trigger
  /// notifier with [fired] wired to `onTrigger`.
  ///
  /// `mascotTriggerProvider` is autoDispose, so the standing `listen` is what
  /// keeps the notifier — and its debounce timer — alive between events.
  ProviderContainer mount(FakeAsync async) {
    final container = ProviderContainer(overrides: [
      sseInvalidationProvider.overrideWith((ref) => sse.stream),
      dashboardDomainReadyProvider.overrideWith((ref) async {}),
      wanDataProvider.overrideWith(() => wan),
      devicesDataProvider.overrideWith(() => devices),
      firewallDataProvider.overrideWith(() => firewall),
      wifiDataProvider.overrideWith(() => wifi),
    ]);

    // Resolve every async dependency before the notifier builds, so
    // `_initializeState` runs against loaded data rather than AsyncLoading.
    container.listen(dashboardDomainReadyProvider, (_, __) {});
    container.listen(wanDataProvider, (_, __) {});
    container.listen(devicesDataProvider, (_, __) {});
    container.listen(firewallDataProvider, (_, __) {});
    container.listen(wifiDataProvider, (_, __) {});
    async.elapse(const Duration(milliseconds: 5));

    container.listen(mascotTriggerProvider, (_, __) {});
    container.read(mascotTriggerProvider.notifier).onTrigger = fired.add;
    return container;
  }

  /// Pushes one SSE event and lets the notifier's 500 ms debounce fire.
  void emit(FakeAsync async, InvalidationDomain domain, int seq) {
    sse.add((domain: domain, seq: seq));
    async.elapse(const Duration(milliseconds: 600));
  }

  group('MascotTriggerNotifier', () {
    // Documents a real defect, not desired behaviour: `_initializeState()`
    // assigns `state = MascotTriggerState(previousWanUp: ...)` *inside*
    // `build()`, and riverpod 2.6.1 immediately overwrites it with build()'s
    // return value — `setState(provider.runNotifierBuild(notifier))`,
    // riverpod-2.6.1/lib/src/notifier/base.dart:212. So every `previousXxx`
    // stays null however much data is loaded, and the first SSE event per
    // domain can only seed, never fire. When that is fixed, this test must be
    // inverted to expect the seeded values.
    test(
        'build does not seed previous values (state assigned in build is lost)',
        () {
      fakeAsync((async) {
        final container = mount(async);

        final state = container.read(mascotTriggerProvider);
        expect(state.lastTrigger, isNull);
        expect(state.previousWanUp, isNull);
        expect(state.previousDeviceCount, isNull);
        expect(state.previousFirewallEnabled, isNull);
        expect(state.previousDisabledRadios, isNull);

        // The observable consequence: WAN is already down when the very first
        // wanStatus event arrives, and nothing fires.
        wan.setData(SystemHealthTestData.createWanData(isUp: false));
        emit(async, InvalidationDomain.wanStatus, 0);

        expect(fired, isEmpty);
        expect(container.read(mascotTriggerProvider).previousWanUp, isFalse);

        container.dispose();
      });
    });

    test('SSE wanStatus fires wan_down, then wan_restored on the way back', () {
      fakeAsync((async) {
        final container = mount(async);

        // Event 1 only seeds previousWanUp = true (see the defect above).
        emit(async, InvalidationDomain.wanStatus, 0);
        expect(fired, isEmpty);

        wan.setData(SystemHealthTestData.createWanData(isUp: false));
        emit(async, InvalidationDomain.wanStatus, 1);
        expect(fired.map((t) => t.id), ['wan_down']);
        expect(fired.last.priority, TriggerPriority.critical);

        wan.setData(SystemHealthTestData.createWanData(isUp: true));
        emit(async, InvalidationDomain.wanStatus, 2);
        expect(fired.map((t) => t.id), ['wan_down', 'wan_restored']);

        // Both events reached the notifier: same domain three times, so `seq`
        // (#1501 AC-B1) is the only difference between consecutive events, and
        // each is spaced past the 500 ms debounce window — inside it they are
        // *meant* to merge, so a repeat asserted there could not tell a real
        // collapse from the debouncer doing its job.
        expect(container.read(mascotTriggerProvider).lastTrigger?.id,
            'wan_restored');

        container.dispose();
      });
    });

    test('SSE connectedDevices fires new_device_joined when the count grows',
        () {
      fakeAsync((async) {
        final container = mount(async);

        emit(async, InvalidationDomain.connectedDevices, 0);
        expect(fired, isEmpty);
        expect(container.read(mascotTriggerProvider).previousDeviceCount, 2);

        devices.setData(MascotTestData.createDevicesData(clientCount: 3));
        emit(async, InvalidationDomain.connectedDevices, 1);

        expect(fired.map((t) => t.id), ['new_device_joined']);
        expect(fired.last.message, contains('Client-3'));

        container.dispose();
      });
    });

    test('SSE firewallRules fires firewall_disabled when SPI is turned off',
        () {
      fakeAsync((async) {
        final container = mount(async);

        emit(async, InvalidationDomain.firewallRules, 0);
        expect(fired, isEmpty);
        expect(container.read(mascotTriggerProvider).previousFirewallEnabled,
            isTrue);

        firewall.setData(FirewallTestData.createFirewallDisabledData());
        emit(async, InvalidationDomain.firewallRules, 1);

        expect(fired.map((t) => t.id), ['firewall_disabled']);

        container.dispose();
      });
    });

    test('SSE wifiRadios fires wifi_radio_disabled for the newly-off band', () {
      fakeAsync((async) {
        final container = mount(async);

        emit(async, InvalidationDomain.wifiRadios, 0);
        expect(fired, isEmpty);
        expect(container.read(mascotTriggerProvider).previousDisabledRadios,
            isEmpty);

        wifi.setData(WifiSettingsTestData.createWifiData(
          radioModels:
              WifiSettingsTestData.createRadioUIModels(is5GhzEnabled: false),
        ));
        emit(async, InvalidationDomain.wifiRadios, 1);

        expect(fired.map((t) => t.id), ['wifi_radio_disabled_5GHz']);

        container.dispose();
      });
    });

    // wifiSsids is the sharpest wrong answer: wifiRadios *is* in
    // `notificationDomains`, so a guard that matched the WiFi family would
    // survive a test using an obviously unrelated domain. The state is primed
    // to fire — previousDisabledRadios is seeded and 5 GHz is already off — so
    // the only reason nothing happens is the domain filter itself.
    test('SSE wifiSsids does not trigger anything', () {
      fakeAsync((async) {
        final container = mount(async);

        emit(async, InvalidationDomain.wifiRadios, 0);
        expect(fired, isEmpty);

        wifi.setData(WifiSettingsTestData.createWifiData(
          radioModels:
              WifiSettingsTestData.createRadioUIModels(is5GhzEnabled: false),
        ));
        emit(async, InvalidationDomain.wifiSsids, 1);

        expect(fired, isEmpty);
        expect(container.read(mascotTriggerProvider).lastTrigger, isNull);

        // Proof the primed state really would have fired: the same data with
        // the watched domain does.
        emit(async, InvalidationDomain.wifiRadios, 2);
        expect(fired.map((t) => t.id), ['wifi_radio_disabled_5GHz']);

        container.dispose();
      });
    });

    // The listener's domain filter is *not* observable through the fire/no-fire
    // assertion above: `_evaluateTriggers` switches on the domain and
    // `wifiSsids` lands on `default: break`, so an unwatched domain produces no
    // trigger either way. Measured by forcing the guard permanently true — all
    // seven other tests here still passed.
    //
    // What the guard actually buys is this: `_debouncedEvaluate` *cancels* the
    // pending timer, so an unfiltered event arriving inside the 500 ms window
    // would replace a queued watched-domain evaluation with a no-op one and the
    // mascot notification would be lost outright.
    test(
        'an unwatched domain inside the debounce window does not swallow a '
        'pending trigger', () {
      fakeAsync((async) {
        final container = mount(async);

        // Seed previousDisabledRadios = {} (both radios enabled).
        emit(async, InvalidationDomain.wifiRadios, 0);
        expect(fired, isEmpty);

        wifi.setData(WifiSettingsTestData.createWifiData(
          radioModels:
              WifiSettingsTestData.createRadioUIModels(is5GhzEnabled: false),
        ));

        // Watched domain: arms the debounce timer for t+500ms.
        sse.add((domain: InvalidationDomain.wifiRadios, seq: 1));
        async.elapse(const Duration(milliseconds: 300));
        expect(fired, isEmpty);

        // Unwatched domain 200ms before that timer is due. It must be dropped
        // by the listener — not re-arm the timer with its own domain.
        sse.add((domain: InvalidationDomain.wifiSsids, seq: 2));
        async.elapse(const Duration(milliseconds: 300));

        expect(fired.map((t) => t.id), ['wifi_radio_disabled_5GHz']);

        container.dispose();
      });
    });

    test('a repeat of the same change does not re-fire', () {
      fakeAsync((async) {
        final container = mount(async);

        emit(async, InvalidationDomain.wanStatus, 0);
        wan.setData(SystemHealthTestData.createWanData(isUp: false));
        emit(async, InvalidationDomain.wanStatus, 1);
        expect(fired.map((t) => t.id), ['wan_down']);

        // Same state, new event: the change detector must swallow it (the
        // cooldown is a second line of defence, not the one under test).
        emit(async, InvalidationDomain.wanStatus, 2);
        expect(fired.map((t) => t.id), ['wan_down']);

        container.dispose();
      });
    });
  });
}
