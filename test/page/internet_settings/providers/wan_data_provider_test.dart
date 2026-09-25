import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_wan_data_service.dart';

class MockUspClient extends Mock implements UspClient {}

/// A service-level mock, used only by the ordering group at the bottom of this file: those
/// tests need to control which of two overlapping fetches COMPLETES first, and the
/// `UspClient` mock the rest of the file uses cannot express that — one `get` stub serves
/// every round trip.
class MockWanSvc extends Mock implements UspWanDataService {}

void main() {
  late MockUspClient mockUsp;

  /// Simulated WAN status response (Device.IP.Interface.2.*).
  /// Includes IPv6Enable since WanStatus codegen v1.1.0 fetches it.
  final wanStatusResponse = <String, dynamic>{
    'Device.IP.Interface.2.Status': 'Up',
    'Device.IP.Interface.2.IPv4Address.1.IPAddress': '100.64.0.10',
    'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '255.255.255.0',
    'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'DHCP',
    'Device.IP.Interface.2.MaxMTUSize': '1500',
    'Device.IP.Interface.2.IPv6Enable': true,
  };

  /// Simulated routing table response for gateway lookup.
  /// StaticRouting validation requires all fields for each route instance.
  final routingResponse = <String, dynamic>{
    // Default route (0.0.0.0) on WAN interface
    'Device.Routing.Router.1.IPv4Forwarding.1.Enable': true,
    'Device.Routing.Router.1.IPv4Forwarding.1.DestIPAddress': '0.0.0.0',
    'Device.Routing.Router.1.IPv4Forwarding.1.DestSubnetMask': '0.0.0.0',
    'Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress': '100.64.0.1',
    'Device.Routing.Router.1.IPv4Forwarding.1.Interface':
        'Device.IP.Interface.2.',
    'Device.Routing.Router.1.IPv4Forwarding.1.Origin': 'Static',
    'Device.Routing.Router.1.IPv4Forwarding.1.Alias': 'DefaultRoute',
    // LAN route
    'Device.Routing.Router.1.IPv4Forwarding.2.Enable': true,
    'Device.Routing.Router.1.IPv4Forwarding.2.DestIPAddress': '192.168.1.0',
    'Device.Routing.Router.1.IPv4Forwarding.2.DestSubnetMask': '255.255.255.0',
    'Device.Routing.Router.1.IPv4Forwarding.2.GatewayIPAddress': '0.0.0.0',
    'Device.Routing.Router.1.IPv4Forwarding.2.Interface':
        'Device.IP.Interface.1.',
    'Device.Routing.Router.1.IPv4Forwarding.2.Origin': 'Static',
    'Device.Routing.Router.1.IPv4Forwarding.2.Alias': 'LanRoute',
  };

  /// Simulated IPv6 response.
  final ipv6Response = <String, dynamic>{
    'Device.IP.Interface.2.IPv6Enable': true,
    'Device.IP.Interface.2.IPv6Address.1.IPAddress': '2001:db8::1',
    'Device.IP.Interface.2.IPv6Address.2.IPAddress': 'fe80::1',
  };

  setUp(() {
    mockUsp = MockUspClient();

    // Route usp.get() calls by path content.
    //
    // Service issues requests in parallel:
    //   1. WanStatus.fetch  → Device.IP.Interface.2.Status, IPv6Enable, etc.
    //   2. StaticRouting.fetch → Device.Routing.Router.1.IPv4Forwarding.*
    //   3. WanIpv6Addresses.fetch → Device.IP.Interface.2.IPv6Address.*
    //
    // Distinguish by path patterns.
    when(() => mockUsp.get(any())).thenAnswer((invocation) async {
      final paths = invocation.positionalArguments[0] as List;
      final joined = paths.join(',');

      if (joined.contains('IPv4Forwarding')) {
        // StaticRouting.fetch
        return routingResponse;
      }
      if (joined.contains('IPv6Address')) {
        // WanIpv6Addresses.fetch
        return ipv6Response;
      }
      // WanStatus.fetch (includes IPv6Enable in its paths)
      return wanStatusResponse;
    });
  });

  ProviderContainer createContainer({Stream<InvalidationEvent>? sse}) {
    final container = ProviderContainer(
      overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        if (sse != null) sseInvalidationProvider.overrideWith((_) => sse),
      ],
    );
    container.listen(wanDataProvider, (_, __) {});
    return container;
  }

  group('WanDataNotifier', () {
    // -----------------------------------------------------------------------
    // build / fetch
    // -----------------------------------------------------------------------

    test('fetch builds WanData with IP, status, and gateway', () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final data = container.read(wanDataProvider).requireValue;

      expect(data.model.ipAddress, '100.64.0.10');
      expect(data.model.isUp, isTrue);
      expect(data.model.gateway, '100.64.0.1');
      expect(data.model.subnetMask, '255.255.255.0');
      expect(data.model.mtu, 1500);
      container.dispose();
    });

    test('fetch includes IPv6 addresses when available', () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final data = container.read(wanDataProvider).requireValue;

      expect(data.model.ipv6Enabled, isTrue);
      expect(data.model.ipv6Addresses, contains('2001:db8::1'));
      container.dispose();
    });

    test('fetch sets error state when USP service unavailable', () async {
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(null),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        ],
      );
      container.listen(wanDataProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      final state = container.read(wanDataProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<ServiceNotInitializedError>());
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Gateway lookup
    // -----------------------------------------------------------------------

    test(
        'gateway found from default route (DestIPAddress 0.0.0.0 on Interface.2)',
        () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final data = container.read(wanDataProvider).requireValue;
      expect(data.model.gateway, '100.64.0.1');
      container.dispose();
    });

    test('gateway empty when no default route matches', () async {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List;
        final joined = paths.join(',');

        if (joined.contains('IPv4Forwarding')) {
          // No route with DestIP 0.0.0.0 on Interface.2
          return <String, dynamic>{
            'Device.Routing.Router.1.IPv4Forwarding.1.Enable': true,
            'Device.Routing.Router.1.IPv4Forwarding.1.DestIPAddress':
                '192.168.1.0',
            'Device.Routing.Router.1.IPv4Forwarding.1.DestSubnetMask':
                '255.255.255.0',
            'Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress':
                '0.0.0.0',
            'Device.Routing.Router.1.IPv4Forwarding.1.Interface':
                'Device.IP.Interface.1.',
            'Device.Routing.Router.1.IPv4Forwarding.1.Origin': 'Static',
            'Device.Routing.Router.1.IPv4Forwarding.1.Alias': 'LanRoute',
            ...ipv6Response,
          };
        }
        return wanStatusResponse;
      });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final data = container.read(wanDataProvider).requireValue;
      expect(data.model.gateway, isEmpty);
      container.dispose();
    });

    test('gateway gracefully handles fetch failure', () async {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List;
        final joined = paths.join(',');

        if (joined.contains('IPv4Forwarding')) {
          throw Exception('timeout');
        }
        return wanStatusResponse;
      });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final data = container.read(wanDataProvider).requireValue;
      // Gateway falls back to empty string, rest of data still loads
      expect(data.model.gateway, isEmpty);
      expect(data.model.ipAddress, '100.64.0.10');
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // IPv6 fallback
    // -----------------------------------------------------------------------

    test('IPv6 gracefully handles fetch failure', () async {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List;
        final joined = paths.join(',');

        // The combined gateway+IPv6 call fails entirely — both gateway and
        // IPv6 fall back to empty.
        if (joined.contains('IPv4Forwarding')) {
          throw Exception('not supported');
        }
        return wanStatusResponse;
      });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final data = container.read(wanDataProvider).requireValue;
      // ipv6Enabled comes from WanStatus.fetch (succeeds), addresses from
      // the combined call (fails) — graceful degradation.
      expect(data.model.ipv6Enabled, isTrue);
      expect(data.model.ipv6Addresses, isEmpty);
      // Core WAN data still loads
      expect(data.model.ipAddress, '100.64.0.10');
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // WanData equality
    // -----------------------------------------------------------------------

    test('WanData equality uses model props', () {
      const a = WanData(
        model: WanStatusUIModel(
          isUp: true,
          ipAddress: '1.2.3.4',
          subnetMask: '255.255.255.0',
          addressingType: 'DHCP',
          mtu: 1500,
          gateway: '1.2.3.1',
        ),
      );
      const b = WanData(
        model: WanStatusUIModel(
          isUp: true,
          ipAddress: '1.2.3.4',
          subnetMask: '255.255.255.0',
          addressingType: 'DHCP',
          mtu: 1500,
          gateway: '1.2.3.1',
        ),
      );
      expect(a, equals(b));
    });
  });

  // -------------------------------------------------------------------------
  // SSE invalidation (#1501)
  //
  // `sseInvalidationProvider` emits `({InvalidationDomain domain, int seq})`.
  // This notifier reads `.domain` and ignores `seq`, whose only job is to keep
  // two consecutive events for the *same* domain unequal — without it,
  // riverpod 3.x's `==`-based `updateShouldNotify` collapses the second one and
  // the repeat below stops re-fetching. So the repeat is the assertion that
  // pins the tag end-to-end at the consumer, not just at the producer.
  // -------------------------------------------------------------------------
  group('WanDataNotifier SSE invalidation', () {
    /// Drains enough microtasks for an SSE event to travel
    /// stream -> provider state -> `ref.listen` -> `invalidateSelf()` ->
    /// rebuild -> `_fetch()`. Awaiting `provider.future` instead does NOT work:
    /// it resolves against the future that is already complete, before the
    /// event has propagated at all.
    ///
    /// Both tests below drain the same amount so the negative one cannot pass
    /// merely by looking earlier than the positive one.
    ///
    /// Measured: 2 hops is the minimum that passes here, 1 fails. 4 is
    /// deliberate margin — an extra hop on a chain that has already settled is
    /// free, whereas one too few reads as "the listener is broken".
    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await Future.delayed(Duration.zero);
      }
    }

    /// Number of *fetch rounds* since the last verification, counted by the one
    /// request per round that carries the WanStatus paths. Counting raw
    /// `get` calls instead would couple the assertion to how many parallel
    /// requests the service happens to issue.
    ///
    /// `verify` marks the calls it matched as verified, so consecutive calls
    /// return the delta rather than a running total.
    int fetchRounds() => verify(() => mockUsp.get(captureAny()))
        .captured
        .cast<List>()
        .where(
            (paths) => paths.join(',').contains('Device.IP.Interface.2.Status'))
        .length;

    test('wanStatus domain re-fetches, and a repeat re-fetches again',
        () async {
      final sse = StreamController<InvalidationEvent>();
      final container = createContainer(sse: sse.stream);
      await Future.delayed(Duration.zero);

      // Drop the build() fetch so the counting below starts from zero.
      clearInteractions(mockUsp);

      sse.add((domain: InvalidationDomain.wanStatus, seq: 0));
      await settle();
      expect(fetchRounds(), 1);

      // Same domain again — e.g. the link drops and comes back, or the lease
      // renews with a new address. `seq` is the only thing that differs.
      sse.add((domain: InvalidationDomain.wanStatus, seq: 1));
      await settle();
      expect(fetchRounds(), 1,
          reason: 'the second wanStatus event must re-fetch too; collapsing it '
              'leaves the UI showing the pre-drop WAN address');

      await sse.close();
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // linksys/PrivacyGUI#1615 — does the re-fetch survive WITHOUT a listener?
    //
    // The test above passes, yet on FW 2.0 this same path does not re-fetch on real
    // hardware. `createContainer()` differs from production in one way that matters:
    // it calls `container.listen(wanDataProvider, …)`, holding a subscriber for the
    // whole test. `invalidateSelf()` only SCHEDULES a rebuild — riverpod runs `build()`
    // again when something READS the provider, and that listener guarantees something
    // does.
    //
    // So the passing test cannot tell "invalidateSelf() re-fetches" apart from
    // "invalidateSelf() re-fetches BECAUSE a listener was held". This one removes the
    // listener and asks the narrower question. If it fails, hypothesis A in #1615 is
    // confirmed: the defect is the pattern, not the library.
    //
    // The provider is read once up front so the notifier is constructed and its
    // `ref.listen` registered — without that there is nothing to invalidate and the
    // test would be vacuous. A one-shot `read` rather than a `listen` is deliberately
    // what a widget that has since stopped watching looks like.
    // -----------------------------------------------------------------------
    test('#1615: wanStatus re-fetches with NO listener held on the provider',
        () async {
      final sse = StreamController<InvalidationEvent>();
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(mockUsp),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          sseInvalidationProvider.overrideWith((_) => sse.stream),
        ],
      );
      // `await …future` rather than a bare `read`: reading an AsyncNotifierProvider
      // returns the current AsyncValue without waiting for build() to finish, and the
      // fetch inside it needs more than a few microtasks. Awaiting the future is what
      // guarantees build() — and therefore its ref.listen — has actually run.
      final d = await container.read(wanDataProvider.future);
      // Proves build() ran and fetched — the ref.listen inside it is therefore
      // registered, so the event below has something to invalidate. Asserting on the
      // VALUE rather than on a verify() count, because `fetchRounds()` uses
      // `verify(…)`, and mocktail's verify CONSUMES the calls it matches: calling it
      // here would leave nothing for the assertion that matters.
      expect(d.model.ipAddress, '100.64.0.10',
          reason: 'build() must have completed, or this test asserts nothing');

      clearInteractions(mockUsp);

      sse.add((domain: InvalidationDomain.wanStatus, seq: 0));
      await settle();

      expect(
        fetchRounds(),
        1,
        reason:
            'a push-triggered refresh must re-read the device even when nothing is '
            'listening. A zero here means the notifier is back to depending on a '
            'subscriber — which production does not guarantee, and which also stops the '
            'ref.listen from being re-registered, disabling the mechanism entirely. '
            'See #1615.',
      );

      await sse.close();
      container.dispose();
    });

    test('a neighbouring domain does not re-fetch', () async {
      final sse = StreamController<InvalidationEvent>();
      final container = createContainer(sse: sse.stream);
      await Future.delayed(Duration.zero);
      clearInteractions(mockUsp);

      // staticRouting is the plausible-but-wrong neighbour: _fetch() reads the
      // routing table to resolve the gateway, so a route change looks relevant
      // — but the listener is scoped to wanStatus and must ignore it.
      sse.add((domain: InvalidationDomain.staticRouting, seq: 0));
      await settle();

      verifyNever(() => mockUsp.get(any()));

      await sse.close();
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // Ordering — linksys/PrivacyGUI#1615, found while reviewing the fix itself.
  //
  // Replacing `invalidateSelf()` with a direct `state` assignment removed a guarantee
  // nobody had written down: riverpod COALESCES invalidations. Measured — two
  // `invalidateSelf()` calls inside one fetch window produce ONE rebuild, whereas two
  // bare `async` calls run two overlapping fetches with last-COMPLETION-wins semantics.
  //
  // Reachable because `_fetch()` fans out over several USP `get`s through a throttler
  // against a single-threaded OBUSPA, so the window is wide. And it does not self-correct:
  // the provider is push-driven only, so a wrong value survives until the next
  // notification — on a settled WAN, possibly never.
  // ---------------------------------------------------------------------------
  group('WanDataNotifier — overlapping push refreshes', () {
    late MockWanSvc svc;

    WanStatusUIModel model({required bool isUp, required String ip}) =>
        WanStatusUIModel(
          isUp: isUp,
          ipAddress: ip,
          subnetMask: '255.255.255.0',
          addressingType: 'DHCP',
          mtu: 1500,
        );

    setUp(() => svc = MockWanSvc());

    ProviderContainer makeContainer(Stream<InvalidationEvent> sse) =>
        ProviderContainer(overrides: [
          uspWanDataServiceProvider.overrideWithValue(svc),
          sseInvalidationProvider.overrideWith((_) => sse),
        ]);

    Future<void> tick() => Future<void>.delayed(Duration.zero);

    test('the LATER push wins even when its fetch completes FIRST', () async {
      // The full scenario: the link goes down, then returns before the first read has
      // finished. The device's newer answer (up) arrives first and the older answer
      // (down) arrives second — which must be discarded, not published.
      final slowDown = Completer<WanStatusUIModel>();
      final fastUp = Completer<WanStatusUIModel>();
      var call = 0;
      when(() => svc.fetch()).thenAnswer((_) {
        call++;
        if (call == 1) return Future.value(model(isUp: true, ip: '100.64.0.1'));
        if (call == 2) return slowDown.future;
        return fastUp.future;
      });

      final sse = StreamController<InvalidationEvent>.broadcast();
      final c = makeContainer(sse.stream);
      c.listen(wanDataProvider, (_, __) {});
      await c.read(wanDataProvider.future);

      sse.add((domain: InvalidationDomain.wanStatus, seq: 1));
      await tick();
      sse.add((domain: InvalidationDomain.wanStatus, seq: 2));
      await tick();
      expect(call, 3,
          reason:
              'both refreshes must be in flight, or this test proves nothing');

      fastUp.complete(model(isUp: true, ip: '100.64.0.9'));
      await tick();
      slowDown.complete(model(isUp: false, ip: ''));
      await tick();

      final end = c.read(wanDataProvider).valueOrNull!.model;
      expect(end.isUp, isTrue,
          reason:
              'the older read completed last and must have been discarded — otherwise the '
              'dashboard reports a dead link until the next notification, which on a '
              'settled WAN may never arrive');
      expect(end.ipAddress, '100.64.0.9');

      await sse.close();
      c.dispose();
    });

    test('a single push still publishes — the guard is not simply blocking',
        () async {
      // The mirror of the test above: a generation check that rejected everything would
      // also satisfy it, and would reintroduce #1615 itself.
      when(() => svc.fetch())
          .thenAnswer((_) async => model(isUp: true, ip: '100.64.0.2'));

      final sse = StreamController<InvalidationEvent>.broadcast();
      final c = makeContainer(sse.stream);
      c.listen(wanDataProvider, (_, __) {});
      await c.read(wanDataProvider.future);

      when(() => svc.fetch())
          .thenAnswer((_) async => model(isUp: false, ip: ''));
      sse.add((domain: InvalidationDomain.wanStatus, seq: 1));
      await tick();
      await tick();

      expect(c.read(wanDataProvider).valueOrNull!.model.isUp, isFalse,
          reason: 'one push in flight is the newest, so it must publish');

      await sse.close();
      c.dispose();
    });

    test('a save-triggered rebuild wins over a push that was already in flight',
        () async {
      // The other way a value reaches `state`: `build()` returns it directly, bypassing
      // `_refreshFromPush` and its guard. Without bumping the counter in `build()` too, a
      // push that started before a WAN save completes afterwards and republishes pre-save
      // data — on this provider that is the address the user just changed, right after they
      // changed it. Save paths: `usp_internet_settings_notifier.dart`'s `ref.invalidate`
      // after a WAN save and after a DHCP renew.
      final pushGate = Completer<WanStatusUIModel>();
      final rebuildGate = Completer<WanStatusUIModel>();
      var call = 0;
      when(() => svc.fetch()).thenAnswer((_) {
        call++;
        if (call == 1) return Future.value(model(isUp: true, ip: '100.64.0.1'));
        return call == 2 ? pushGate.future : rebuildGate.future;
      });

      final sse = StreamController<InvalidationEvent>.broadcast();
      final c = makeContainer(sse.stream);
      c.listen(wanDataProvider, (_, __) {});
      await c.read(wanDataProvider.future);

      sse.add((domain: InvalidationDomain.wanStatus, seq: 1));
      await tick();
      expect(call, 2,
          reason: 'the push must be in flight, or this test proves nothing');

      // The user saves.
      c.invalidate(wanDataProvider);
      await tick();
      expect(call, 3, reason: 'the rebuild must have started its own fetch');

      // Post-save rebuild completes first, with the NEW address.
      rebuildGate.complete(model(isUp: true, ip: '100.64.0.77'));
      await tick();
      await tick();
      // Then the stale push completes, carrying the OLD one.
      pushGate.complete(model(isUp: true, ip: '100.64.0.1'));
      await tick();
      await tick();

      expect(
          c.read(wanDataProvider).valueOrNull!.model.ipAddress, '100.64.0.77',
          reason:
              'the rebuild published after the push started, so the push is stale — '
              'otherwise the user saves an address and watches it revert');

      await sse.close();
      c.dispose();
    });

    test('a failed push keeps the previous value and does not block later ones',
        () async {
      // The failure path the review noted had no test, asserting two things: the previous
      // value survives, AND the failed attempt does not leave the generation counter in a
      // state that discards the next success.
      when(() => svc.fetch())
          .thenAnswer((_) async => model(isUp: true, ip: '100.64.0.3'));

      final sse = StreamController<InvalidationEvent>.broadcast();
      final c = makeContainer(sse.stream);
      c.listen(wanDataProvider, (_, __) {});
      await c.read(wanDataProvider.future);

      when(() => svc.fetch()).thenThrow(
          const ServiceNotInitializedError(detail: 'transport gone'));
      sse.add((domain: InvalidationDomain.wanStatus, seq: 1));
      await tick();
      await tick();

      final afterFailure = c.read(wanDataProvider);
      expect(afterFailure.hasError, isFalse,
          reason:
              'a push failure must not surface as AsyncError — consumers read through '
              'valueOrNull, so that would render as "unknown"');
      expect(afterFailure.valueOrNull!.model.ipAddress, '100.64.0.3',
          reason: 'the previous value must survive');

      when(() => svc.fetch())
          .thenAnswer((_) async => model(isUp: true, ip: '100.64.0.4'));
      sse.add((domain: InvalidationDomain.wanStatus, seq: 2));
      await tick();
      await tick();

      expect(c.read(wanDataProvider).valueOrNull!.model.ipAddress, '100.64.0.4',
          reason:
              'a later push must still be able to publish after a failed one');

      await sse.close();
      c.dispose();
    });
  });
}
