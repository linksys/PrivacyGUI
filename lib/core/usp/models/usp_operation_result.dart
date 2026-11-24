import 'package:privacy_gui/core/usp/errors/usp_refusal_reason.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// USP 操作結果的 sealed class hierarchy
///
/// 實作「Never Lose Information」原則，保留所有來自 firmware 的結構化資訊
sealed class UspOperationResult<T> {
  const UspOperationResult();

  /// 便利方法：檢查是否有任何成功操作
  bool get hasAnySuccess => switch (this) {
        UspSuccess(details: final details) => details.isNotEmpty,
        UspPartialSuccess(successes: final successes) => successes.isNotEmpty,
        UspFailure() => false,
      };

  /// 便利方法：檢查是否完全成功
  bool get isCompleteSuccess => switch (this) {
        UspSuccess() => true,
        UspPartialSuccess() || UspFailure() => false,
      };

  /// 便利方法：檢查是否有錯誤
  bool get hasErrors => switch (this) {
        UspSuccess() => false,
        UspPartialSuccess() || UspFailure() => true,
      };

  /// 在允許部分成功的情境中檢查是否成功
  bool isSuccessfulInContext({bool allowPartial = false}) {
    return allowPartial ? hasAnySuccess : isCompleteSuccess;
  }
}

/// 完全成功：所有操作都成功
final class UspSuccess<T> extends UspOperationResult<T> {
  final List<UspSuccessDetail> details;

  const UspSuccess(this.details);

  /// 取得所有成功更新的實例
  List<UspUpdatedInstance> get allUpdatedInstances => details
      .expand((d) => d.updatedInstances ?? <UspUpdatedInstance>[])
      .toList();

  /// 取得所有創建的實例
  List<UspCreatedInstance> get allCreatedInstances => details
      .expand((d) => d.createdInstances ?? <UspCreatedInstance>[])
      .toList();

  /// 取得所有刪除的實例
  List<UspDeletedInstance> get allDeletedInstances => details
      .expand((d) => d.deletedInstances ?? <UspDeletedInstance>[])
      .toList();

  @override
  String toString() => 'UspSuccess(${details.length} details)';
}

/// 部分成功：有些成功，有些失敗
final class UspPartialSuccess<T> extends UspOperationResult<T> {
  final List<UspSuccessDetail> successes;
  final List<UspErrorDetail> failures;

  const UspPartialSuccess(this.successes, this.failures);

  /// Every instance the operation created, as [UspSuccess.allCreatedInstances]
  /// has it. An Add the agent created but refused part of comes back as a
  /// partial success with its rows here (usp-client 0.14.0).
  List<UspCreatedInstance> get allCreatedInstances => successes
      .expand((d) => d.createdInstances ?? <UspCreatedInstance>[])
      .toList();

  /// 錯誤摘要
  String get errorSummary =>
      failures.map((f) => '${f.requestedPath}: ${f.errorMessage}').join('; ');

  /// 成功操作摘要
  String get successSummary => successes.map((s) => s.requestedPath).join(', ');

  @override
  String toString() =>
      'UspPartialSuccess(${successes.length} successes, ${failures.length} failures)';
}

/// 完全失敗：所有操作都失敗
final class UspFailure<T> extends UspOperationResult<T> {
  final List<UspErrorDetail> errors;

  const UspFailure(this.errors);

  /// 錯誤摘要
  String get errorSummary =>
      errors.map((e) => '${e.requestedPath}: ${e.errorMessage}').join('; ');

  /// 取得特定錯誤碼的錯誤
  List<UspErrorDetail> getErrorsByCode(int errorCode) =>
      errors.where((e) => e.errorCode == errorCode).toList();

  @override
  String toString() => 'UspFailure(${errors.length} errors)';
}

// =============================================================================
// 詳細資料類別
// =============================================================================

/// 成功操作的詳細資訊
class UspSuccessDetail {
  final String requestedPath;
  final List<UspUpdatedInstance>? updatedInstances;
  final List<UspCreatedInstance>? createdInstances;
  final List<UspDeletedInstance>? deletedInstances;
  final Map<String, dynamic>? retrievedParams;
  final String? commandKey;
  final Map<String, dynamic>? outputArgs;

  const UspSuccessDetail({
    required this.requestedPath,
    this.updatedInstances,
    this.createdInstances,
    this.deletedInstances,
    this.retrievedParams,
    this.commandKey,
    this.outputArgs,
  });

  factory UspSuccessDetail.fromMap(Map<String, dynamic> map) {
    return UspSuccessDetail(
      requestedPath: map['requestedPath'] as String,
      updatedInstances: _parseUpdatedInstances(map['updatedInstances']),
      createdInstances: _parseCreatedInstances(map['createdInstances']),
      deletedInstances: _parseDeletedInstances(map['deletedInstances']),
      retrievedParams: map['retrievedParams'] as Map<String, dynamic>?,
      commandKey: map['commandKey'] as String?,
      outputArgs: map['outputArgs'] as Map<String, dynamic>?,
    );
  }

  static List<UspUpdatedInstance>? _parseUpdatedInstances(dynamic data) {
    if (data == null) return null;
    final list = data as List<dynamic>;
    return list
        .map((item) => UspUpdatedInstance.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  static List<UspCreatedInstance>? _parseCreatedInstances(dynamic data) {
    if (data == null) return null;
    final list = data as List<dynamic>;
    return list
        .map((item) => UspCreatedInstance.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  static List<UspDeletedInstance>? _parseDeletedInstances(dynamic data) {
    if (data == null) return null;
    final list = data as List<dynamic>;
    return list
        .map((item) => UspDeletedInstance.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  String toString() => 'UspSuccessDetail($requestedPath)';
}

/// What one entry of a usp-client `errors` list says failed (usp-client
/// 0.16.0). The client reads it from the structure of the answer, never from
/// the shape of a path.
enum UspErrorKind {
  /// The call as a whole: the client's own transport (9999), decode (9998) or
  /// validation (9997) failure, or the router refusing the whole request (a
  /// USP `Error`, with the router's code).
  request,

  /// One requested path: an object the router did not write, create or
  /// delete, a Get path it does not have, a command it refused.
  path,

  /// The object was written or created, but the router refused this
  /// parameter of it.
  parameter,

  /// A failure the app makes itself, or a kind this client does not name.
  unknown;

  /// The kind an `errors` entry's `kind` member names.
  static UspErrorKind fromWire(Object? kind) => switch (kind) {
        'request' => request,
        'path' => path,
        'parameter' => parameter,
        _ => unknown,
      };
}

/// 失敗操作的詳細資訊
class UspErrorDetail {
  final String requestedPath;
  final int errorCode;
  final String errorMessage;

  /// Why the router refused, when it named a reason ([UspRefusalReason]).
  ///
  /// Set from [errorMessage] once, by [UspErrorDetail.fromResponse], where a
  /// failure enters the app. Code above the USP layer reads this, never
  /// [errorMessage]. The plain constructor leaves it [UspRefusalReason.unknown]:
  /// it is for failures the app makes itself.
  final UspRefusalReason refusalReason;

  /// What failed, as the response's `errors` entry said ([UspErrorKind]).
  ///
  /// Carried for the log and for diagnosis; no write decides anything by it.
  /// The plain constructor leaves it [UspErrorKind.unknown].
  final UspErrorKind kind;

  const UspErrorDetail({
    required this.requestedPath,
    required this.errorCode,
    required this.errorMessage,
    this.refusalReason = UspRefusalReason.unknown,
    this.kind = UspErrorKind.unknown,
  });

  /// A failure as a response reported it (the router's, or the WASM
  /// client's), with [refusalReason] read off its message.
  factory UspErrorDetail.fromResponse({
    required String requestedPath,
    required int errorCode,
    required String errorMessage,
    required UspErrorKind kind,
  }) =>
      UspErrorDetail(
        requestedPath: requestedPath,
        errorCode: errorCode,
        errorMessage: errorMessage,
        refusalReason: UspRefusalReason.fromErrorMessage(errorMessage),
        kind: kind,
      );

  /// 檢查是否為特定類型的錯誤
  bool isErrorCode(int code) => errorCode == code;

  /// 常見 USP 錯誤碼檢查
  bool get isParameterNotWritable => errorCode == 7004;
  bool get isInvalidParameterName => errorCode == 7005;
  bool get isInvalidParameterValue => errorCode == 7006;
  bool get isParameterNotFound => errorCode == 7026;
  bool get isObjectNotFound => errorCode == 7027;

  /// 檢查錯誤是否可重試（非致命性錯誤）
  bool get isRetryable => switch (errorCode) {
        // 網路相關錯誤通常可重試
        7001 || 7002 || 7003 => true,
        // 參數錯誤通常不可重試
        7004 || 7005 || 7006 || 7026 || 7027 => false,
        // 未知錯誤預設可重試
        _ => true,
      };

  @override
  String toString() =>
      'UspErrorDetail(${kind.name} $requestedPath: $errorCode - $errorMessage)';
}

// =============================================================================
// 實例資料類別
// =============================================================================

/// 更新的實例資訊
class UspUpdatedInstance {
  final String affectedPath;
  final Map<String, String> updatedParams;

  const UspUpdatedInstance({
    required this.affectedPath,
    required this.updatedParams,
  });

  factory UspUpdatedInstance.fromMap(Map<String, dynamic> map) {
    return UspUpdatedInstance(
      affectedPath: map['affectedPath'] as String,
      updatedParams: Map<String, String>.from(map['updatedParams'] ?? {}),
    );
  }

  @override
  String toString() =>
      'UspUpdatedInstance($affectedPath: ${updatedParams.length} params)';
}

/// 創建的實例資訊
class UspCreatedInstance {
  final String affectedPath;
  final Map<String, String> initialParams;

  const UspCreatedInstance({
    required this.affectedPath,
    required this.initialParams,
  });

  factory UspCreatedInstance.fromMap(Map<String, dynamic> map) {
    return UspCreatedInstance(
      affectedPath: map['affectedPath'] as String,
      initialParams: Map<String, String>.from(map['initialParams'] ?? {}),
    );
  }

  @override
  String toString() =>
      'UspCreatedInstance($affectedPath: ${initialParams.length} params)';
}

/// 刪除的實例資訊
class UspDeletedInstance {
  final String affectedPath;

  const UspDeletedInstance({
    required this.affectedPath,
  });

  factory UspDeletedInstance.fromMap(Map<String, dynamic> map) {
    return UspDeletedInstance(
      affectedPath: map['affectedPath'] as String,
    );
  }

  @override
  String toString() => 'UspDeletedInstance($affectedPath)';
}

// =============================================================================
// 具體操作結果類型別名
// =============================================================================

typedef UspSetResult = UspOperationResult<void>;
typedef UspAddResult = UspOperationResult<List<String>>;
typedef UspDeleteResult = UspOperationResult<void>;
typedef UspOperateResult = UspOperationResult<Map<String, dynamic>>;

// =============================================================================
// 結果解析輔助方法
// =============================================================================

/// 從 WASM 回傳的 Map 解析 USP 操作結果
///
/// A write's failures are read from the envelope's `errors` list (usp-client
/// 0.16.0), never from the deprecated `error` map, which the next minor
/// release of the client drops. The two carry the same entries; the list also
/// keeps a second entry under a path the map would overwrite, and says each
/// entry's [UspErrorKind]. Whether a write succeeded, partly succeeded or
/// failed is still `success` plus whether any entry is there; `kind` decides
/// nothing here.
class UspResultParser {
  static const _tag = '[USP][Parser]:';

  /// 解析 SET 操作結果
  static UspSetResult parseSetResult(Map<String, dynamic> map) {
    final result = _parseGenericResult<void>(map);
    _logResult('SET', result);
    return result;
  }

  /// 解析 ADD 操作結果
  ///
  /// WASM v0.11.0 ADD 格式: {success, result: {data: {instances: [...]}}}
  /// 其中 instances 是創建的實例路徑字串陣列，需轉換為 [UspCreatedInstance]
  static UspAddResult parseAddResult(Map<String, dynamic> map) {
    final result = _parseAddResultInternal(map);
    _logResult('ADD', result);
    return result;
  }

  static UspAddResult _parseAddResultInternal(Map<String, dynamic> map) {
    final success = map['success'] as bool? ?? false;
    final resultMap = map['result'] as Map<String, dynamic>? ?? {};
    final data = resultMap['data'] as Map<String, dynamic>? ?? {};
    final failures = _errorDetails(resultMap['errors']);

    if (!success) {
      return UspFailure<List<String>>(failures.isNotEmpty
          ? failures
          : const [
              UspErrorDetail(
                requestedPath: 'add_operation',
                errorCode: -1,
                errorMessage: 'Add operation failed',
              ),
            ]);
    }

    // Extract instances array → UspCreatedInstance list
    final instances = data['instances'] as List? ?? [];
    final createdInstances = instances
        .whereType<String>()
        .map((path) => UspCreatedInstance(
              affectedPath: path,
              initialParams: const {},
            ))
        .toList();

    final successes = [
      UspSuccessDetail(
        requestedPath: 'add_operation',
        createdInstances: createdInstances,
        retrievedParams: data,
      ),
    ];

    if (failures.isNotEmpty) {
      return UspPartialSuccess<List<String>>(successes, failures);
    }

    return UspSuccess<List<String>>(successes);
  }

  /// 解析 DELETE 操作結果
  static UspDeleteResult parseDeleteResult(Map<String, dynamic> map) {
    final result = _parseGenericResult<void>(map);
    _logResult('DELETE', result);
    return result;
  }

  /// 解析 OPERATE 操作結果
  static UspOperateResult parseOperateResult(Map<String, dynamic> map) {
    final result = _parseGenericResult<Map<String, dynamic>>(map);
    _logResult('OPERATE', result);
    return result;
  }

  /// 解析 unified 格式：{success, result: {data, errors?}}
  static UspOperationResult<T> _parseGenericResult<T>(
      Map<String, dynamic> map) {
    final success = map['success'] as bool? ?? false;
    final result = map['result'] as Map<String, dynamic>? ?? {};
    final data = result['data'] as Map<String, dynamic>? ?? {};
    final failures = _errorDetails(result['errors']);

    final successes = <UspSuccessDetail>[];

    if (success && failures.isEmpty) {
      // All success: success=true, no errors
      successes.add(UspSuccessDetail(
        requestedPath: 'bulk_operation',
        retrievedParams: data,
      ));
      return UspSuccess<T>(successes);
    } else if (success) {
      // Partial success: success=true, but errors has entries
      if (data.isNotEmpty) {
        successes.add(UspSuccessDetail(
          requestedPath: 'bulk_operation',
          retrievedParams: data,
        ));
      }

      return UspPartialSuccess<T>(successes, failures);
    } else {
      // All failure: success=false. No specific error info → generic failure
      return UspFailure<T>(failures.isNotEmpty
          ? failures
          : const [
              UspErrorDetail(
                requestedPath: 'bulk_operation',
                errorCode: -1,
                errorMessage: 'Operation failed',
              ),
            ]);
    }
  }

  /// The envelope's `errors` list, one detail per entry, in the order the
  /// answer gives them, each with the reason its message names
  /// ([UspErrorDetail.fromResponse]).
  ///
  /// An entry that names no path (a 9997 for input the client could not read)
  /// is keyed `''`, as the `error` map keys it.
  static List<UspErrorDetail> _errorDetails(Object? errors) => [
        if (errors is List)
          for (final entry in errors)
            if (entry is Map)
              UspErrorDetail.fromResponse(
                requestedPath: entry['path'] as String? ?? '',
                errorCode: entry['errorCode'] as int? ?? -1,
                errorMessage:
                    entry['errorMessage'] as String? ?? 'Unknown error',
                kind: UspErrorKind.fromWire(entry['kind']),
              ),
      ];

  /// 創建空的成功結果（當沒有參數需要操作時）
  static UspOperationResult<T> createEmptySuccess<T>() {
    return const UspSuccess<Never>([]) as UspOperationResult<T>;
  }

  /// 從異常創建失敗結果
  static UspOperationResult<T> createFailureFromException<T>(
    Object exception,
    String requestedPath,
  ) {
    return UspFailure<T>([
      UspErrorDetail(
        requestedPath: requestedPath,
        errorCode: -1,
        errorMessage: exception.toString(),
      )
    ]);
  }

  /// `<path>=<code> (<kind>)`, so a bench log tells a request the router
  /// refused as a whole from one parameter it refused.
  static String _logEntry(UspErrorDetail f) =>
      '${f.requestedPath}=${f.errorCode} (${f.kind.name})';

  static void _logResult<T>(String op, UspOperationResult<T> result) {
    switch (result) {
      case UspSuccess(details: final details):
        logger.d('$_tag $op → UspSuccess (${details.length} details)');
      case UspPartialSuccess(
          successes: final successes,
          failures: final failures
        ):
        logger.w('$_tag $op → UspPartialSuccess '
            '(${successes.length} successes, ${failures.length} failures: '
            '${failures.map(_logEntry).join(', ')})');
      case UspFailure(errors: final errors):
        logger.w('$_tag $op → UspFailure '
            '(${errors.length} errors: ${errors.map(_logEntry).join(', ')})');
    }
  }
}
