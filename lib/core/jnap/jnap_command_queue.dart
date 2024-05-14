import 'dart:async';
import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/utils/logger.dart';

import 'command/base_command.dart';

class CommandQueue {
  static const int _maxEmptyRetry = 60;
  static CommandQueue? _singleton;
  final Queue<BaseCommand> _queue = Queue();
  bool _isPause = false;
  final linksysCacheManger =
      ProviderContainer().read(linksysCacheManagerProvider);

  set pause(bool pause) {
    logger.d('Command Queue:: pause: $_isPause');
    _isPause = pause;
  }

  Timer? _timer;

  int _emptyRetry = 0;

  factory CommandQueue() {
    _singleton ??= CommandQueue._();
    return _singleton!;
  }

  CommandQueue._();

  _consumeCommand(Timer timer) {
    if (_isPause) {
      return;
    }
    // Consume the command
    if (_queue.isEmpty) {
      _emptyRetry++;
      _stopConsume();
      return;
    }

    final command = _queue.removeFirst();
    logger.d(
        'Command Queue <${_queue.length}>:: handle command: ${command.runtimeType}, ${command.spec.action}');
    command.publish().then((value) => command.complete(value)).onError(
        (error, stackTrace) => command.completeError(error, stackTrace));
    _emptyRetry = 0;
  }

  Future enqueue(BaseCommand command) {
    if (!(_timer?.isActive ?? false)) {
      _startConsume();
    }
    _queue.add(command);
    logger.d(
        'Command Queue:: enqueue command ${command.runtimeType}, ${command.spec.action}');
    return command.wait();
  }

  _startConsume() {
    if (_timer?.isActive ?? false) {
      return;
    }
    _emptyRetry = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), _consumeCommand);
    logger.d('Command Queue:: start to consume commands!');
  }

  _stopConsume() {
    if ((_timer?.isActive ?? false) && _emptyRetry >= _maxEmptyRetry) {
      logger.d('Command Queue:: exceed to empty retry, stop!');
      _timer?.cancel();
    }
  }
}
