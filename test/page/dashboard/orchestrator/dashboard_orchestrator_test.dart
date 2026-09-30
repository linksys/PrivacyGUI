import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/page/dashboard/orchestrator/dashboard_orchestrator.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';

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
}
