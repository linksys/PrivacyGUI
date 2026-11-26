import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The cloud's status page, served on the loopback interface.
///
/// A `LinksysHttpClient` built inside [run] gets an [HttpClient] that sends
/// every request here instead of to the host it names, and records the URL it
/// was asked for. Under the test binding every other [HttpClient] answers an
/// empty 400.
class CloudStatusStandIn {
  CloudStatusStandIn._(this._server, this._client);

  static Future<CloudStatusStandIn> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    // A real client, which the test binding's HttpOverrides would replace.
    final client = HttpOverrides.runWithHttpOverrides(
        () => HttpClient(), _RealHttpClients());
    final standIn = CloudStatusStandIn._(server, client);
    server.listen(standIn._answer);
    return standIn;
  }

  final HttpServer _server;
  final HttpClient _client;

  /// What the status page answers.
  int status = 200;
  String body = '{"cloudStatus":"OK"}';

  /// The URLs the app asked for, in order.
  final List<Uri> requested = [];

  /// Runs [body] with every [HttpClient] it creates sent to this page.
  R run<R>(R Function() body) => HttpOverrides.runZoned(body,
      createHttpClient: (_) => _Redirect(this));

  Future<void> close() async {
    _client.close(force: true);
    await _server.close(force: true);
  }

  void _answer(HttpRequest request) {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(body);
    request.response.close();
  }
}

class _RealHttpClients extends HttpOverrides {}

class _Redirect extends Fake implements HttpClient {
  _Redirect(this._standIn);

  final CloudStatusStandIn _standIn;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    _standIn.requested.add(url);
    return _standIn._client.openUrl(
        method,
        url.replace(
            scheme: 'http',
            host: InternetAddress.loopbackIPv4.address,
            port: _standIn._server.port));
  }

  @override
  void close({bool force = false}) {}
}
