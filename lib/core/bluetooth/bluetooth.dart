import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:linksys_moab/core/bluetooth/exceptions.dart';
import 'package:linksys_moab/core/jnap/command/base_command.dart';
import 'package:linksys_moab/core/jnap/command/bt_base_command.dart';
import 'package:linksys_moab/core/jnap/jnap_command_executor_mixin.dart';
import 'package:linksys_moab/core/jnap/result/jnap_result.dart';
import 'package:linksys_moab/core/utils/logger.dart';

part 'bluetooth_command_wrap.dart';

const _jnapService = '00002080-8eab-46c2-b788-0e9440016fd1';
const _controlPoint = '00002081-8eab-46c2-b788-0e9440016fd1';
const _jnapData = '00002082-8eab-46c2-b788-0e9440016fd1';

const _belkinMFG = 0x005c;
const _linksysMFG = 0x0bee;
const _acceptMFG = [_belkinMFG, _linksysMFG];
const _mfcSpecUnConfig = 0x00;
const _mfcSpecUnConfigMasterOnly = 0x04;
const _mfcSpecUnConfigSlaveOnly = 0x08;
const _mfcSpecs = [
  _mfcSpecUnConfig,
  _mfcSpecUnConfigMasterOnly,
  _mfcSpecUnConfigSlaveOnly
];

class BluetoothManager with JNAPCommandExecutor<JNAPResult> {
  final int _maxRetry = 3;
  final int _retryTimeInSec = 5;
  Future Function(int retry, Object? error)? _onRetry;

  set maxRetry(int maxRetry) => _maxRetry;

  set retryTimeInSec(int timeInSec) => _retryTimeInSec;

  set onRetryCallback(Future Function(int retry, Object? error) onRetry) =>
      _onRetry;

  factory BluetoothManager() {
    _singleton ??= BluetoothManager._();
    return _singleton!;
  }

  BluetoothManager._();

  static BluetoothManager? _singleton;

  StreamSubscription? _subscription;
  final List<ScanResult> _results = [];

  List<ScanResult> get results => _results;
  BluetoothDevice? _connectedDevice;

  scan({int durationInSec = 10}) async {
    _subscription?.cancel();
    _results.clear();
    _subscription = FlutterBluePlus.scanResults.listen((results) {
      final filtered = results
          .where((result) => _checkAdvertisementData(result.advertisementData));
      for (ScanResult result in filtered) {
        logger.d(
            'BT scan result: ${result.device.name} found! <${result.device}>, rssi: ${result.rssi}, advertisementData: ${result.advertisementData}');
        final isExist =
            _results.any((element) => element.device.id == result.device.id);
        if (isExist) {
          final index = _results
              .indexWhere((element) => element.device.id == result.device.id);
          _results.replaceRange(index, index + 1, [result]);
        } else {
          _results.add(result);
        }
      }
    });

    logger.d('BT scan start');
    await FlutterBluePlus.startScan(
        timeout: Duration(seconds: durationInSec),
        withServices: [Guid(_jnapService)]);
    logger.d('BT scan done');
  }

  // Throw timeout exception when timeout occurs
  connect(BluetoothDevice device, {int durationInSec = 120}) async {
    try {
      logger.d('BT start to connect to $device');
      await device.connect(timeout: Duration(seconds: durationInSec));
      logger.d('BT ${device.id} connected');
      final services = await device.discoverServices();
      logger.d('BT Services on ${device.id}');
      for (var service in services) {
        logger.d('BT Service: $service');
      }
    } catch (e) {
      logger.e('BT connect error', e);
      throw BTDeviceConnectionError(device.id.id);
    }
    _connectedDevice = device;
  }

  disconnect() async {
    await _connectedDevice?.disconnect();
  }

  bool _checkAdvertisementData(AdvertisementData data) {
    final mData = data.manufacturerData.entries
        .firstWhereOrNull((entry) => _acceptMFG.contains(entry.key));
    if (mData == null) {
      return false;
    }
    final isBackhaulStatusUp = mData.value[0];
    final modeLimitationType =
        mData.value[1]; // ML - 0:No Limitation, 4:Only Slave, 8:Only Master
    return isBackhaulStatusUp == 0 && _mfcSpecs.contains(modeLimitationType);
  }

  @override
  void dropCommand(String id) {}

  @override
  Future<JNAPResult> execute(BaseCommand command) async {
    final btCommand = command as JNAPBTCommand?;
    logger.d('BT execute JNAP command: ${command.spec.action}');
    if (btCommand == null) {
      // invalid JNAP command
      throw BTInvalidJNAPCommandError();
    }
    if (_connectedDevice == null) {
      throw BTNoConnectedDeviceError();
    }

    final result = await send(btCommand);

    if (result == null) {
      throw BTNoResponseError();
    } else {
      return result;
    }
  }

  Future<JNAPResult?> send(JNAPBTCommand command) async {
    int retry = 0;
    for (;;) {
      final commandWrap = BluetoothCommandWrap(command: command);
      logger.d('BT send command wrap: $commandWrap');
      try {
        await commandWrap.execute(_connectedDevice!);
      } catch (e) {
        if (retry == _maxRetry) {
          rethrow;
        }
      }

      final result = commandWrap.result;
      JNAPResult? response;
      if (result != null) {
        response = command.createResponse(result);
        if (response is JNAPSuccess) {
          return response;
        }
      }
      if (retry == _maxRetry) {
        return response;
      }

      await Future<void>.delayed(_defaultDelay(retry));
      await _onRetry?.call(retry, response);
      retry++;
    }
  }

  Duration _defaultDelay(int retryCount) =>
      Duration(seconds: _retryTimeInSec) * math.pow(1.5, retryCount);
}
