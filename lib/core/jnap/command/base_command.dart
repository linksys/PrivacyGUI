import 'dart:async';

import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/jnap_command_executor_mixin.dart';
import 'package:privacy_gui/core/jnap/spec/jnap_spec.dart';

enum CacheLevel { localCached, noCache }

abstract class BaseCommand<R, S extends JNAPSpec> {
  BaseCommand({
    required this.spec,
    required this.executor,
    this.fetchRemote = false,
    this.cacheLevel = CacheLevel.localCached,
  });

  final S spec;
  final JNAPCommandExecutor executor;
  final Completer<R> _completer = Completer();
  final bool fetchRemote;
  final CacheLevel cacheLevel;

  Future<R> publish();

  bool isComplete() => _completer.isCompleted;

  complete(R result) => _completer.complete(result);

  completeError(Object? error, StackTrace stackTrace) =>
      _completer.completeError(error ?? UnsupportedError, stackTrace);

  Future<R> wait() => _completer.future;

  R createResponse(String payload) => spec.response(payload);

  bool checkCacheValidation(LinksysCacheManager cache) => !fetchRemote;
}
