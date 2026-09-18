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

/// The four L1 providers the trigger notifier reads, each swapped for a mutable
/// stand-in so a test can change the router's state and observe the reaction.
///
/// `build()` is overridden wholesale (not calling `super.build()`), which also
/// strips each L1 provider's own SSE listener and its 500 ms invalidate
/// debounce — those are the *other* side of the collision these tests are about,
/// and a test models them by choosing *when* it calls [setData].
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
  /// keeps the notifier — and its four domain listeners — alive.
  /// Pass `dashboardReady: false` to hold [dashboardDomainReadyProvider] in
  /// `AsyncLoading` for the whole test — the one state in which `build()`
  /// deliberately captures no baseline.
  ///
  /// The `sseInvalidationProvider` override is deliberately still here even
  /// though the notifier no longer reads it: it is what lets
  /// `a change that lands long after the event still fires` replay the full
  /// production sequence — event first, value 550 ms later — and that sequence
  /// is what the previous clock-driven implementation got wrong.
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
    // container still reads AsyncLoading.
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

  /// Lets a published L1 value reach the notifier's listeners.
  void settle(FakeAsync async) => async.elapse(const Duration(milliseconds: 1));

  group('MascotTriggerNotifier', () {
    // This is the inverted #1509 pin. It used to assert four nulls: the
    // baseline was assigned to `state` *inside* `build()`, and riverpod applies
    // build()'s return value afterwards — `setState(provider.runNotifierBuild(
    // notifier))`, riverpod-2.6.1/lib/src/notifier/base.dart:212 (3.4.3 does the
    // same at providers/notifier.dart:94) — so the assignment was silently
    // discarded, every `previousXxx` stayed null, and the first change per
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
    // changes, and the *first* change fires. Every one of these asserted
    // `fired, isEmpty` before #1509.
    test('the first WAN change fires wan_down', () {
      fakeAsync((async) {
        final container = mount(async);

        wan.setData(SystemHealthTestData.createWanData(isUp: false));
        settle(async);

        expect(fired.map((t) => t.id), ['wan_down']);

        container.dispose();
      });
    });

    test('the first device-count change fires new_device_joined', () {
      fakeAsync((async) {
        final container = mount(async);

        devices.setData(MascotTestData.createDevicesData(clientCount: 3));
        settle(async);

        expect(fired.map((t) => t.id), ['new_device_joined']);
        expect(fired.last.message, contains('Client-3'));

        container.dispose();
      });
    });

    test('the first firewall change fires firewall_disabled', () {
      fakeAsync((async) {
        final container = mount(async);

        firewall.setData(FirewallTestData.createFirewallDisabledData());
        settle(async);

        expect(fired.map((t) => t.id), ['firewall_disabled']);

        container.dispose();
      });
    });

    test('the first radio change fires wifi_radio_disabled', () {
      fakeAsync((async) {
        final container = mount(async);

        wifi.setData(WifiSettingsTestData.createWifiData(
          radioModels:
              WifiSettingsTestData.createRadioUIModels(is5GhzEnabled: false),
        ));
        settle(async);

        expect(fired.map((t) => t.id), ['wifi_radio_disabled_5GHz']);

        container.dispose();
      });
    });

    // The reason this notifier is value-driven and not SSE-plus-timer-driven.
    //
    // `firewallDataProvider` debounces its own SSE-triggered refetch by 500 ms
    // (`firewall_data_provider.dart:137-141`; `wifi_data_provider.dart:109-112`
    // and `devices_data_provider.dart:246-249` are the same shape), so the new
    // value cannot exist before T+500 — the USP round-trip only *starts* then.
    // A mascot-side 500 ms debounce therefore evaluated against the unchanged
    // value and announced nothing: measured `[]` for firewallRules, wifiRadios
    // and connectedDevices, and only `wanStatus` worked because
    // `wan_data_provider.dart:49-51` invalidates with no debounce.
    //
    // 550 ms models that whole chain: the L1's own debounce plus a round-trip.
    // Nothing in the notifier may depend on when the value shows up.
    test('a change that lands long after the event still fires', () {
      fakeAsync((async) {
        final container = mount(async);

        sse.add((domain: InvalidationDomain.firewallRules, seq: 0));
        Timer(
          const Duration(milliseconds: 550),
          () => firewall.setData(FirewallTestData.createFirewallDisabledData()),
        );
        async.elapse(const Duration(seconds: 2));

        expect(fired.map((t) => t.id), ['firewall_disabled']);

        container.dispose();
      });
    });

    // `build()` can only seed what is already loaded, and
    // `dashboardDomainReadyProvider` awaits systemInfo/devices/ethernet only, so
    // `wanDataProvider` and `firewallDataProvider` — both card-driven, and
    // `firewall_overview` sits below the fold — can still be in flight when the
    // mascot mounts. The domain listener closes that gap for free: the first
    // settled value seeds, and the change after it fires.
    test('a domain still loading at build seeds from its first settled value',
        () {
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
        expect(container.read(mascotTriggerProvider).previousFirewallEnabled,
            isTrue);
        expect(fired, isEmpty);

        firewall.setData(FirewallTestData.createFirewallDisabledData());
        settle(async);

        expect(fired.map((t) => t.id), ['firewall_disabled']);

        container.dispose();
      });
    });

    // Each domain is listened to independently. The previous implementation
    // shared one debounce timer across all four and cancelled it
    // unconditionally, so an event on one domain discarded another's pending
    // evaluation; here wan is still in flight while firewall fires.
    test('a domain still in flight does not stop another from firing', () {
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
        settle(async);

        expect(fired.map((t) => t.id), ['firewall_disabled']);

        container.dispose();
      });
    });

    // Two domains changing at once both get announced — neither is dropped.
    test('changes on two domains each fire', () {
      fakeAsync((async) {
        final container = mount(async);

        wan.setData(SystemHealthTestData.createWanData(isUp: false));
        firewall.setData(FirewallTestData.createFirewallDisabledData());
        settle(async);

        expect(fired.map((t) => t.id),
            containsAll(['wan_down', 'firewall_disabled']));

        container.dispose();
      });
    });

    // The boundary of the fix, pinned deliberately. `build()` only captures a
    // baseline once the dashboard is ready, so a notifier mounted before that
    // seeds from the first value it sees instead — which means the change that
    // arrived during the gap is absorbed, not announced. Kept as a test because
    // it is the one path where the null baseline is by design rather than by
    // accident, and in production the coordinator only wires `onTrigger` once
    // `isDashboardReady` (`mascot_providers.dart`).
    test('no baseline is captured while the dashboard is not ready', () {
      fakeAsync((async) {
        final container = mount(async, dashboardReady: false);

        expect(container.read(mascotTriggerProvider).previousWanUp, isNull);

        wan.setData(SystemHealthTestData.createWanData(isUp: false));
        settle(async);

        expect(fired, isEmpty);
        expect(container.read(mascotTriggerProvider).previousWanUp, isFalse);

        container.dispose();
      });
    });

    test('wan_down, then wan_restored on the way back', () {
      fakeAsync((async) {
        final container = mount(async);

        wan.setData(SystemHealthTestData.createWanData(isUp: false));
        settle(async);
        expect(fired.map((t) => t.id), ['wan_down']);
        expect(fired.last.priority, TriggerPriority.critical);

        wan.setData(SystemHealthTestData.createWanData(isUp: true));
        settle(async);
        expect(fired.map((t) => t.id), ['wan_down', 'wan_restored']);

        expect(container.read(mascotTriggerProvider).lastTrigger?.id,
            'wan_restored');

        container.dispose();
      });
    });

    test('a device leaving does not fire', () {
      fakeAsync((async) {
        final container = mount(async);

        devices.setData(MascotTestData.createDevicesData(clientCount: 1));
        settle(async);

        expect(fired, isEmpty);
        expect(container.read(mascotTriggerProvider).previousDeviceCount, 1);

        container.dispose();
      });
    });

    test('a republished but unchanged value does not fire', () {
      fakeAsync((async) {
        final container = mount(async);

        wan.setData(SystemHealthTestData.createWanData(isUp: false));
        settle(async);
        expect(fired.map((t) => t.id), ['wan_down']);

        // Same state published again: the change detector must swallow it (the
        // cooldown is a second line of defence, not the one under test).
        wan.setData(SystemHealthTestData.createWanData(isUp: false));
        settle(async);
        expect(fired.map((t) => t.id), ['wan_down']);

        container.dispose();
      });
    });

    // A radio going *back* on is not a notification, and must not be reported
    // as one just because the disabled-set changed.
    test('re-enabling a radio does not fire', () {
      fakeAsync((async) {
        wifi = _MutableWifiNotifier(WifiSettingsTestData.createWifiData(
          radioModels:
              WifiSettingsTestData.createRadioUIModels(is5GhzEnabled: false),
        ));

        final container = mount(async);
        expect(container.read(mascotTriggerProvider).previousDisabledRadios,
            {'5GHz'});

        wifi.setData(WifiSettingsTestData.createWifiData(
          radioModels: WifiSettingsTestData.createRadioUIModels(),
        ));
        settle(async);

        expect(fired, isEmpty);
        expect(container.read(mascotTriggerProvider).previousDisabledRadios,
            isEmpty);

        container.dispose();
      });
    });
  });
}
