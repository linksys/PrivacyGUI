import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/ddns/models/ddns_update_status.dart';
import 'package:privacy_gui/page/ddns/providers/ddns_status_data_provider.dart';
import 'package:privacy_gui/page/ddns/services/usp_ddns_status_data_service.dart';

class MockUspDdnsStatusDataService extends Mock
    implements UspDdnsStatusDataService {}

/// The DDNS update status the page's status card reads (PrivacyGUI#641): read
/// once, then re-read when the router pushes a change of the client, which it
/// makes on its own as an update runs.
void main() {
  late MockUspDdnsStatusDataService service;

  setUp(() {
    service = MockUspDdnsStatusDataService();
    when(() => service.fetch(fresh: any(named: 'fresh')))
        .thenAnswer((_) async => DdnsUpdateStatus.connecting);
  });

  ProviderContainer createContainer({Stream<InvalidationEvent>? sse}) {
    return ProviderContainer(overrides: [
      uspDdnsStatusDataServiceProvider.overrideWithValue(service),
      if (sse != null) sseInvalidationProvider.overrideWith((ref) => sse),
    ]);
  }

  group('DdnsStatusDataNotifier - build', () {
    test('reads the status, from the cache if it has one', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      expect(await container.read(ddnsStatusDataProvider.future),
          DdnsUpdateStatus.connecting);
      verify(() => service.fetch(fresh: false)).called(1);
    });

    test('surfaces a failed read as an error', () async {
      when(() => service.fetch(fresh: any(named: 'fresh')))
          .thenThrow(const NetworkError(detail: 'read failed'));
      final container = createContainer();
      addTearDown(container.dispose);

      await expectLater(container.read(ddnsStatusDataProvider.future),
          throwsA(isA<NetworkError>()));
    });
  });

  group('DdnsStatusDataNotifier - pushed change', () {
    // Read once, with no listener held: a page that has stopped watching must
    // not stop the push from landing (#1615).
    void settle(FakeAsync async, ProviderContainer container) {
      container.read(ddnsStatusDataProvider);
      async.flushMicrotasks();
      expect(container.read(ddnsStatusDataProvider).value,
          DdnsUpdateStatus.connecting,
          reason: 'build() must have completed, or nothing is listening');
      clearInteractions(service);
    }

    test('re-reads fresh after the debounce', () {
      fakeAsync((async) {
        final sse = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sse: sse.stream);
        settle(async, container);
        when(() => service.fetch(fresh: any(named: 'fresh')))
            .thenAnswer((_) async => DdnsUpdateStatus.success);

        sse.add((domain: InvalidationDomain.dynamicDns, seq: 0));
        async.elapse(const Duration(milliseconds: 499));
        verifyNever(() => service.fetch(fresh: any(named: 'fresh')));

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        verify(() => service.fetch(fresh: true)).called(1);
        expect(container.read(ddnsStatusDataProvider).value,
            DdnsUpdateStatus.success);

        sse.close();
        container.dispose();
      });
    });

    test('the burst of one update reads once', () {
      fakeAsync((async) {
        final sse = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sse: sse.stream);
        settle(async, container);

        // Status, LastError, the host name's Status and LastUpdate.
        for (var seq = 0; seq < 4; seq++) {
          sse.add((domain: InvalidationDomain.dynamicDns, seq: seq));
          async.elapse(const Duration(milliseconds: 100));
        }
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        verify(() => service.fetch(fresh: any(named: 'fresh'))).called(1);

        sse.close();
        container.dispose();
      });
    });

    test('another domain is ignored', () {
      fakeAsync((async) {
        final sse = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sse: sse.stream);
        settle(async, container);

        sse.add((domain: InvalidationDomain.wanStatus, seq: 0));
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        verifyNever(() => service.fetch(fresh: any(named: 'fresh')));

        sse.close();
        container.dispose();
      });
    });

    test('a failed pushed read keeps the value it had', () {
      fakeAsync((async) {
        final sse = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sse: sse.stream);
        settle(async, container);
        when(() => service.fetch(fresh: any(named: 'fresh')))
            .thenThrow(const NetworkError(detail: 'read failed'));

        sse.add((domain: InvalidationDomain.dynamicDns, seq: 0));
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        final value = container.read(ddnsStatusDataProvider);
        expect(value.hasError, isFalse);
        expect(value.value, DdnsUpdateStatus.connecting);

        sse.close();
        container.dispose();
      });
    });

    test('a rebuild discards a pushed read that finishes after it', () {
      fakeAsync((async) {
        final sse = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sse: sse.stream);
        container.listen(ddnsStatusDataProvider, (_, __) {});
        settle(async, container);

        final slow = Completer<DdnsUpdateStatus>();
        when(() => service.fetch(fresh: true)).thenAnswer((_) => slow.future);
        when(() => service.fetch(fresh: false))
            .thenAnswer((_) async => DdnsUpdateStatus.success);

        sse.add((domain: InvalidationDomain.dynamicDns, seq: 0));
        async.elapse(const Duration(milliseconds: 500));
        // The page re-reads while the pushed read is still out. Reading right
        // after the invalidation rebuilds now rather than on the scheduler.
        container.invalidate(ddnsStatusDataProvider);
        container.read(ddnsStatusDataProvider);
        async.flushMicrotasks();
        expect(container.read(ddnsStatusDataProvider).value,
            DdnsUpdateStatus.success);

        slow.complete(DdnsUpdateStatus.authenticationFailed);
        async.flushMicrotasks();
        expect(container.read(ddnsStatusDataProvider).value,
            DdnsUpdateStatus.success,
            reason: 'the older read must not overwrite the newer one');

        sse.close();
        container.dispose();
      });
    });
  });

  group('DdnsStatusDataNotifier - refresh', () {
    test('a refresh that lands during a rebuild is not overwritten by it',
        () async {
      final container = createContainer();
      addTearDown(container.dispose);
      container.listen(ddnsStatusDataProvider, (_, __) {});
      await container.read(ddnsStatusDataProvider.future);

      // The rebuild's read answers late with the older value.
      final slowBuild = Completer<DdnsUpdateStatus>();
      when(() => service.fetch(fresh: false))
          .thenAnswer((_) => slowBuild.future);
      when(() => service.fetch(fresh: true))
          .thenAnswer((_) async => DdnsUpdateStatus.success);
      container.invalidate(ddnsStatusDataProvider);
      container.read(ddnsStatusDataProvider);

      await container.read(ddnsStatusDataProvider.notifier).refresh();
      slowBuild.complete(DdnsUpdateStatus.connecting);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(ddnsStatusDataProvider).value,
          DdnsUpdateStatus.success);
    });

    test('reads fresh and publishes the result', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(ddnsStatusDataProvider.future);
      when(() => service.fetch(fresh: true))
          .thenAnswer((_) async => DdnsUpdateStatus.authenticationFailed);

      await container.read(ddnsStatusDataProvider.notifier).refresh();

      expect(container.read(ddnsStatusDataProvider).value,
          DdnsUpdateStatus.authenticationFailed);
    });

    test('a failed refresh keeps the value and throws for the caller',
        () async {
      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(ddnsStatusDataProvider.future);
      when(() => service.fetch(fresh: true))
          .thenThrow(const NetworkError(detail: 'read failed'));

      await expectLater(
        container.read(ddnsStatusDataProvider.notifier).refresh(),
        throwsA(isA<NetworkError>()),
      );
      expect(container.read(ddnsStatusDataProvider).value,
          DdnsUpdateStatus.connecting);
    });
  });
}
