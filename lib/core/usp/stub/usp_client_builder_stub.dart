/// Stub for UspClientBuilderJS — used for Remote Assistance mode.
/// On non-web platforms this is a no-op class that can't actually build a client.
class UspClientBuilderJS {
  UspClientBuilderJS(String baseUrl);
  UspClientBuilderJS endpoint(String endpoint) => this;
  UspClientBuilderJS authToken(String token) => this;
  UspClientBuilderJS extraHeader(String name, String value) => this;
  dynamic build() => throw UnsupportedError('USP is only available on Web');
}
