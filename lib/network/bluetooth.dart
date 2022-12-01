import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:linksys_moab/network/jnap/command/base_command.dart';
import 'package:linksys_moab/network/jnap/jnap_command_executor_mixin.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/util/logger.dart';

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

const _host = "Host:www.linksyssmartwifi.com";
var _baseAction = "X-JNAP-Action:http://linksys.com/jnap";
var _contentType = "Content-Type:application/json; charset=utf-8";
var _auth = "X-JNAP-Authorization:Basic YWRtaW46YWRtaW4=";

class BluetoothManager with JNAPCommandExecutor {
  factory BluetoothManager() {
    _singleton ??= BluetoothManager._();
    return _singleton!;
  }

  BluetoothManager._();

  static BluetoothManager? _singleton;

  StreamSubscription? _subscription;
  final List<ScanResult> _results = [];

  scan({int durationInSec = 10}) async {
    FlutterBluePlus instance = FlutterBluePlus.instance;
    _subscription?.cancel();
    _results.clear();
    _subscription = instance.scanResults.listen((results) {
      final filtered = results
          .where((result) => _checkAdvertisementData(result.advertisementData));
      for (ScanResult result in filtered) {
        logger.d(
            'BT scan result: ${result.device.name} found! <${result.device}>, rssi: ${result.rssi}, advertisementData: ${result.advertisementData}');

        _results.add(result);
      }
    });

    logger.d('BT scan start');
    await instance.startScan(
        timeout: Duration(seconds: durationInSec),
        withServices: [Guid(_jnapService)]);
    logger.d('BT scan done');
    if (_results.isNotEmpty) {
      connect(_results[0].device);
    }
  }

  connect(BluetoothDevice device) async {
    await device.connect();
    final services = await device.discoverServices();
    logger.d('Services on ${device.id}');
    for (var service in services) {
      logger.d('Service: $service');
    }
    final characteristics = services[0].characteristics.firstWhereOrNull((element) => element.uuid.toString() == _jnapData);
    if (characteristics != null) {
      final response = await characteristics.write(_buildPayload('/nodes/setup/GetMACAddress').codeUnits);
      logger.d('RESPONSE: $response');
      final result = String.fromCharCodes(await characteristics.read());
      logger.d('RESULT: $result');
    }
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

  String _buildPayload(String action, {Map<String, dynamic> data = const {}}) {
    return '$_host\n$_baseAction$action\n$_auth\n$_contentType\n${jsonEncode(data)}\n';
  }

  @override
  void dropCommand(String id) {}

  @override
  Future execute(BaseCommand command) {
    // TODO: implement execute
    throw UnimplementedError();
  }
}
