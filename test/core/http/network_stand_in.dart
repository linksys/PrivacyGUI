import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/testing.dart';

/// The network beneath a `LinksysHttpClient`, which takes an [IOClient].
///
/// Each request is answered by [answer], as `package:http`'s [MockClient]
/// answers it, and recorded in [received] as the network got it, after the
/// client's own header and body handling. [declaredLengths] holds the
/// content length each request declared, which [MockClient] does not pass on.
/// As a real [IOClient] does, each response names the request it answers.
class NetworkStandIn extends IOClient {
  NetworkStandIn(this.answer);

  /// Answers one request. Throw to fail the request, as a dropped connection
  /// does; return a future that never completes for a network that never
  /// answers.
  MockClientHandler answer;

  final List<http.Request> received = [];
  final List<int?> declaredLengths = [];

  late final MockClient _mock = MockClient((request) {
    received.add(request);
    return answer(request);
  });

  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) async {
    declaredLengths.add(request.contentLength);
    final response = await _mock.send(request);
    return IOStreamedResponse(
      response.stream,
      response.statusCode,
      contentLength: response.contentLength,
      request: request,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
