part of 'base_http_command.dart';

class JNAPHttpCommand extends BaseHttpCommand<JNAPResult, HttpJNAPSpec> {
  JNAPHttpCommand({
    required super.url,
    required super.executor,
    super.fetchRemote,
    super.cacheLevel,
    required String action,
    Map<String, dynamic> data = const {},
    Map<String, String> extraHeader = const {},
  }) : super(
            spec: HttpJNAPSpec(
          action: action,
          data: data,
          extraHeader: extraHeader,
        ));

  @override
  Future<JNAPResult> publish() async {
    final cache = ProviderContainer().read(linksysCacheManagerProvider);
    if (checkCacheValidation(cache)) {
      logger
          .d('[CacheManager] responsed with local cache data: ${spec.action}');
      return createResponse(jsonEncode(cache.data[spec.action]["data"]));
    } else {
      _data = spec.payload();
      _header = {
        keyMqttHeaderAction: spec.action,
        HttpHeaders.contentTypeHeader: ContentType.json.value,
        // HttpHeaders.acceptEncodingHeader: '*/*',
        ...spec.extraHeader
      }..removeWhere((key, value) => value.isEmpty);
      return executor
          .execute(this)
          .then((result) => createResponse(result.body))
          .then((jnap) async {
        if (cacheLevel == CacheLevel.localCached) {
          final prefs = await SharedPreferences.getInstance();
          final serialNumber = prefs.getString(pCurrentSN);
          if (serialNumber != null) {
            logger.d(
                '[CacheManager] save JNAP<${spec.action}> data to $serialNumber');
            cache.handleJNAPCached(jnap.toJson(), spec.action, serialNumber);
          }
        }
        return jnap;
      }).catchError(handleJNAPError, test: errorTest);
    }
  }

  @override
  JNAPResult createResponse(String payload) {
    final result = super.createResponse(payload);
    if (result is JNAPSuccess) {
      return result;
    }
    throw (result as JNAPError);
  }

  @override
  bool checkCacheValidation(LinksysCacheManager cache) {
    return !fetchRemote && cache.checkCacheDataValid(spec.action);
  }
}
