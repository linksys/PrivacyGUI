part of 'base_http_command.dart';

class TransactionHttpCommand
    extends BaseHttpCommand<JNAPTransactionSuccessWrap, HttpTransactionSpec> {
  final List<JNAPAction> actions;
  TransactionHttpCommand({
    required super.url,
    required super.executor,
    required List<Map<String, dynamic>> payload,
    required this.actions,
    Map<String, String> extraHeader = const {},
    super.fetchRemote,
    super.cacheLevel,
  }) : super(
            spec: HttpTransactionSpec(
          extraHeader: extraHeader,
          payload: payload,
        ));

  @override
  Future<JNAPTransactionSuccessWrap> publish() async {
    final cache = ProviderContainer().read(linksysCacheManagerProvider);
    if (checkCacheValidation(cache)) {
      final actions = [];
      for (var element in (jsonDecode(spec.payload()) as List<dynamic>)) {
        actions.add(cache.data[element["action"]]["data"]);
      }
      final dataMap = {keyJnapResult: jnapResultOk, keyJnapResponses: actions};
      logger
          .d('[CacheManager] responsed with local cache transaction: $dataMap');
      return createResponse(jsonEncode(dataMap));
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
          jnap.data.forEach((entry) {
            final dataResult = {
              "target": entry.key.actionValue,
              "cachedAt": DateTime.now().millisecondsSinceEpoch,
            };
            dataResult["data"] = (entry.value as JNAPSuccess).toJson();
            cache.data[entry.key.actionValue] = dataResult;
          });
          logger.d(
              '[CacheManager] save JNAP<${spec.action}> data to $serialNumber');
          if (serialNumber != null) {
            cache.saveCache(serialNumber);
          }
        }
        return jnap;
      }).catchError(handleJNAPError, test: errorTest);
    }
  }

  @override
  JNAPTransactionSuccessWrap createResponse(String payload) {
    final result = spec.response(payload);
    if (result is JNAPTransactionSuccess) {
      return JNAPTransactionSuccessWrap.convert(
          actions: actions, transactionSuccess: result);
    }
    throw (result as JNAPError);
  }

  @override
  bool checkCacheValidation(LinksysCacheManager cache) {
    return !fetchRemote && !_checkNonExistActionAndExpiration(cache);
  }

  bool _checkNonExistActionAndExpiration(LinksysCacheManager cache) {
    final actionList = jsonDecode(spec.payload()) as List<dynamic>;
    return actionList
        .any((element) => !cache.checkCacheDataValid(element['action']));
  }
}
