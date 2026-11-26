// The timeout and retries an executor holds are what its HTTP client waits for
// and retries with: the repository sets them per command (router_repository's
// createCommand), and LinksysHttpClient reads them on every request.
//
// The router here never answers, so each request runs into the timeout. The
// waits are real timers, so the tests run on testWidgets' fake clock and read
// the outcome after pumping.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';

/// A connection to a router that never answers: every request it opens hangs.
class _SilentRouter extends Fake implements HttpClient {
  int opened = 0;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    opened++;
    return Completer<HttpClientRequest>().future;
  }
}

void main() {
  late _SilentRouter router;
  late LinksysHttpClient executor;
  Object? failure;

  void sendJnap() {
    final request = http.Request('POST', Uri.parse('https://192.168.1.1/JNAP/'))
      ..body = '{}';
    executor.send(request).then<void>(
      (_) {},
      onError: (Object error) {
        failure = error;
      },
    );
  }

  setUp(() {
    router = _SilentRouter();
    executor = LinksysHttpClient(client: IOClient(router));
    failure = null;
  });

  testWidgets(
      'waits 10 s for an answer and retries once, half a second later, '
      'unless told otherwise', (tester) async {
    sendJnap();

    await tester.pump(const Duration(seconds: 10));
    expect(router.opened, 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(router.opened, 2);
    expect(failure, isNull);
    await tester.pump(const Duration(seconds: 10));

    expect(router.opened, 2);
    expect(failure, isA<TimeoutException>());
  });

  testWidgets('gives up after the timeout and retries the repository sets',
      (tester) async {
    // As the side effect's probes ask: a 3 s wait and no retry.
    executor
      ..timeoutMs = 3000
      ..retries = 0;

    sendJnap();
    await tester.pump(const Duration(milliseconds: 2999));
    expect(failure, isNull);
    await tester.pump(const Duration(milliseconds: 1));

    expect(failure, isA<TimeoutException>());
    expect(router.opened, 1);
  });
}
