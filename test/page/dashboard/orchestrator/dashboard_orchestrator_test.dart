import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/page/administration/providers/upnp_data_provider.dart';
import 'package:privacy_gui/page/ipv6_port_service/providers/ipv6_port_service_data_provider.dart';
import 'package:privacy_gui/page/dashboard/orchestrator/dashboard_orchestrator.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_data.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_mode.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_data_provider.dart';

/// Connection state a test can move by hand. `build()` is overridden so none of
/// the real notifier's wiring (SSE manager, auth listener) runs.
class _DrivenConnectionState extends AppConnectionStateNotifier {
  @override
  AppConnectionState build() => AppConnectionState.authenticated;

  void move(AppConnectionState next) => state = next;
}

/// Counts fetches. The value is never read, so it fails rather than inventing a
/// `WanData`.
class _CountingWanDataNotifier extends WanDataNotifier {
  int builds = 0;

  @override
  Future<WanData> build() async {
    builds++;
    throw StateError('not read by these tests');
  }
}

/// Counts reads of the session-wide MAC filter (the menu's Instant Privacy badge).
class _CountingMacFilterDataNotifier extends MacFilterDataNotifier {
  int builds = 0;

  @override
  Future<MacFilterData> build() async {
    builds++;
    return const MacFilterData(mode: MacFilterMode.disabled, macs: []);
  }
}

void main() {
  late _DrivenConnectionState connection;
  late _CountingWanDataNotifier wan;
  late ProviderContainer container;
  late List<AsyncValue<DashboardOrchestratorState>> orchestratorStates;

  setUp(() {
    connection = _DrivenConnectionState();
    wan = _CountingWanDataNotifier();
    container = ProviderContainer(overrides: [
      appConnectionStateProvider.overrideWith(() => connection),
      wanDataProvider.overrideWith(() => wan),
    ]);
    addTearDown(container.dispose);

    // Keep both alive the way the dashboard does. The orchestrator's own build
    // fails here (no USP client off-web), which is fine: what is under test is
    // the listener it registers first.
    container.listen(appConnectionStateProvider, (_, __) {});
    container.listen(wanDataProvider, (_, __) {});
    orchestratorStates = [];
    container.listen(dashboardOrchestratorProvider,
        (_, next) => orchestratorStates.add(next));
  });

  Future<void> settle() async {
    await pumpEventQueue();
    container.read(wanDataProvider);
    await pumpEventQueue();
  }

  group('DashboardOrchestrator - after a recovery wait', () {
    // The router rebooting (or the link dropping) puts the app in
    // `waitingForRecovery`; the probe brings it back to `authenticated`. Nothing
    // re-read the dashboard's data on that edge, so every card kept showing what
    // it read before the outage.
    test('coming back to authenticated re-fetches the domain providers',
        () async {
      await settle();
      expect(wan.builds, 1);

      connection.move(AppConnectionState.waitingForRecovery);
      await settle();
      expect(wan.builds, 1, reason: 'entering the wait fetches nothing');

      connection.move(AppConnectionState.authenticated);
      await settle();
      expect(wan.builds, 2);
    });

    test('the data is re-read without rebuilding the orchestrator', () async {
      // A rebuild re-runs `_registerSSEAfterDomainReady`, which calls `connect()`
      // whenever the stream is not `connected` — and right after recovery it is
      // not: `connected` is inferred from traffic, and Guardian sends none. That
      // second `connect()` tears down the stream the probe has just opened, while
      // its re-registration walk is putting the subscriptions back.
      await settle();
      orchestratorStates.clear();

      connection.move(AppConnectionState.waitingForRecovery);
      connection.move(AppConnectionState.authenticated);
      await settle();

      expect(wan.builds, 2);
      expect(orchestratorStates, isEmpty);
    });

    test('a fetch that fails straight after recovery is retried', () {
      // The router answers the probe before every service on it is back, so
      // the first reads can 503. Boot covers that with the orchestrator's
      // backoff retry; this path does not rebuild, so it has to start the
      // retry itself.
      fakeAsync((async) {
        final connection = _DrivenConnectionState();
        final wan = _CountingWanDataNotifier();
        final container = ProviderContainer(overrides: [
          appConnectionStateProvider.overrideWith(() => connection),
          wanDataProvider.overrideWith(() => wan),
        ]);
        container.listen(appConnectionStateProvider, (_, __) {});
        container.listen(wanDataProvider, (_, __) {});
        container.listen(dashboardOrchestratorProvider, (_, __) {});
        void settle() {
          async.flushMicrotasks();
          container.read(wanDataProvider);
          async.flushMicrotasks();
        }

        settle();
        connection.move(AppConnectionState.waitingForRecovery);
        connection.move(AppConnectionState.authenticated);
        settle();
        expect(wan.builds, 2);

        async.elapse(const Duration(seconds: 5));
        settle();
        expect(wan.builds, 3, reason: 'still failing at 5s, so re-read');

        container.dispose();
      });
    });

    test('ending in loggedOut does not re-fetch', () async {
      // Factory reset and a changed serial both end the wait this way; there is
      // no session to read with.
      await settle();

      connection.move(AppConnectionState.waitingForRecovery);
      connection.move(AppConnectionState.loggedOut);
      await settle();

      expect(wan.builds, 1);
    });

    test('a re-login (loggedOut → authenticated) is not a recovery', () async {
      // The connection state takes this edge on every re-login, and the
      // orchestrator's auth listener already rebuilds it then. Refreshing here as
      // well would fire every domain fetch twice into a bridge that is just
      // coming up — the 503 burst `_registerSSEAfterDomainReady` waits out.
      await settle();

      connection.move(AppConnectionState.loggedOut);
      await settle();
      connection.move(AppConnectionState.authenticated);
      await settle();

      expect(wan.builds, 1);
    });
  });

  group('DashboardOrchestrator - the MAC filter (#1755)', () {
    // A hardware privacy switch move made while the router is off is applied at
    // boot, and its push goes out before the app is back. Only a re-read after
    // the recovery wait brings the menu's Instant Privacy badge to it.
    test('is re-read after a recovery wait', () async {
      final connection = _DrivenConnectionState();
      final macFilter = _CountingMacFilterDataNotifier();
      final container = ProviderContainer(overrides: [
        appConnectionStateProvider.overrideWith(() => connection),
        macFilterDataProvider.overrideWith(() => macFilter),
      ]);
      addTearDown(container.dispose);
      container.listen(appConnectionStateProvider, (_, __) {});
      container.listen(macFilterDataProvider, (_, __) {});
      container.listen(dashboardOrchestratorProvider, (_, __) {});
      await pumpEventQueue();
      expect(macFilter.builds, 1);

      connection.move(AppConnectionState.waitingForRecovery);
      connection.move(AppConnectionState.authenticated);
      await pumpEventQueue();
      container.read(macFilterDataProvider);
      await pumpEventQueue();

      expect(macFilter.builds, 2);
    });
  });

  group('DashboardOrchestrator - UPnP (#1130)', () {
    // The Firewall card shows UPnP, and the router pushes nothing for it, so
    // only the dashboard's re-reads bring it up to date.
    test('is re-read after a recovery wait', () async {
      final connection = _DrivenConnectionState();
      var upnpReads = 0;
      final container = ProviderContainer(overrides: [
        appConnectionStateProvider.overrideWith(() => connection),
        upnpDataProvider.overrideWith((ref) async {
          upnpReads++;
          return true;
        }),
      ]);
      addTearDown(container.dispose);
      container.listen(appConnectionStateProvider, (_, __) {});
      container.listen(upnpDataProvider, (_, __) {});
      container.listen(dashboardOrchestratorProvider, (_, __) {});
      await pumpEventQueue();
      expect(upnpReads, 1);

      connection.move(AppConnectionState.waitingForRecovery);
      connection.move(AppConnectionState.authenticated);
      await pumpEventQueue();
      container.read(upnpDataProvider);
      await pumpEventQueue();

      expect(upnpReads, 2);
    });
  });

  group('DashboardOrchestrator - IPv6 Port Service rules (#1130)', () {
    // They decide the Firewall card's "nothing opened" sentence, and nothing
    // the app hears is pushed for them.
    test('are re-read after a recovery wait', () async {
      final connection = _DrivenConnectionState();
      var reads = 0;
      final container = ProviderContainer(overrides: [
        appConnectionStateProvider.overrideWith(() => connection),
        ipv6PortServiceDataProvider.overrideWith((ref) async {
          reads++;
          return const [];
        }),
      ]);
      addTearDown(container.dispose);
      container.listen(appConnectionStateProvider, (_, __) {});
      container.listen(ipv6PortServiceDataProvider, (_, __) {});
      container.listen(dashboardOrchestratorProvider, (_, __) {});
      await pumpEventQueue();
      expect(reads, 1);

      connection.move(AppConnectionState.waitingForRecovery);
      connection.move(AppConnectionState.authenticated);
      await pumpEventQueue();
      container.read(ipv6PortServiceDataProvider);
      await pumpEventQueue();

      expect(reads, 2);
    });
  });
}
