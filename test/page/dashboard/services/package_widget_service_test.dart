import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/models/sse_notification.dart';
import 'package:privacy_gui/core/usp/services/bridge_request_throttler.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/dashboard/models/cgi_call_result.dart';
import 'package:privacy_gui/page/dashboard/models/package_widget_template.dart';
import 'package:privacy_gui/page/dashboard/services/package_widget_service.dart';

class MockUspClient extends Mock implements UspClient {}

class MockSseManager extends Mock implements SseManager {}

class MockBridgeRequestThrottler extends Mock
    implements BridgeRequestThrottler {}

/// A client that fails the test if the service sends anything through it.
final _noHttp = MockClient((request) async {
  fail('unexpected HTTP request: ${request.method} ${request.url}');
});

PackageWidgetService _service({
  UspClient? usp,
  SseManager? sse,
  http.Client? httpClient,
  BridgeRequestThrottler? throttler,
  String? baseUrl = 'http://192.168.1.1',
}) {
  return PackageWidgetService(
    usp: usp,
    sse: sse,
    throttler: throttler ??
        BridgeRequestThrottler(
          staggerDelay: Duration.zero,
          defaultCacheTtl: Duration.zero,
        ),
    httpClient: httpClient ?? _noHttp,
    baseUrl: baseUrl,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String>[]);
    registerFallbackValue(RequestPriority.normal);
    Future<http.Response> fallbackAction() async => http.Response('', 200);
    registerFallbackValue(fallbackAction);
  });

  group('fetchUspPaths', () {
    test('returns what the router answers for the widget paths', () async {
      final usp = MockUspClient();
      when(() => usp.get(['Device.DeviceInfo.ModelName']))
          .thenAnswer((_) async => {'Device.DeviceInfo.ModelName': 'M60TB'});

      final data = await _service(usp: usp)
          .fetchUspPaths(['Device.DeviceInfo.ModelName']);

      expect(data, {'Device.DeviceInfo.ModelName': 'M60TB'});
    });

    test('returns null when there is no USP client', () async {
      expect(await _service(usp: null).fetchUspPaths(['Device.X.']), isNull);
    });

    test('a failed GET reaches the caller as a ServiceError', () async {
      final usp = MockUspClient();
      // The WASM client throws plain strings (constitution 13.3).
      when(() => usp.get(any())).thenAnswer((_) async => throw 'timeout');

      await expectLater(
        _service(usp: usp).fetchUspPaths(['Device.X.']),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  group('subscribeValueChanges', () {
    late MockSseManager sse;
    late SseNotificationHandler handler;
    var cleanedUp = false;

    setUp(() {
      sse = MockSseManager();
      cleanedUp = false;
      when(() => sse.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            notifType: any(named: 'notifType'),
            referenceList: any(named: 'referenceList'),
            onNotification: any(named: 'onNotification'),
          )).thenAnswer((invocation) async {
        handler = invocation.namedArguments[#onNotification]
            as SseNotificationHandler;
        return () async => cleanedUp = true;
      });
    });

    SseNotification valueChange(String path, Object? value) => SseNotification(
          subscriptionId: 'cpe-5',
          type: 'ValueChange',
          payload: {
            'value_change': {'param_path': path, 'param_value': value},
          },
        );

    test('a ValueChange reaches the handler as a path and a value', () async {
      final changes = <(String, Object?)>[];

      await _service(sse: sse).subscribeValueChanges(
        widgetId: 'w1',
        subscription: const WidgetSubscriptionConfig(
          paths: ['Device.WiFi.Radio.1.', 'Device.WiFi.Radio.2.'],
          notifType: 'ValueChange',
        ),
        onValueChange: (path, value) => changes.add((path, value)),
      );
      handler(valueChange('Device.WiFi.Radio.1.Channel', '36'));

      verify(() => sse.subscribe(
            subscriptionId: 'pkg-w1-valuechange',
            notifType: 'ValueChange',
            referenceList: 'Device.WiFi.Radio.1.',
            onNotification: any(named: 'onNotification'),
          )).called(1);
      expect(changes, [('Device.WiFi.Radio.1.Channel', '36')]);
    });

    test('returns the manager\'s cleanup, which removes the subscription',
        () async {
      final cleanup = await _service(sse: sse).subscribeValueChanges(
        widgetId: 'w1',
        subscription: const WidgetSubscriptionConfig(
          paths: ['Device.X.'],
          notifType: 'ValueChange',
        ),
        onValueChange: (_, __) {},
      );
      await cleanup!();

      expect(cleanedUp, isTrue);
    });

    test('ignores what is not a ValueChange with a path', () async {
      final changes = <(String, Object?)>[];
      await _service(sse: sse).subscribeValueChanges(
        widgetId: 'w1',
        subscription: const WidgetSubscriptionConfig(
          paths: ['Device.X.'],
          notifType: 'ValueChange',
        ),
        onValueChange: (path, value) => changes.add((path, value)),
      );

      handler(const SseNotification(
        subscriptionId: 'cpe-5',
        type: 'ObjectCreation',
        payload: {
          'value_change': {'param_path': 'Device.X.Y', 'param_value': 1},
        },
      ));
      handler(const SseNotification(
        subscriptionId: 'cpe-5',
        type: 'ValueChange',
        payload: {},
      ));
      handler(const SseNotification(
        subscriptionId: 'cpe-5',
        type: 'ValueChange',
        payload: {
          'value_change': {'param_value': 1},
        },
      ));

      expect(changes, isEmpty);
    });

    test('returns null when there is no SSE manager', () async {
      final cleanup = await _service(sse: null).subscribeValueChanges(
        widgetId: 'w1',
        subscription: const WidgetSubscriptionConfig(
          paths: ['Device.X.'],
          notifType: 'ValueChange',
        ),
        onValueChange: (_, __) {},
      );

      expect(cleanup, isNull);
    });

    test('a failed subscribe reaches the caller as a ServiceError', () async {
      when(() => sse.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            notifType: any(named: 'notifType'),
            referenceList: any(named: 'referenceList'),
            onNotification: any(named: 'onNotification'),
          )).thenAnswer((_) async => throw 'subscription failed');

      await expectLater(
        _service(sse: sse).subscribeValueChanges(
          widgetId: 'w1',
          subscription: const WidgetSubscriptionConfig(
            paths: ['Device.X.'],
            notifType: 'ValueChange',
          ),
          onValueChange: (_, __) {},
        ),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  group('fetchHttpData', () {
    test('GETs the URL on the router with the session token, then maps it',
        () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
            '{"data": {"query": "1.2.3.4", "city": "Taipei"}}', 200);
      });
      final usp = MockUspClient();
      when(() => usp.sessionToken).thenReturn('session-token');

      final data = await _service(usp: usp, httpClient: client).fetchHttpData(
        const HttpDataSourceConfig(
          url: '/cgi-bin/ip-info.cgi',
          method: 'GET',
          mapping: {'ip': 'data.query', 'city': 'data.city'},
        ),
      );

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(requests.single.url.toString(),
          'http://192.168.1.1/cgi-bin/ip-info.cgi');
      expect(requests.single.headers['Authorization'], 'Bearer session-token');
      expect(requests.single.headers['Content-Type'],
          startsWith('application/json'));
      expect(data, {'ip': '1.2.3.4', 'city': 'Taipei'});
    });

    test('POSTs a data source whose method is not GET, with its body',
        () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"rx": 7}', 200);
      });

      final data = await _service(httpClient: client).fetchHttpData(
        const HttpDataSourceConfig(
          url: '/cgi-bin/stats.cgi',
          body: {'iface': 'wan'},
          mapping: {'rx': 'rx'},
        ),
      );

      expect(requests.single.method, 'POST');
      expect(jsonDecode(requests.single.body), {'iface': 'wan'});
      expect(requests.single.headers.containsKey('Authorization'), isFalse,
          reason: 'no session token, no Authorization header');
      expect(data, {'rx': 7});
    });

    test('refuses a URL that is not a local CGI path, without a request',
        () async {
      for (final url in ['https://evil.com/api', '/api/v1/data']) {
        final data = await _service(httpClient: _noHttp).fetchHttpData(
          HttpDataSourceConfig(url: url, mapping: const {'k': 'v'}),
        );
        expect(data, isNull, reason: url);
      }
    });

    test('returns null for a response that is not 200', () async {
      final client =
          MockClient((_) async => http.Response('Server Error', 500));

      final data = await _service(httpClient: client).fetchHttpData(
        const HttpDataSourceConfig(url: '/cgi-bin/x.cgi', mapping: {'k': 'v'}),
      );

      expect(data, isNull);
    });

    test(
        'a failed request or unreadable answer reaches the caller as a '
        'ServiceError', () async {
      const source =
          HttpDataSourceConfig(url: '/cgi-bin/x.cgi', mapping: {'k': 'v'});
      final dropped = MockClient((_) async => throw Exception('unreachable'));
      final notJson = MockClient((_) async => http.Response('<html>', 200));

      await expectLater(
        _service(httpClient: dropped).fetchHttpData(source),
        throwsA(isA<ServiceError>()),
      );
      await expectLater(
        _service(httpClient: notJson).fetchHttpData(source),
        throwsA(isA<ServiceError>()),
      );
      // Where the page has no origin (`Uri.base` is `file://` under test),
      // reading it throws — that too is a failed request, not a crash.
      await expectLater(
        _service(httpClient: notJson, baseUrl: null).fetchHttpData(source),
        throwsA(isA<ServiceError>()),
      );
    });

    test('goes through the throttler at low priority under http:<method>:<url>',
        () async {
      final throttler = _passThroughThrottler();
      final client = MockClient((_) async => http.Response('{}', 200));

      await _service(httpClient: client, throttler: throttler).fetchHttpData(
        const HttpDataSourceConfig(url: '/cgi-bin/x.cgi', mapping: {}),
      );

      verify(() => throttler.enqueue<http.Response>(
            cacheKey: 'http:POST:/cgi-bin/x.cgi',
            priority: RequestPriority.low,
            action: any(named: 'action'),
          )).called(1);
    });
  });

  _postCgiTests();
  _loaderFetchTests();
}

void _loaderFetchTests() {
  group('fetchWidgetEntries', () {
    test('reads widget id → template URL from apps and userApps in apps.json',
        () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'apps': [
              {
                'name': 'adguard',
                'widget': {
                  'id': 'pkg_adguard',
                  'templateUrl': '/apps/adguard/widget.json'
                },
              },
              {'name': 'no-widget'},
              {
                'name': 'no-url',
                'widget': {'id': 'pkg_broken'},
              },
            ],
            'userApps': [
              {
                'name': 'speed',
                'widget': {
                  'id': 'pkg_speed',
                  'templateUrl': 'http://192.168.1.1/apps/speed/widget.json'
                },
              },
            ],
          }),
          200,
        );
      });

      final entries = await _service(httpClient: client).fetchWidgetEntries();

      expect(requests.single.method, 'GET');
      expect(
          requests.single.url.toString(), 'http://192.168.1.1/api/apps.json');
      expect(requests.single.headers.containsKey('Authorization'), isFalse);
      expect(entries, {
        'pkg_adguard': '/apps/adguard/widget.json',
        'pkg_speed': 'http://192.168.1.1/apps/speed/widget.json',
      });
    });

    test('returns null when apps.json is not 200', () async {
      final client = MockClient((_) async => http.Response('', 404));

      expect(await _service(httpClient: client).fetchWidgetEntries(), isNull);
    });

    test('a failed fetch or unreadable apps.json is a ServiceError', () async {
      final dropped = MockClient((_) async => throw Exception('unreachable'));
      final notJson = MockClient((_) async => http.Response('<html>', 200));

      await expectLater(_service(httpClient: dropped).fetchWidgetEntries(),
          throwsA(isA<ServiceError>()));
      await expectLater(_service(httpClient: notJson).fetchWidgetEntries(),
          throwsA(isA<ServiceError>()));
    });
  });

  group('fetchTemplate', () {
    const templateJson =
        '{"widgetId": "pkg_adguard", "displayName": "AdGuard"}';

    test('fetches a relative template URL from the router and parses it',
        () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(templateJson, 200);
      });

      final template = await _service(httpClient: client)
          .fetchTemplate('/apps/adguard/widget.json');

      expect(requests.single.url.toString(),
          'http://192.168.1.1/apps/adguard/widget.json');
      expect(template?.widgetId, 'pkg_adguard');
      expect(template?.displayName, 'AdGuard');
    });

    test('fetches an absolute template URL as it is', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(templateJson, 200);
      });

      await _service(httpClient: client)
          .fetchTemplate('http://10.0.0.1/apps/adguard/widget.json');

      expect(requests.single.url.toString(),
          'http://10.0.0.1/apps/adguard/widget.json');
    });

    test('returns null when the template is not 200', () async {
      final client = MockClient((_) async => http.Response('', 404));

      expect(
          await _service(httpClient: client).fetchTemplate('/w.json'), isNull);
    });

    test('a failed fetch or unreadable template is a ServiceError', () async {
      final dropped = MockClient((_) async => throw Exception('unreachable'));
      final notJson = MockClient((_) async => http.Response('<html>', 200));

      await expectLater(_service(httpClient: dropped).fetchTemplate('/w.json'),
          throwsA(isA<ServiceError>()));
      await expectLater(_service(httpClient: notJson).fetchTemplate('/w.json'),
          throwsA(isA<ServiceError>()));
    });
  });
}

void _postCgiTests() {
  group('postCgi', () {
    test('POSTs the body to the CGI URL with the session token; 200 succeeds',
        () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 200);
      });
      final usp = MockUspClient();
      when(() => usp.sessionToken).thenReturn('session-token');

      final result = await _service(usp: usp, httpClient: client).postCgi(
        url: '/cgi-bin/adguard.cgi',
        body: {'enabled': true},
      );

      expect(result, isA<CgiCallSuccess>());
      expect(requests.single.method, 'POST');
      expect(requests.single.url.toString(),
          'http://192.168.1.1/cgi-bin/adguard.cgi');
      expect(jsonDecode(requests.single.body), {'enabled': true});
      expect(requests.single.headers['Authorization'], 'Bearer session-token');
    });

    test('another status is a failure that carries it', () async {
      final client = MockClient((_) async => http.Response('busy', 503));

      final result =
          await _service(httpClient: client).postCgi(url: '/cgi-bin/x.cgi');

      expect(result, isA<CgiCallFailure>());
      expect((result as CgiCallFailure).statusCode, 503);
    });

    test('refuses a URL that is not a local CGI path, without a request',
        () async {
      for (final url in ['https://evil.com/steal', '/api/v1/hack']) {
        expect(await _service(httpClient: _noHttp).postCgi(url: url),
            isA<CgiCallSkipped>(),
            reason: url);
      }
    });

    test('a failed request reaches the caller as a ServiceError', () async {
      final dropped = MockClient((_) async => throw Exception('unreachable'));

      await expectLater(
        _service(httpClient: dropped).postCgi(url: '/cgi-bin/x.cgi'),
        throwsA(isA<ServiceError>()),
      );
    });

    test('goes through the throttler at low priority under cgi:<url>',
        () async {
      final throttler = _passThroughThrottler();
      final client = MockClient((_) async => http.Response('{}', 200));

      await _service(httpClient: client, throttler: throttler)
          .postCgi(url: '/cgi-bin/x.cgi');

      verify(() => throttler.enqueue<http.Response>(
            cacheKey: 'cgi:/cgi-bin/x.cgi',
            priority: RequestPriority.low,
            action: any(named: 'action'),
          )).called(1);
    });
  });
}

/// A throttler that runs every request at once, so a test can read the cache
/// key and priority a request was queued under.
MockBridgeRequestThrottler _passThroughThrottler() {
  final throttler = MockBridgeRequestThrottler();
  when(() => throttler.enqueue<http.Response>(
            cacheKey: any(named: 'cacheKey'),
            priority: any(named: 'priority'),
            action: any(named: 'action'),
          ))
      .thenAnswer((invocation) => (invocation.namedArguments[#action]
          as Future<http.Response> Function())());
  return throttler;
}
