import 'dart:async';

import 'package:linksys_app/core/jnap/jnap_command_executor_mixin.dart';
import 'package:linksys_app/core/jnap/spec/jnap_spec.dart';

import '../../cache/linksys_cache_manager.dart';

enum CacheLevel { localCached, noCache }

abstract class BaseCommand<R, S extends JNAPSpec> {
  BaseCommand(
      {required this.spec,
      required this.executor,
      this.force = false,
      this.cacheLevel = CacheLevel.localCached});

  final S spec;
  final JNAPCommandExecutor executor;
  final Completer<(R, DataSource)> _completer = Completer();
  final bool force;
  final CacheLevel cacheLevel;

  Future<R> publish();

  bool isComplete() => _completer.isCompleted;

  complete((R result, DataSource ds) record) => _completer.complete(record);

  completeError(Object? error, StackTrace stackTrace) =>
      _completer.completeError(error ?? UnsupportedError, stackTrace);

  Future<(R, DataSource)> wait() => _completer.future;

  R createResponse(String payload) => spec.response(payload);
}
