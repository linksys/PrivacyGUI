import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_data.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_mode.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_data_provider.dart';
import 'package:privacy_gui/page/mac_filter/services/usp_mac_filter_data_service.dart';

const _disabled = MacFilterData(mode: MacFilterMode.disabled, macs: []);
const _locked =
    MacFilterData(mode: MacFilterMode.allow, macs: ['AA:BB:CC:DD:EE:01']);

class MockUspMacFilterDataService extends Mock
    implements UspMacFilterDataService {}

/// The session-wide MAC filter state the menu's Instant Privacy badge reads
/// (PrivacyGUI#1755): read once, then re-read when the router pushes a change of
/// the mode, which the hardware privacy switch makes as well as a save.
void main() {
  late MockUspMacFilterDataService service;

  setUp(() {
    service = MockUspMacFilterDataService();
    when(() => service.fetch(fresh: any(named: 'fresh')))
        .thenAnswer((_) async => _disabled);
  });

  ProviderContainer createContainer({
    Stream<InvalidationEvent>? sse,
    DeviceCapabilities? capabilities,
  }) {
    return ProviderContainer(overrides: [
      uspMacFilterDataServiceProvider.overrideWithValue(service),
      deviceCapabilitiesProvider.overrideWithValue(capabilities ??
          DeviceCapabilities(const {DeviceCapability.wifiMacFilter})),
      if (sse != null) sseInvalidationProvider.overrideWith((ref) => sse),
    ]);
  }

  group('MacFilterDataNotifier — build', () {
    test('reads the applied mode and list', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      expect(await container.read(macFilterDataProvider.future), _disabled);
      verify(() => service.fetch(fresh: any(named: 'fresh'))).called(1);
    });

    test('the first read may be served from the cache', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(macFilterDataProvider.future);

      verify(() => service.fetch(fresh: false)).called(1);
    });

    // Firmware without the filter has nothing to read, and the orchestrator's
    // retry builds this provider whether or not the menu watches it. No read:
    // no filter is in effect there, so it is Disabled with no list.
    test('without the capability, reads nothing and is Disabled', () async {
      final container = createContainer(capabilities: DeviceCapabilities.empty);
      addTearDown(container.dispose);

      expect(await container.read(macFilterDataProvider.future), _disabled);
      verifyNever(() => service.fetch(fresh: any(named: 'fresh')));
    });

    test('surfaces a failed read as an error', () async {
      when(() => service.fetch(fresh: any(named: 'fresh')))
          .thenThrow(const UnexpectedError(detail: 'read failed'));
      final container = createContainer();
      addTearDown(container.dispose);

      await expectLater(container.read(macFilterDataProvider.future),
          throwsA(isA<UnexpectedError>()));
    });
  });

  group('MacFilterDataNotifier — pushed mode change', () {
    // Read once, with no listener held: a widget that has stopped watching must
    // not stop the push from landing.
    void settle(FakeAsync async, ProviderContainer container) {
      container.read(macFilterDataProvider);
      async.flushMicrotasks();
      expect(container.read(macFilterDataProvider).value, _disabled,
          reason: 'build() must have completed, or nothing is listening');
      clearInteractions(service);
    }

    test('re-reads the filter after the debounce', () {
      fakeAsync((async) {
        final sse = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sse: sse.stream);
        settle(async, container);
        when(() => service.fetch(fresh: any(named: 'fresh')))
            .thenAnswer((_) async => _locked);

        sse.add((domain: InvalidationDomain.macFilter, seq: 0));
        async.elapse(const Duration(milliseconds: 499));
        verifyNever(() => service.fetch(fresh: any(named: 'fresh')));

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        verify(() => service.fetch(fresh: any(named: 'fresh'))).called(1);
        expect(container.read(macFilterDataProvider).value, _locked);

        sse.close();
        container.dispose();
      });
    });

    test('a burst inside the window reads once', () {
      fakeAsync((async) {
        final sse = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sse: sse.stream);
        settle(async, container);

        for (var i = 0; i < 3; i++) {
          sse.add((domain: InvalidationDomain.macFilter, seq: i));
          async.elapse(const Duration(milliseconds: 100));
        }
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        verify(() => service.fetch(fresh: any(named: 'fresh'))).called(1);

        sse.close();
        container.dispose();
      });
    });

    test('a failed re-read keeps the value it had', () {
      fakeAsync((async) {
        final sse = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sse: sse.stream);
        settle(async, container);
        when(() => service.fetch(fresh: any(named: 'fresh')))
            .thenThrow(const UnexpectedError(detail: 'read failed'));

        sse.add((domain: InvalidationDomain.macFilter, seq: 0));
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        final state = container.read(macFilterDataProvider);
        expect(state.hasError, isFalse,
            reason: 'a push is a hint to re-read, not a reason to lose the '
                'mode the badge already shows');
        expect(state.value, _disabled);

        sse.close();
        container.dispose();
      });
    });

    // The switch moves to Lock, and its push starts a slow read; the user then
    // turns Instant Privacy off and saves, which rebuilds this provider. The
    // rebuild read is the newer one, so the push landing after it must not win.
    test('a save-triggered rebuild wins over a push already in flight',
        () async {
      final pushGate = Completer<MacFilterData>();
      var call = 0;
      when(() => service.fetch(fresh: any(named: 'fresh'))).thenAnswer((_) {
        call++;
        if (call == 1) return Future.value(_disabled);
        return call == 2 ? pushGate.future : Future.value(_disabled);
      });
      final sse = StreamController<InvalidationEvent>.broadcast();
      final container = createContainer(sse: sse.stream);
      addTearDown(container.dispose);
      addTearDown(sse.close);
      container.listen(macFilterDataProvider, (_, __) {});
      await container.read(macFilterDataProvider.future);

      sse.add((domain: InvalidationDomain.macFilter, seq: 0));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(call, 2, reason: 'the push read must be in flight');

      container.invalidate(macFilterDataProvider);
      await container.read(macFilterDataProvider.future);
      expect(call, 3, reason: 'the rebuild must have read on its own');

      pushGate.complete(_locked);
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(container.read(macFilterDataProvider).value, _disabled);
    });

    // Lock, then Unlock two seconds later: both re-reads fall inside the
    // throttler's 5 s cache window. Each must reach the router, or the second
    // replays the first and the badge stays On.
    test('two pushes inside the cache window each read the router', () {
      fakeAsync((async) {
        final sse = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sse: sse.stream);
        settle(async, container);

        when(() => service.fetch(fresh: any(named: 'fresh')))
            .thenAnswer((_) async => _locked);
        sse.add((domain: InvalidationDomain.macFilter, seq: 0));
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();
        expect(container.read(macFilterDataProvider).value, _locked);

        async.elapse(const Duration(milliseconds: 1500));
        when(() => service.fetch(fresh: any(named: 'fresh')))
            .thenAnswer((_) async => _disabled);
        sse.add((domain: InvalidationDomain.macFilter, seq: 1));
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        expect(container.read(macFilterDataProvider).value, _disabled);
        verify(() => service.fetch(fresh: true)).called(2);

        sse.close();
        container.dispose();
      });
    });

    test('another domain does not re-read', () {
      fakeAsync((async) {
        final sse = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sse: sse.stream);
        settle(async, container);

        sse.add((domain: InvalidationDomain.connectedDevices, seq: 0));
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        verifyNever(() => service.fetch(fresh: any(named: 'fresh')));

        sse.close();
        container.dispose();
      });
    });
  });
}
