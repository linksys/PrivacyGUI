part of 'bluetooth.dart';

enum BTControlFlow {
  none('none'),
  init('AAE='),
  start('AAI='),
  stop('AAU='),
  data('BAAAAA=='),
  lens('lens');

  const BTControlFlow(this.value);

  final String value;

  static BTControlFlow get(String value) {
    return BTControlFlow.values
            .firstWhereOrNull((element) => element.value == value) ??
        (int.tryParse(value) != null ? BTControlFlow.lens : null) ??
        BTControlFlow.data;
  }
}

class BluetoothCommandWrap {
  BTControlFlow _flow = BTControlFlow.none;
  String? _result;
  String? get result => _result;

  final JNAPBTCommand command;

  BluetoothCommandWrap({
    required this.command,
  });

  Future execute(BluetoothDevice device) async {
    final services = await device.discoverServices() ?? [];
    if (services.isEmpty) {
      // No service found
      throw BTError(
          code: 'services_not_found',
          message: 'BT connected device no services found');
    }
    final service = services
        .firstWhereOrNull((element) => element.uuid.toString() == _jnapService);
    if (service == null) {
      throw BTError(
          code: 'jnap_service_not_found',
          message: 'BT connected device no jnap service found');
    }
    logger.d('Start send command');
    await _sendCommand(service);
    logger.d('Done send command');
  }

  Future _sendCommand(BluetoothService service) async {
    final jnapCharacteristics = service.characteristics
        .firstWhereOrNull((element) => element.uuid.toString() == _jnapData);
    final ctrlCharacteristics = service.characteristics.firstWhereOrNull(
        (element) => element.uuid.toString() == _controlPoint);
    String result;
    switch (_flow) {
      case BTControlFlow.none:
        await ctrlCharacteristics?.write(BTControlFlow.init.value.codeUnits);
        result = String.fromCharCodes(await ctrlCharacteristics?.read() ?? []);
        break;
      case BTControlFlow.init:
        await ctrlCharacteristics?.write(BTControlFlow.start.value.codeUnits);
        result = String.fromCharCodes(await ctrlCharacteristics?.read() ?? []);
        break;
      case BTControlFlow.start:
        await ctrlCharacteristics?.write('${command.spec.payload().length}'.codeUnits);
        result = String.fromCharCodes(await ctrlCharacteristics?.read() ?? []);
        break;
      case BTControlFlow.stop:
        final last = String.fromCharCodes(await jnapCharacteristics?.read() ?? []);
        logger.d('BT Control Result $_flow, $_result, last read:$last');
        _result = last;
        return;
      case BTControlFlow.data:
        await ctrlCharacteristics?.write(BTControlFlow.stop.value.codeUnits);
        result = String.fromCharCodes(await ctrlCharacteristics?.read() ?? []);
        break;
      case BTControlFlow.lens:
        logger.i('BT Send command: ${command.spec.payload()}');
        await jnapCharacteristics?.write(command.spec.payload().codeUnits);
        result = String.fromCharCodes(await jnapCharacteristics?.read() ?? []);
        break;
    }
    _flow = BTControlFlow.get(result);
    logger.d('BT Control Next flow $_flow, with result $result');
    await _sendCommand(service);
  }
}
