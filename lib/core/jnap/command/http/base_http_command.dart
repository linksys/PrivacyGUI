import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/http/jnap_retry_options.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/spec/jnap_spec.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'jnap_http_command.dart';
part 'transaction_http_command.dart';

abstract class BaseHttpCommand<R, S extends JNAPSpec>
    extends BaseCommand<R, S> {
  BaseHttpCommand({
    required this.url,
    required super.spec,
    required super.executor,
    super.fetchRemote,
    super.cacheLevel,
    this.retryOptions = const JNAPRetryOptions(),
  });

  final String url;

  String _data = '';

  String get data => _data;

  Map<String, String> _header = {};

  Map<String, String> get header => _header;

  int currentRetry = 0;
  final JNAPRetryOptions retryOptions;

  Future<R> handleJNAPError(error) async {
    if (retryOptions.exceedMaxRetry(currentRetry)) {
      logger.d(
          'JNAP<${spec.action}> Error<$error> exceed MAX retry, throw error');
      throw error;
    }
    final delay = retryOptions.getRetryDelay(currentRetry);
    logger.d(
        'JNAP<${spec.action}> Error<$error> do ${currentRetry + 1} retry after ${delay.inMilliseconds}ms');
    await Future.delayed(delay);
    // Handle JNAP Errors,
    currentRetry++;
    logger.d('JNAP<${spec.action}> Error<$error> do $currentRetry retry');
    return publish();
  }

  bool errorTest(error) =>
      error is JNAPError && errorJNAPRetryList.contains(error.result);
}
