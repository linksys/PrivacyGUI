import 'package:flutter/foundation.dart';

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

/// 失敗操作的詳細資訊
class UspErrorDetail {
  final String requestedPath;
  final int errorCode;
  final String errorMessage;

  const UspErrorDetail({
    required this.requestedPath,
    required this.errorCode,
    required this.errorMessage,
  });

  factory UspErrorDetail.fromMap(Map<String, dynamic> map) {
    return UspErrorDetail(
      requestedPath: map['requestedPath'] as String,
      errorCode: map['errorCode'] as int? ?? -1,
      errorMessage: map['errorMessage'] as String? ?? 'Unknown error',
    );
  }

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
      'UspErrorDetail($requestedPath: $errorCode - $errorMessage)';
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
typedef UspGetResult = UspOperationResult<Map<String, dynamic>>;
typedef UspOperateResult = UspOperationResult<Map<String, dynamic>>;

// =============================================================================
// 結果解析輔助方法
// =============================================================================

/// 從 WASM 回傳的 Map 解析 USP 操作結果
class UspResultParser {
  /// 解析 SET 操作結果
  static UspSetResult parseSetResult(Map<String, dynamic> map) {
    final result = _parseGenericResult<void>(map);

    // Debug logging to track parsing results
    if (kDebugMode) {
      final success = map['success'] as bool? ?? false;
      print('[UspResultParser] SET parseResult: success=$success, result=${result.runtimeType}');
      if (result is UspFailure) {
        print('[UspResultParser] SET failure: ${result.errorSummary}');
      }
    }

    return result;
  }

  /// 解析 ADD 操作結果
  static UspAddResult parseAddResult(Map<String, dynamic> map) {
    final result = _parseGenericResult<List<String>>(map);
    // ADD 操作的特殊處理：從 createdInstances 中提取實例路徑
    return result;
  }

  /// 解析 DELETE 操作結果
  static UspDeleteResult parseDeleteResult(Map<String, dynamic> map) {
    return _parseGenericResult<void>(map);
  }

  /// 解析 GET 操作結果
  static UspGetResult parseGetResult(Map<String, dynamic> map) {
    return _parseGenericResult<Map<String, dynamic>>(map);
  }

  /// 解析 OPERATE 操作結果
  static UspOperateResult parseOperateResult(Map<String, dynamic> map) {
    return _parseGenericResult<Map<String, dynamic>>(map);
  }

  /// 解析 WASM v0.11.0 格式：{success, result: {data, error?}}
  static UspOperationResult<T> _parseGenericResult<T>(
      Map<String, dynamic> map) {
    final success = map['success'] as bool? ?? false;
    final result = map['result'] as Map<String, dynamic>? ?? {};
    final data = result['data'] as Map<String, dynamic>? ?? {};
    final error = result['error'] as Map<String, dynamic>?;

    final successes = <UspSuccessDetail>[];
    final failures = <UspErrorDetail>[];

    if (success && error == null) {
      // All success: success=true, no error field
      successes.add(UspSuccessDetail(
        requestedPath: 'bulk_operation',
        retrievedParams: data,
      ));
      return UspSuccess<T>(successes);
    } else if (success && error != null) {
      // Partial success: success=true, but has error field
      if (data.isNotEmpty) {
        successes.add(UspSuccessDetail(
          requestedPath: 'bulk_operation',
          retrievedParams: data,
        ));
      }

      for (final entry in error.entries) {
        final path = entry.key;
        final errorInfo = entry.value as Map<String, dynamic>;
        failures.add(UspErrorDetail(
          requestedPath: path,
          errorCode: errorInfo['errorCode'] as int? ?? -1,
          errorMessage: errorInfo['errorMessage'] as String? ?? 'Unknown error',
        ));
      }

      return UspPartialSuccess<T>(successes, failures);
    } else {
      // All failure: success=false
      if (error != null) {
        for (final entry in error.entries) {
          final path = entry.key;
          final errorInfo = entry.value as Map<String, dynamic>;
          failures.add(UspErrorDetail(
            requestedPath: path,
            errorCode: errorInfo['errorCode'] as int? ?? -1,
            errorMessage:
                errorInfo['errorMessage'] as String? ?? 'Unknown error',
          ));
        }
      } else {
        // No specific error info, create generic failure
        failures.add(const UspErrorDetail(
          requestedPath: 'bulk_operation',
          errorCode: -1,
          errorMessage: 'Operation failed',
        ));
      }

      return UspFailure<T>(failures);
    }
  }

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
}
