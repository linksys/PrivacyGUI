import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/dashboard/models/cgi_call_result.dart';
import 'package:privacy_gui/page/dashboard/models/package_widget_template.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_live_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_data_provider.dart';
import 'package:privacy_gui/page/dashboard/services/package_widget_service.dart';
import 'package:ui_kit_library/ui_kit.dart'
    show HeightStrategy, WidgetGridConstraints;

class MockPackageWidgetService extends Mock implements PackageWidgetService {}

final _constraints = WidgetGridConstraints(
  minColumns: 3,
  maxColumns: 6,
  preferredColumns: 4,
  heightStrategy: HeightStrategy.strict(2),
);

PackageWidgetTemplate _uspTemplate({String widgetId = 'w_usp'}) =>
    PackageWidgetTemplate(
      widgetId: widgetId,
      displayName: 'USP widget',
      constraints: _constraints,
      subscription: const WidgetSubscriptionConfig(
        paths: ['Device.DeviceInfo.'],
        notifType: 'ValueChange',
      ),
      template: const {'type': 'AppText'},
    );

void main() {
  late MockPackageWidgetService service;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(<String>[]);
    registerFallbackValue(
        const WidgetSubscriptionConfig(paths: [], notifType: 'ValueChange'));
    registerFallbackValue(const HttpDataSourceConfig(url: '', mapping: {}));
    void onValueChange(String path, Object? value) {}
    registerFallbackValue(onValueChange);
  });

  setUp(() {
    service = MockPackageWidgetService();
    container = ProviderContainer(overrides: [
      packageWidgetServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);
  });

  /// Keeps the autoDispose live notifier alive, as a mounted card does.
  ProviderSubscription<bool> mount(PackageWidgetTemplate template) =>
      container.listen(packageWidgetLiveProvider(template), (_, __) {});

  group('USP data source', () {
    test('the initial GET lands in the data cache and ends the initial fetch',
        () async {
      when(() => service.fetchUspPaths(['Device.DeviceInfo.']))
          .thenAnswer((_) async => {'Device.DeviceInfo.ModelName': 'M60TB'});
      when(() => service.subscribeValueChanges(
            widgetId: any(named: 'widgetId'),
            subscription: any(named: 'subscription'),
            onValueChange: any(named: 'onValueChange'),
          )).thenAnswer((_) async => () async {});
      final template = _uspTemplate();

      final card = mount(template);
      expect(card.read(), isFalse, reason: 'the initial fetch has not run');
      await container.pump();
      await pumpEventQueue();

      expect(container.read(packageWidgetDataProvider('w_usp')),
          {'Device.DeviceInfo.ModelName': 'M60TB'});
      expect(card.read(), isTrue);
    });

    test('an SSE value change patches the data cache', () async {
      late void Function(String, Object?) onValueChange;
      when(() => service.fetchUspPaths(any())).thenAnswer((_) async => {
            'Device.DeviceInfo.ModelName': 'M60TB',
            'Device.DeviceInfo.UpTime': 10,
          });
      when(() => service.subscribeValueChanges(
            widgetId: 'w_usp',
            subscription: _uspTemplate().subscription!,
            onValueChange: any(named: 'onValueChange'),
          )).thenAnswer((invocation) async {
        onValueChange = invocation.namedArguments[#onValueChange] as void
            Function(String, Object?);
        return () async {};
      });

      mount(_uspTemplate());
      await container.pump();
      await pumpEventQueue();
      onValueChange('Device.DeviceInfo.UpTime', 11);

      expect(container.read(packageWidgetDataProvider('w_usp')), {
        'Device.DeviceInfo.ModelName': 'M60TB',
        'Device.DeviceInfo.UpTime': 11,
      });
    });

    test('a failed GET still subscribes and still ends the initial fetch',
        () async {
      when(() => service.fetchUspPaths(any()))
          .thenAnswer((_) async => throw const NetworkError());
      when(() => service.subscribeValueChanges(
            widgetId: any(named: 'widgetId'),
            subscription: any(named: 'subscription'),
            onValueChange: any(named: 'onValueChange'),
          )).thenAnswer((_) async => () async {});

      final card = mount(_uspTemplate());
      await container.pump();
      await pumpEventQueue();

      verify(() => service.subscribeValueChanges(
            widgetId: 'w_usp',
            subscription: any(named: 'subscription'),
            onValueChange: any(named: 'onValueChange'),
          )).called(1);
      expect(card.read(), isTrue);
      expect(container.read(packageWidgetDataProvider('w_usp')), isEmpty);
    });

    test('leaving the dashboard removes the subscription and keeps the data',
        () async {
      var cleanups = 0;
      when(() => service.fetchUspPaths(any()))
          .thenAnswer((_) async => {'Device.DeviceInfo.ModelName': 'M60TB'});
      when(() => service.subscribeValueChanges(
            widgetId: any(named: 'widgetId'),
            subscription: any(named: 'subscription'),
            onValueChange: any(named: 'onValueChange'),
          )).thenAnswer((_) async => () async => cleanups++);

      final card = mount(_uspTemplate());
      await container.pump();
      await pumpEventQueue();
      card.close();
      await container.pump();

      expect(cleanups, 1);
      expect(container.read(packageWidgetDataProvider('w_usp')),
          {'Device.DeviceInfo.ModelName': 'M60TB'},
          reason: 'a card that comes back shows its last data at once');
    });

    test('a failure that is not a ServiceError still ends the initial fetch',
        () async {
      // Constitution 13.4.3: the loading card has no button to leave it by.
      when(() => service.fetchUspPaths(any()))
          .thenAnswer((_) async => throw StateError('a bug of ours'));

      final card = mount(_uspTemplate());
      await container.pump();
      await pumpEventQueue();

      expect(card.read(), isTrue);
    });

    test('a card that leaves while its GET fails does not subscribe', () {
      fakeAsync((async) {
        final answer = Completer<Map<String, dynamic>?>();
        when(() => service.fetchUspPaths(any()))
            .thenAnswer((_) => answer.future);

        final card = mount(_uspTemplate());
        async.flushMicrotasks();
        card.close();
        // autoDispose runs on the event queue, not as a microtask.
        async.elapse(Duration.zero);
        answer.completeError(const NetworkError());
        async.flushMicrotasks();

        verifyNever(() => service.subscribeValueChanges(
              widgetId: any(named: 'widgetId'),
              subscription: any(named: 'subscription'),
              onValueChange: any(named: 'onValueChange'),
            ));
      });
    });

    test('two cards of one template share one subscription', () async {
      // The drag-feedback copy of a card is a second renderer of the same
      // template. Sharing the live notifier is what stops that copy from
      // subscribing under the card's SSE id and unregistering it at drag end.
      var cleanups = 0;
      when(() => service.fetchUspPaths(any()))
          .thenAnswer((_) async => {'Device.DeviceInfo.ModelName': 'M60TB'});
      when(() => service.subscribeValueChanges(
            widgetId: any(named: 'widgetId'),
            subscription: any(named: 'subscription'),
            onValueChange: any(named: 'onValueChange'),
          )).thenAnswer((_) async => () async => cleanups++);

      final card = mount(_uspTemplate());
      final dragCopy = mount(_uspTemplate());
      await container.pump();
      await pumpEventQueue();
      dragCopy.close();
      await container.pump();

      verify(() => service.subscribeValueChanges(
            widgetId: any(named: 'widgetId'),
            subscription: any(named: 'subscription'),
            onValueChange: any(named: 'onValueChange'),
          )).called(1);
      expect(cleanups, 0, reason: 'the card is still on the dashboard');

      card.close();
      await container.pump();
      expect(cleanups, 1);
    });

    test('with no USP client, neither reads nor subscribes', () async {
      when(() => service.fetchUspPaths(any())).thenAnswer((_) async => null);

      final card = mount(_uspTemplate());
      await container.pump();
      await pumpEventQueue();

      verifyNever(() => service.subscribeValueChanges(
            widgetId: any(named: 'widgetId'),
            subscription: any(named: 'subscription'),
            onValueChange: any(named: 'onValueChange'),
          ));
      expect(card.read(), isTrue);
    });
  });

  _refreshTests(() => service, () => container);
  _cgiCallTests(() => service, () => container);

  test('a template with no data source reads nothing and is done at once',
      () async {
    final card = mount(PackageWidgetTemplate(
      widgetId: 'w_static',
      displayName: 'Static widget',
      constraints: _constraints,
      template: const {'type': 'AppText'},
    ));
    await container.pump();
    await pumpEventQueue();

    expect(card.read(), isTrue);
    verifyZeroInteractions(service);
  });

  group('HTTP data source', () {
    test('the initial fetch lands in the data cache and ends the initial fetch',
        () async {
      final template = _httpTemplate();
      when(() => service.fetchHttpData(template.dataSource!))
          .thenAnswer((_) async => {'ip': '1.2.3.4'});

      final card = mount(template);
      await container.pump();
      await pumpEventQueue();

      expect(container.read(packageWidgetDataProvider('w_http')),
          {'ip': '1.2.3.4'});
      expect(card.read(), isTrue);
    });

    test('polls every refreshInterval seconds until the card leaves', () {
      fakeAsync((async) {
        var fetches = 0;
        when(() => service.fetchHttpData(any())).thenAnswer((_) async {
          fetches++;
          return {'ip': 'fetch $fetches'};
        });

        final card = mount(_httpTemplate(refreshInterval: 30));
        async.flushMicrotasks();
        expect(fetches, 1, reason: 'the initial fetch');

        async.elapse(const Duration(seconds: 29));
        expect(fetches, 1);
        async.elapse(const Duration(seconds: 1));
        expect(fetches, 2);
        expect(container.read(packageWidgetDataProvider('w_http')),
            {'ip': 'fetch 2'});

        card.close();
        async.elapse(const Duration(minutes: 5));
        expect(fetches, 2, reason: 'no poll once the card has left');
      });
    });

    test('a card that leaves mid-fetch writes nothing and starts no poll', () {
      fakeAsync((async) {
        final answer = Completer<Map<String, dynamic>?>();
        var fetches = 0;
        when(() => service.fetchHttpData(any())).thenAnswer((_) {
          fetches++;
          return answer.future;
        });

        final card = mount(_httpTemplate(refreshInterval: 30));
        async.flushMicrotasks();
        card.close();
        // autoDispose runs on the event queue, not as a microtask.
        async.elapse(Duration.zero);
        answer.complete({'ip': 'late'});
        async.elapse(const Duration(minutes: 5));

        expect(container.read(packageWidgetDataProvider('w_http')), isEmpty);
        expect(fetches, 1);
        expect(async.periodicTimerCount, 0);
      });
    });
  });
}

void _refreshTests(
  MockPackageWidgetService Function() service,
  ProviderContainer Function() container,
) {
  group('refresh', () {
    test('a USP widget reads its paths again into the data cache', () async {
      var reads = 0;
      when(() => service().fetchUspPaths(any())).thenAnswer((_) async {
        reads++;
        return {'Device.DeviceInfo.UpTime': reads};
      });
      when(() => service().subscribeValueChanges(
            widgetId: any(named: 'widgetId'),
            subscription: any(named: 'subscription'),
            onValueChange: any(named: 'onValueChange'),
          )).thenAnswer((_) async => () async {});
      final template = _uspTemplate();
      container().listen(packageWidgetLiveProvider(template), (_, __) {});
      await container().pump();
      await pumpEventQueue();

      await container()
          .read(packageWidgetLiveProvider(template).notifier)
          .refresh();

      expect(reads, 2);
      expect(container().read(packageWidgetDataProvider('w_usp')),
          {'Device.DeviceInfo.UpTime': 2});
    });

    test('an HTTP widget fetches its data source again', () async {
      var fetches = 0;
      when(() => service().fetchHttpData(any())).thenAnswer((_) async {
        fetches++;
        return {'ip': 'fetch $fetches'};
      });
      final template = _httpTemplate();
      container().listen(packageWidgetLiveProvider(template), (_, __) {});
      await container().pump();
      await pumpEventQueue();

      await container()
          .read(packageWidgetLiveProvider(template).notifier)
          .refresh();

      expect(container().read(packageWidgetDataProvider('w_http')),
          {'ip': 'fetch 2'});
    });

    test('a failed read still completes, and leaves the data as it was',
        () async {
      var reads = 0;
      when(() => service().fetchUspPaths(any())).thenAnswer((_) async {
        if (++reads > 1) throw const NetworkError();
        return {'Device.DeviceInfo.UpTime': 1};
      });
      when(() => service().subscribeValueChanges(
            widgetId: any(named: 'widgetId'),
            subscription: any(named: 'subscription'),
            onValueChange: any(named: 'onValueChange'),
          )).thenAnswer((_) async => () async {});
      final template = _uspTemplate();
      container().listen(packageWidgetLiveProvider(template), (_, __) {});
      await container().pump();
      await pumpEventQueue();

      await expectLater(
        container()
            .read(packageWidgetLiveProvider(template).notifier)
            .refresh(),
        completes,
      );
      expect(container().read(packageWidgetDataProvider('w_usp')),
          {'Device.DeviceInfo.UpTime': 1});
    });
  });
}

void _cgiCallTests(
  MockPackageWidgetService Function() service,
  ProviderContainer Function() container,
) {
  group('cgiCall', () {
    Future<CgiCallResult> cgiCall({
      String url = '/cgi-bin/adguard.cgi',
      Map<String, dynamic>? body,
    }) async {
      final template = PackageWidgetTemplate(
        widgetId: 'w_cgi',
        displayName: 'CGI widget',
        constraints: _constraints,
        template: const {'type': 'AppText'},
      );
      container().listen(packageWidgetLiveProvider(template), (_, __) {});
      return container()
          .read(packageWidgetLiveProvider(template).notifier)
          .cgiCall(url: url, body: body);
    }

    test('hands back what the service answered for the URL and body', () async {
      for (final answer in const <CgiCallResult>[
        CgiCallSuccess(),
        CgiCallFailure(statusCode: 500),
        CgiCallSkipped(),
      ]) {
        when(() => service().postCgi(
              url: '/cgi-bin/adguard.cgi',
              body: {'enabled': true},
            )).thenAnswer((_) async => answer);

        expect(await cgiCall(body: {'enabled': true}), same(answer));
      }
    });

    test('a failed request is a failure with no status', () async {
      when(() => service().postCgi(url: any(named: 'url')))
          .thenAnswer((_) async => throw const NetworkError());

      final result = await cgiCall();

      expect(result, isA<CgiCallFailure>());
      expect((result as CgiCallFailure).statusCode, isNull);
    });
  });
}

PackageWidgetTemplate _httpTemplate({int refreshInterval = 0}) =>
    PackageWidgetTemplate(
      widgetId: 'w_http',
      displayName: 'HTTP widget',
      constraints: _constraints,
      dataSource: HttpDataSourceConfig(
        url: '/cgi-bin/ip-info.cgi',
        refreshInterval: refreshInterval,
        mapping: const {'ip': 'data.query'},
      ),
      template: const {'type': 'AppText'},
    );
