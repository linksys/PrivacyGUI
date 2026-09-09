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
/// [buildDelay] holds this provider in `AsyncLoading` past the point where
/// `mount` mounts the trigger notifier, which is how a test reproduces an L1
/// provider that `dashboardDomainReadyProvider` does not await.
class _MutableWanNotifier extends WanDataNotifier {
  _MutableWanNotifier(this._data, {this.buildDelay = Duration.zero});
  WanData _data;
  final Duration buildDelay;

  @override
  Future<WanData> build() async {
    if (buildDelay > Duration.zero) await Future.delayed(buildDelay);
    return _data;
  }

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
  _MutableFirewallNotifier(this._data, {this.buildDelay = Duration.zero});
  FirewallData _data;
  final Duration buildDelay;

  @override
  Future<FirewallData> build() async {
    if (buildDelay > Duration.zero) await Future.delayed(buildDelay);
    return _data;
  }

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

  tearDown(() => sse.close());

  /// Builds the container, resolves the L1 providers, then mounts the trigger
  /// notifier with [fired] wired to `onTrigger`.
  ///
  /// `mascotTriggerProvider` is autoDispose, so the standing `listen` is what
  /// keeps the notifier — and its debounce timer — alive between events.
  /// Pass `dashboardReady: false` to hold [dashboardDomainReadyProvider] in
  /// `AsyncLoading` for the whole test — the one state in which `build()`
  /// deliberately captures no baseline.
  ProviderContainer mount(FakeAsync async, {bool dashboardReady = true}) {
    final container = ProviderContainer(overrides: [
      sseInvalidationProvider.overrideWith((ref) => sse.stream),
      dashboardDomainReadyProvider.overrideWith(
        (ref) => dashboardReady ? Future.value() : Completer<void>().future,
      ),
      wanDataProvider.overrideWith(() => wan),
      devicesDataProvider.overrideWith(() => devices),
      firewallDataProvider.overrideWith(() => firewall),
      wifiDataProvider.overrideWith(() => wifi),
    ]);

    // Resolve every async dependency before the notifier builds, so
    // `_seedBaseline` runs against loaded data rather than AsyncLoading — unless
    // a stand-in was given a `buildDelay`, which is the point of that knob.
    //
    // Any non-zero duration works; `flushMicrotasks()` does not, because it
    // runs the notifier's own work without publishing the build result — the
    // container still reads AsyncLoading. The value is deliberately small only
    // to keep the elapsed clock readable in the debounce assertions below; the
    // trigger notifier is not mounted yet, so no timer of its own is armed here.
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
    // This is the inverted #1509 pin. It used to assert four nulls: the
    // baseline was assigned to `state` *inside* `build()`, and riverpod applies
    // build()'s return value afterwards — `setState(provider.runNotifierBuild(
    // notifier))`, riverpod-2.6.1/lib/src/notifier/base.dart:212 (3.4.3 does the
    // same at providers/notifier.dart:94) — so the assignment was silently
    // discarded, every `previousXxx` stayed null, and the first SSE event per
    // domain could only seed, never fire. Returning the baseline from build()
    // is the fix; this test is what goes red if anyone assigns it again.
    test('build seeds every previous value from the loaded L1 providers', () {
      fakeAsync((async) {
        final container = mount(async);

        final state = container.read(mascotTriggerProvider);
        expect(state.lastTrigger, isNull);
        expect(state.previousWanUp, isTrue);
        expect(state.previousDeviceCount, 2);
        expect(state.previousFirewallEnabled, isTrue);
        expect(state.previousDisabledRadios, isEmpty);

        container.dispose();
      });
    });

    // The observable half of the fix, one test per watched domain: the router
    // changes, and the *first* event announcing it fires. Every one of these
    // asserted `fired, isEmpty` before #1509.
    test('the first wanStatus event fires wan_down', () {
      fakeAsync((async) {
        final container = mount(async);

        wan.setData(SystemHealthTestData.createWanData(isUp: false));
        emit(async, InvalidationDomain.wanStatus, 0);

        expect(fired.map((t) => t.id), ['wan_down']);

        container.dispose();
      });
    });

    test('the first connectedDevices event fires new_device_joined', () {
      fakeAsync((async) {
        final container = mount(async);

        devices.setData(MascotTestData.createDevicesData(clientCount: 3));
        emit(async, InvalidationDomain.connectedDevices, 0);

        expect(fired.map((t) => t.id), ['new_device_joined']);

        container.dispose();
      });
    });

    test('the first firewallRules event fires firewall_disabled', () {
      fakeAsync((async) {
        final container = mount(async);

        firewall.setData(FirewallTestData.createFirewallDisabledData());
        emit(async, InvalidationDomain.firewallRules, 0);

        expect(fired.map((t) => t.id), ['firewall_disabled']);

        container.dispose();
      });
    });

    test('the first wifiRadios event fires wifi_radio_disabled', () {
      fakeAsync((async) {
        final container = mount(async);

        wifi.setData(WifiSettingsTestData.createWifiData(
          radioModels:
              WifiSettingsTestData.createRadioUIModels(is5GhzEnabled: false),
        ));
        emit(async, InvalidationDomain.wifiRadios, 0);

        expect(fired.map((t) => t.id), ['wifi_radio_disabled_5GHz']);

        container.dispose();
      });
    });

    // The half of #1509 the ticket's one-line fix does not reach.
    // `dashboardDomainReadyProvider` awaits systemInfo/devices/ethernet only, so
    // `wanDataProvider` and `firewallDataProvider` — both card-driven, and
    // `firewall_overview` sits below the fold — can still be in flight when the
    // mascot mounts, leaving `build()` nothing to seed from. `_fillMissingBaseline`
    // closes it by reading the pre-event value as the event arrives.
    //
    // The ordering below is the production one and is what makes that read a
    // *pre-event* value: the SSE event lands first, the L1 refetch it triggers
    // lands inside the 500 ms debounce window.
    test('a baseline missing at build is filled from the pre-event value', () {
      fakeAsync((async) {
        firewall = _MutableFirewallNotifier(
          FirewallTestData.createFirewallData(),
          buildDelay: const Duration(milliseconds: 50),
        );

        final container = mount(async);

        // mount() elapses 5 ms; the firewall fetch needs 50 ms.
        expect(container.read(mascotTriggerProvider).previousFirewallEnabled,
            isNull);
        async.elapse(const Duration(milliseconds: 100));

        sse.add((domain: InvalidationDomain.firewallRules, seq: 0));
        async.elapse(const Duration(milliseconds: 100));
        expect(container.read(mascotTriggerProvider).previousFirewallEnabled,
            isTrue);

        firewall.setData(FirewallTestData.createFirewallDisabledData());
        async.elapse(const Duration(milliseconds: 500));

        expect(fired.map((t) => t.id), ['firewall_disabled']);

        container.dispose();
      });
    });

    // The trap inside the fill: `copyWith` prefers its argument, so expressing it
    // as `state.copyWith(previousFirewallEnabled: baseline.previousFirewallEnabled)`
    // would overwrite a good baseline with the already-changed value and swallow
    // the notification. Here the baseline is genuinely incomplete — wan is still
    // in flight, so the fill runs — while the firewall value it reads is the new
    // one, which is exactly the state that punishes the wrong merge direction.
    test('the fill never overwrites a baseline build already captured', () {
      fakeAsync((async) {
        wan = _MutableWanNotifier(
          SystemHealthTestData.createWanData(isUp: true),
          buildDelay: const Duration(milliseconds: 50),
        );

        final container = mount(async);
        expect(container.read(mascotTriggerProvider).previousWanUp, isNull);
        expect(container.read(mascotTriggerProvider).previousFirewallEnabled,
            isTrue);

        firewall.setData(FirewallTestData.createFirewallDisabledData());
        emit(async, InvalidationDomain.firewallRules, 0);

        expect(fired.map((t) => t.id), ['firewall_disabled']);

        container.dispose();
      });
    });

    // The boundary of the fix, pinned deliberately. `build()` only captures a
    // baseline once the dashboard is ready, and `_fillMissingBaseline` defers to
    // the same guard, so a notifier mounted before that still cannot fire on its
    // first event per domain. Kept as a test because it is the one path where the
    // null baseline is by design rather than by accident: pre-ready there is no
    // trustworthy "previous" to speak of, and in production the coordinator only
    // reads the trigger notifier once `isDashboardReady` (mascot_providers.dart).
    test('no baseline is captured while the dashboard is not ready', () {
      fakeAsync((async) {
        final container = mount(async, dashboardReady: false);

        expect(container.read(mascotTriggerProvider).previousWanUp, isNull);

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

        // Event 1 announces nothing: the baseline captured at build() already
        // says the WAN is up, so there is no change to report.
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
