import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/cache/linksys_cache_manager.dart';
import 'package:linksys_app/core/jnap/command/http_base_command.dart';
import 'package:linksys_app/core/utils/logger.dart';

import '../../constants/jnap_const.dart';
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
    if (_checkUseCacheDataForJnapHttpCommand(command)) {
      logger.d(
          'linksys cache manager: responsed with local cache data: ${command.spec.action}');
      command.complete((
        command.createResponse(
            jsonEncode(linksysCacheManger.data[command.spec.action]["data"])),
        DataSource.fromCache
      ));
    } else if (_checkUseCacheDataForJnapTransactionCommand(command)) {
      final dataMap = _buildTransacationData(command);
      command.complete((
        command.createResponse((jsonEncode(dataMap))),
        DataSource.fromCache
      ));
    } else {
      command
          .publish()
          .then((value) => command.complete((value, DataSource.fromRemote)))
          .onError(
              (error, stackTrace) => command.completeError(error, stackTrace));
    }
    _emptyRetry = 0;
  }

  Future enqueue(BaseCommand command) {
    if (!(_timer?.isActive ?? false)) {
      _startConsume();
    }
    _queue.add(command);
    logger.d(
        'Command Queue:: enqueue command ${command.runtimeType}, ${command.spec.action}');
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

  bool _checkNonExistActionAndExpiration(
      BaseCommand command, LinksysCacheManager cacheManager) {
    for (var element in (jsonDecode(command.spec.payload()) as List<dynamic>)) {
      if (!cacheManager.data.containsKey(element["action"]) ||
          cacheManager
              .didCacheExpire(cacheManager.data[element["action"]]["target"])) {
        return true;
      }
    }
    return false;
  }

  bool _checkUseCacheDataForJnapHttpCommand(BaseCommand command) {
    if (command is JNAPHttpCommand &&
        linksysCacheManger.data.containsKey(command.spec.action) &&
        linksysCacheManger.data[command.spec.action] != null &&
        !command.force &&
        !linksysCacheManger.didCacheExpire(command.spec.action)) {
      return true;
    } else {
      return false;
    }
  }

  bool _checkUseCacheDataForJnapTransactionCommand(BaseCommand command) {
    if (command is TransactionHttpCommand &&
        !_checkNonExistActionAndExpiration(command, linksysCacheManger)) {
      return true;
    } else {
      return false;
    }
  }

  Map<String, dynamic> _buildTransacationData(BaseCommand command) {
    final actions = [];
    for (var element in (jsonDecode(command.spec.payload()) as List<dynamic>)) {
      actions.add(linksysCacheManger.data[element["action"]]["data"]);
    }
    final dataMap = {keyJnapResult: jnapResultOk, keyJnapResponses: actions};
    logger.d(
        'linksys cache manager: responsed with local cache transaction: $dataMap');
    return dataMap;
  }
}
