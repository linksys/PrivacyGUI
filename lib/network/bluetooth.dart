import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:linksys_moab/util/logger.dart';

const _jnapService = "00002080-8eab-46c2-b788-0e9440016fd1";
const _belkinMFG = 0x005c;
const _linksysMFG = 0x0bee;
const _acceptMFG = [_belkinMFG, _linksysMFG];
const _mfcSpecUnConfig = 0x00;
const _mfcSpecUnConfigMasterOnly = 0x04;
const _mfcSpecUnConfigSlaveOnly = 0x08;
const _mfcSpecs = [_mfcSpecUnConfig, _mfcSpecUnConfigMasterOnly, _mfcSpecUnConfigSlaveOnly];

class BluetoothManager {
  factory BluetoothManager() {
    _singleton ??= BluetoothManager._();
    return _singleton!;
  }

  BluetoothManager._();

  static BluetoothManager? _singleton;

  StreamSubscription? _subscription;
  List _result = [];

  scan({int durationInSec = 10}) async {
    FlutterBluePlus instance = FlutterBluePlus.instance;
    _subscription?.cancel();
    _result.clear();
    _subscription = instance.scanResults.listen((results) {
      final filtered = results.where((result) => _checkAdvertisementData(result.advertisementData));
      for (ScanResult result in filtered) {
        logger.d(
            'BT scan result: ${result.device.name} found! <${result.device}>, rssi: ${result.rssi}, advertisementData: ${result.advertisementData}');

        _result.add(result);
      }
    });

    logger.d('BT scan start');
    await instance.startScan(timeout: Duration(seconds: durationInSec), withServices: [Guid(_jnapService)]);
    logger.d('BT scan done');
  }

  bool _checkAdvertisementData(AdvertisementData data) {
    final mData = data.manufacturerData.entries.firstWhereOrNull((entry) => _acceptMFG.contains(entry.key));
    if (mData == null) {
      return false;
    }
    final isBackhaulStatusUp = mData.value[0];
    final modeLimitationType = mData.value[1]; // ML - 0:No Limitation, 4:Only Slave, 8:Only Master
    return isBackhaulStatusUp == 0 && _mfcSpecs.contains(modeLimitationType);
  }
}
