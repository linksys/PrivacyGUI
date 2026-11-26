// LinksysHttpClient: every cloud call, the JNAP over HTTP the router answers,
// the firmware upload and the speed-test download go through it.
//
// The network is stood in beneath the client (NetworkStandIn, an IOClient
// over package:http's MockClient), so the client's own retries, timeouts and
// error handling run as they do in the app.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/jnap/command/http/base_http_command.dart';

import 'network_stand_in.dart';

/// No wait between attempts, so a retry test does not sleep.
Duration _noDelay(int retryCount) => Duration.zero;

const _cloud = 'https://cloud.test';

// Expected values the code also builds as const are built at run time
// here: two equal const values are one instance, so == would hold
// whatever their props say.

void main() {
  late List<Object?> reported;

  setUp(() {
    reported = [];
    LinksysHttpClient.onError = reported.add;
  });

  tearDown(() => LinksysHttpClient.onError = null);

  LinksysHttpClient clientOver(
    NetworkStandIn network, {
    Duration Function(int) delay = _noDelay,
    FutureOr<void> Function(http.BaseRequest, http.BaseResponse?, int)?
        onRetry,
  }) =>
      LinksysHttpClient(
        client: network,
        getHost: () => _cloud,
        delay: delay,
        onRetry: onRetry,
      );

  group('a request', () {
    test('goes out without the charset package:http adds to its content type',
        () async {
      final network =
          NetworkStandIn((_) async => http.Response('{"result":"OK"}', 200));
      final client = clientOver(network);

      await client.post(Uri.parse('$_cloud/cloud/v1/ping'),
          headers: {'Content-Type': 'application/json'},
          body: '{"ping":true}');

      final sent = network.received.single;
      expect(sent.headers['content-type'], 'application/json');
      expect(sent.body, '{"ping":true}');
    });

    test('carries a request tag the log can match its answer by', () async {
      final network = NetworkStandIn((_) async => http.Response('', 200));
      final client = clientOver(network);

      await client.get(Uri.parse('$_cloud/cloud.json'));

      expect(network.received.single.headers['X-Request-Tag'],
          matches(RegExp(r'^LNR-\d{5}$')));
    });
  });

  group('retries', () {
    for (final status in [503, 404, 401]) {
      test('asks once more after a $status, and returns the second answer',
          () async {
        var calls = 0;
        final network = NetworkStandIn((_) async => calls++ == 0
            ? http.Response('', status)
            : http.Response('{"cloudStatus":"OK"}', 200));
        final client = clientOver(network);

        final response = await client.post(Uri.parse('$_cloud/cloud.json'),
            headers: {'Content-Type': 'application/json'}, body: '{"a":1}');

        expect(response.statusCode, 200);
        expect(response.body, '{"cloudStatus":"OK"}');
        expect(network.received, hasLength(2));
        // The body is sent again in full, not drained by the first attempt.
        expect(network.received.map((r) => r.body), ['{"a":1}', '{"a":1}']);
      });
    }

    for (final status in [200, 400, 500]) {
      test('does not ask again after a $status', () async {
        final network = NetworkStandIn((_) async => http.Response('', status));
        final client = clientOver(network);

        final response = await client.get(Uri.parse('$_cloud/cloud.json'));

        expect(response.statusCode, status);
        expect(network.received, hasLength(1));
      });
    }

    test('gives up after its retries and hands back the last answer',
        () async {
      final network = NetworkStandIn((_) async => http.Response('busy', 503));
      final client = clientOver(network)..retries = 2;

      final response = await client.get(Uri.parse('$_cloud/cloud.json'));

      expect(response.statusCode, 503);
      expect(response.body, 'busy');
      expect(network.received, hasLength(3));
    });

    test('with no retries, asks only once', () async {
      final network = NetworkStandIn((_) async => http.Response('', 503));
      final client = clientOver(network)..retries = 0;

      await client.get(Uri.parse('$_cloud/cloud.json'));

      expect(network.received, hasLength(1));
    });

    test('tells onRetry about each retry, with the answer it is retrying',
        () async {
      final retried = <(int, int?)>[];
      final network = NetworkStandIn((_) async => http.Response('', 503));
      final client = clientOver(network,
          onRetry: (request, response, retryCount) =>
              retried.add((retryCount, response?.statusCode)))
        ..retries = 2;

      await client.get(Uri.parse('$_cloud/cloud.json'));

      expect(retried, [(0, 503), (1, 503)]);
    });

    // On real time: the client puts a timeout on every request body, and
    // Stream.timeout delivers nothing on testWidgets' fake clock.
    test('wait at least 500 ms before the first retry, and 750 ms before the '
        'next', () async {
      final clock = Stopwatch()..start();
      final sentAt = <Duration>[];
      final network = NetworkStandIn((_) async {
        sentAt.add(clock.elapsed);
        return http.Response('', 503);
      });
      final client = LinksysHttpClient(client: network, getHost: () => _cloud)
        ..retries = 2;

      final response = await client.get(Uri.parse('$_cloud/cloud.json'));

      expect(response.statusCode, 503);
      expect(sentAt, hasLength(3));
      // A timer never fires early; the slack covers the two clocks' rounding.
      const slack = Duration(milliseconds: 5);
      expect(sentAt[1] - sentAt[0],
          greaterThanOrEqualTo(const Duration(milliseconds: 500) - slack));
      expect(sentAt[2] - sentAt[1],
          greaterThanOrEqualTo(const Duration(milliseconds: 750) - slack));
    });
  });

  group('a request that fails', () {
    test(
        'on a timeout is tried again, then reported as REQUEST_TIMEOUT and '
        'thrown', () async {
      final network = NetworkStandIn((_) => Completer<http.Response>().future);
      final client = clientOver(network)..timeoutMs = 20;

      await expectLater(client.get(Uri.parse('$_cloud/cloud.json')),
          throwsA(isA<TimeoutException>()));

      expect(network.received, hasLength(2));
      expect(reported,
          [ErrorResponse(status: 1000, code: 'REQUEST_TIMEOUT')]);
    });

    test(
        'for any other reason is not tried again: it is reported as '
        'UNKNOWN_ERROR and thrown', () async {
      final network = NetworkStandIn(
          (request) => throw http.ClientException('refused', request.url));
      final client = clientOver(network);

      await expectLater(client.get(Uri.parse('$_cloud/cloud.json')),
          throwsA(isA<http.ClientException>()));

      expect(network.received, hasLength(1));
      expect(reported, [ErrorResponse(status: -1, code: 'UNKNOWN_ERROR')]);
    });
  });

  group('an error answer', () {
    test(
        'with the cloud\'s error body becomes an ErrorResponse, reported and '
        'thrown', () async {
      final network = NetworkStandIn((_) async => http.Response(
          '{"errors":[{"error":{"code":"INVALID_SESSION_TOKEN",'
          '"message":"Invalid session token: abc"}}]}',
          400));
      final client = clientOver(network);

      const expected = ErrorResponse(
        status: 400,
        code: 'INVALID_SESSION_TOKEN',
        errorMessage: 'Invalid session token: abc',
      );
      await expectLater(
          client.get(Uri.parse('$_cloud/cloud/v1/guardians')), throwsA(expected));
      expect(reported, [expected]);
    });

    test('with a body that is not JSON is handed back as it is', () async {
      final network = NetworkStandIn(
          (_) async => http.Response('<html>Bad Gateway</html>', 502));
      final client = clientOver(network);

      final response = await client.get(Uri.parse('$_cloud/cloud.json'));

      expect(response.statusCode, 502);
      expect(response.body, '<html>Bad Gateway</html>');
      expect(reported, isEmpty);
    });

    // Each verb goes through the same answer handling.
    final verbs = <String, Future<http.Response> Function(LinksysHttpClient)>{
      'GET': (c) => c.get(Uri.parse('$_cloud/x')),
      'POST': (c) => c.post(Uri.parse('$_cloud/x'), body: '{}'),
      'PUT': (c) => c.put(Uri.parse('$_cloud/x'), body: '{}'),
      'PATCH': (c) => c.patch(Uri.parse('$_cloud/x'), body: '{}'),
      'DELETE': (c) => c.delete(Uri.parse('$_cloud/x')),
      'HEAD': (c) => c.head(Uri.parse('$_cloud/x')),
    };
    for (final MapEntry(key: method, value: call) in verbs.entries) {
      test('to a $method is thrown as the cloud\'s error', () async {
        final network = NetworkStandIn((_) async => http.Response(
            '{"code":"SESSION_EXPIRED","errorMessage":"gone"}', 403));
        final client = clientOver(network);

        await expectLater(
            call(client),
            throwsA(const ErrorResponse(
                status: 403, code: 'SESSION_EXPIRED', errorMessage: 'gone')));
        expect(network.received.single.method, method);
      });
    }

    for (final MapEntry(key: method, value: call) in verbs.entries) {
      test('a successful $method is handed back', () async {
        final network = NetworkStandIn((_) async => http.Response('', 204));
        final client = clientOver(network);

        final response = await call(client);

        expect(response.statusCode, 204);
        expect(network.received.single.method, method);
      });
    }
  });

  group('download', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('download_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('saves the body to the file and says it did', () async {
      final network = NetworkStandIn(
          (_) async => http.Response.bytes([0x89, 0x50, 0x4e, 0x47], 200));
      final client = clientOver(network);
      final file = File('${dir.path}/speed.bin');

      final saved =
          await client.download(Uri.parse('$_cloud/speed.bin'), file.uri);

      expect(saved, isTrue);
      expect(file.readAsBytesSync(), [0x89, 0x50, 0x4e, 0x47]);
    });

    test('says it did not, and saves nothing, when the cloud refuses',
        () async {
      final network = NetworkStandIn((_) async => http.Response(
          '{"errors":[{"error":{"code":"NOT_FOUND"}}]}', 400));
      final client = clientOver(network);
      final file = File('${dir.path}/speed.bin');

      final saved =
          await client.download(Uri.parse('$_cloud/speed.bin'), file.uri);

      expect(saved, isFalse);
      expect(file.existsSync(), isFalse);
    });

    test('says it did not when the connection fails', () async {
      final network = NetworkStandIn(
          (request) => throw http.ClientException('reset', request.url));
      final client = clientOver(network);

      final saved = await client.download(
          Uri.parse('$_cloud/speed.bin'), File('${dir.path}/x').uri);

      expect(saved, isFalse);
    });
  });

  group('upload', () {
    // The manual firmware update's request (firmware_update_provider.dart).
    Future<http.Response> uploadFirmware(LinksysHttpClient client) =>
        client.upload(
          Uri.parse('https://192.168.1.1/jcgi/'),
          [
            http.MultipartFile.fromBytes('upload', [1, 2, 3, 4],
                filename: 'FW_M63.img'),
          ],
          fields: {
            'X-JNAP-Action': 'updatefirmware',
            'X-JNAP-Authorization': 'Basic YWRtaW46YWRtaW4=',
          },
        );

    test('posts the fields and the file as one multipart body', () async {
      final network =
          NetworkStandIn((_) async => http.Response('{"result":"OK"}', 200));
      final client = clientOver(network);

      final response = await uploadFirmware(client);

      expect(response.body, '{"result":"OK"}');
      final sent = network.received.single;
      expect(sent.method, 'POST');
      expect(sent.url, Uri.parse('https://192.168.1.1/jcgi/'));
      final boundary = RegExp(r'^multipart/form-data; boundary=(\S+)$')
          .firstMatch(sent.headers['content-type']!)!
          .group(1);
      expect(
          sent.bodyBytes,
          [
            ...utf8.encode('--$boundary\r\n'
                'Content-Disposition: form-data; name="X-JNAP-Action"\r\n'
                '\r\n'
                'updatefirmware\r\n'
                '--$boundary\r\n'
                'Content-Disposition: form-data; '
                'name="X-JNAP-Authorization"\r\n'
                '\r\n'
                'Basic YWRtaW46YWRtaW4=\r\n'
                '--$boundary\r\n'
                'content-type: application/octet-stream\r\n'
                'Content-Disposition: form-data; name="upload"; '
                'filename="FW_M63.img"\r\n'
                '\r\n'),
            1, 2, 3, 4,
            ...utf8.encode('\r\n--$boundary--\r\n'),
          ]);
      expect(network.declaredLengths.single, sent.bodyBytes.length);
    });

    // The upload reads the router's answer itself, so an error answer is not
    // turned into an ErrorResponse here.
    test('hands back an error answer instead of throwing it', () async {
      final network = NetworkStandIn((_) async =>
          http.Response('{"code":"UPLOAD_FAILED","errorMessage":"x"}', 500));
      final client = clientOver(network);

      final response = await uploadFirmware(client);

      expect(response.statusCode, 500);
      expect(reported, isEmpty);
    });
  });

  group('execute', () {
    const getDeviceInfo = 'http://linksys.com/jnap/core/GetDeviceInfo';

    // A transaction names its action through the action table.
    setUp(initBetterActions);

    test('posts a JNAP command to its URL, with its headers and payload',
        () async {
      final network = NetworkStandIn((_) async => http.Response(
          '{"result":"OK","output":{"serialNumber":"SN1"}}', 200));
      final client = clientOver(network);

      final response = await client.execute(_PublishedJNAPCommand(
        executor: client,
        header: {'X-JNAP-Action': getDeviceInfo},
        data: '{"a":1}',
      ));

      final sent = network.received.single;
      expect(sent.method, 'POST');
      expect(sent.url, Uri.parse('https://192.168.1.1/JNAP/'));
      expect(sent.headers['X-JNAP-Action'], getDeviceInfo);
      expect(sent.body, '{"a":1}');
      expect(response.body, '{"result":"OK","output":{"serialNumber":"SN1"}}');
    });

    test('posts a transaction to its URL, with its headers and payload',
        () async {
      final network =
          NetworkStandIn((_) async => http.Response('{"result":"OK"}', 200));
      final client = clientOver(network);

      await client.execute(_PublishedTransaction(
        executor: client,
        header: {
          'X-JNAP-Action': 'http://linksys.com/jnap/core/Transaction',
        },
        data: '[{"action":"$getDeviceInfo","request":{}}]',
      ));

      final sent = network.received.single;
      expect(sent.url, Uri.parse('https://192.168.1.1/JNAP/'));
      expect(sent.headers['X-JNAP-Action'],
          'http://linksys.com/jnap/core/Transaction');
      expect(jsonDecode(sent.body), [
        {'action': getDeviceInfo, 'request': {}},
      ]);
    });
  });

  group('building a request', () {
    test('names the cloud host, and fills in the endpoint\'s placeholders', () {
      final client = LinksysHttpClient(getHost: () => _cloud);

      expect(
          client.combineUrl(
              '/cloud/v1/guardians/remote-assistances/sessions/{sessionId}',
              args: {'{sessionId}': 'S-1'}),
          '$_cloud/cloud/v1/guardians/remote-assistances/sessions/S-1');
      expect(client.combineUrl('/cloud/v1/geolocation'),
          '$_cloud/cloud/v1/geolocation');
    });

    test('goes to the build\'s cloud when no host is given', () {
      // The default build points at QA (`cloud_env` defaults to `qa`).
      expect(LinksysHttpClient().getHost(),
          'https://qa.cloud1.linksyssmartwifi.com');
    });

    test('wraps a session token the way the cloud reads it', () {
      expect(LinksysHttpClient().wrapSessionToken('abc'),
          'LinksysUserAuth session_token="abc"');
    });

    test('off the web, carries the client type and JSON headers only', () {
      expect(LinksysHttpClient().defaultHeader, {
        'X-Linksys-Client-Type-Id': 'B2101C5E-0E0C-4094-8BC5-6B97DE71C5BB',
        'content-type': 'application/json',
        'accept': 'application/json',
      });
    });
  });
}

// A command as publish() leaves it: the header and payload it fills in are
// stood in here, so execute is tested without the app's cache, which
// publish() opens.
class _PublishedJNAPCommand extends JNAPHttpCommand {
  _PublishedJNAPCommand({
    required super.executor,
    required Map<String, String> header,
    required String data,
  })  : _header = header,
        _data = data,
        super(url: 'https://192.168.1.1/JNAP/', action: 'unused');

  final Map<String, String> _header;
  final String _data;

  @override
  Map<String, String> get header => _header;

  @override
  String get data => _data;
}

class _PublishedTransaction extends TransactionHttpCommand {
  _PublishedTransaction({
    required super.executor,
    required Map<String, String> header,
    required String data,
  })  : _header = header,
        _data = data,
        super(
            url: 'https://192.168.1.1/JNAP/', payload: const [], actions: const []);

  final Map<String, String> _header;
  final String _data;

  @override
  Map<String, String> get header => _header;

  @override
  String get data => _data;
}
