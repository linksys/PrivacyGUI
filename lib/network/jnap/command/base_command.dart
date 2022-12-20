import 'dart:async';

import 'package:linksys_moab/network/jnap/jnap_command_executor_mixin.dart';
import 'package:linksys_moab/network/jnap/spec/jnap_spec.dart';

abstract class BaseCommand<R, S extends JNAPSpec> {
  BaseCommand({required this.spec, required this.executor});

  final S spec;
  final JNAPCommandExecutor executor;
  final Completer<R> _completer = Completer();

  Future<R> publish();

  bool isComplete() => _completer.isCompleted;

  complete(R result) => _completer.complete(result);

  completeError(Object? error, StackTrace stackTrace) =>
      _completer.completeError(error ?? UnsupportedError, stackTrace);

  Future<R> wait() => _completer.future;
}
