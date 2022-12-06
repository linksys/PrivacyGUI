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

  static BTControlFlow? get(String value, {String? encodedLength}) {
    return BTControlFlow.values
            .firstWhereOrNull((element) => element.value == value) ??
        (value == encodedLength ? BTControlFlow.lens : null);
  }
}

class BluetoothCommandWrap {
  BTControlFlow _flow = BTControlFlow.none;

  String? _result;

  String? get result => _result;

  late String encodedLen;

  // TODO maybe doesn't need this characteristic
  BluetoothCharacteristic? _jnapCharacteristic;
  BluetoothCharacteristic? _ctrlCharacteristic;

  final JNAPBTCommand command;
  StreamSubscription? _ctrlSubscription;
  StreamSubscription? _jnapSubscription;
  final Completer _completer = Completer();

  BluetoothCommandWrap({
    required this.command,
  }) {
    encodedLen =
        base64Encode([0, 3, ...'${command.spec.encodedLength}'.codeUnits]);
  }

  Future execute(BluetoothDevice device) async {
    final services = await device.discoverServices() ?? [];
    if (services.isEmpty) {
      // No service found
      throw BTNoServicesFoundError(device.id.id);
    }
    final service = services
        .firstWhereOrNull((element) => element.uuid.toString() == _jnapService);
    if (service == null) {
      throw BTJNAPServiceNotFoundError(device.id.id);
    }

    await _findCharacteristics(service);
    if (_ctrlCharacteristic == null || _jnapCharacteristic == null) {
      throw BTNoCharacteristicFoundError();
    }
    await _subscribe(service);

    logger.d('Start send command');
    await _ctrlCharacteristic?.write(base64Decode(BTControlFlow.init.value));
    logger.d('Done send command');
    return _completer.future;
  }

  _findCharacteristics(BluetoothService service) {
    _jnapCharacteristic = service.characteristics
        .firstWhereOrNull((element) => element.uuid.toString() == _jnapData);
    _ctrlCharacteristic = service.characteristics.firstWhereOrNull(
        (element) => element.uuid.toString() == _controlPoint);
  }

  _subscribe(BluetoothService service) async {
    await _jnapCharacteristic?.setNotifyValue(true);
    _jnapSubscription = _jnapCharacteristic?.value.listen((value) {
      logger.d('JNAP Notify changed: ${String.fromCharCodes(value)}');
    });
    await _ctrlCharacteristic?.setNotifyValue(true);
    _ctrlSubscription = _ctrlCharacteristic?.value.listen(_processFlow);
  }

  _unsubscribe() async {
    await _jnapCharacteristic?.setNotifyValue(false);
    await _ctrlCharacteristic?.setNotifyValue(false);
    _jnapSubscription?.cancel();
    _ctrlSubscription?.cancel();
  }

  _processFlow(List<int> value) async {
    logger.d(
        'Control Point Notify changed: ${base64Encode(value)}, value: $value');
    if (value.isEmpty) {
      return;
    }
    String result = base64Encode(value);
    _nextFlow(result, encodedLen);
    logger.d('BT Control Next flow $_flow, with result $result');
    switch (_flow) {
      case BTControlFlow.init:
        await _ctrlCharacteristic
            ?.write(base64Decode(BTControlFlow.start.value));
        break;
      case BTControlFlow.start:
        await _ctrlCharacteristic?.write(
            [0, 3, ...'${command.spec.payload().codeUnits.length}'.codeUnits]);
        break;
      case BTControlFlow.stop:
        final last =
            String.fromCharCodes(await _jnapCharacteristic?.read() ?? []);
        _result = last;
        logger
            .d('BT Command Result:: ${command.spec.action}: $_flow, $_result');
        if (!_completer.isCompleted) {
          await _unsubscribe();
          _completer.complete();
        }
        return;
      case BTControlFlow.data:
        await _ctrlCharacteristic
            ?.write(base64Decode(BTControlFlow.stop.value));
        break;
      case BTControlFlow.lens:
        logger.i('BT Send command: ${command.spec.payload()}');
        await _jnapCharacteristic?.write(command.spec.payload().codeUnits);
        break;
      default:
        break;
    }
  }

  _nextFlow(String next, String? encodedLength) {
    if (next.isEmpty) {
      return;
    }
    BTControlFlow accepted = _flow;
    switch (_flow) {
      case BTControlFlow.none:
        accepted = next == BTControlFlow.init.value
            ? BTControlFlow.get(next) ?? _flow
            : accepted;
        break;
      case BTControlFlow.init:
        accepted = next == BTControlFlow.start.value
            ? BTControlFlow.get(next) ?? _flow
            : accepted;
        break;
      case BTControlFlow.start:
        accepted = next == encodedLength
            ? BTControlFlow.get(next, encodedLength: encodedLength) ?? _flow
            : accepted;
        break;
      case BTControlFlow.stop:
        accepted = BTControlFlow.none;
        break;
      case BTControlFlow.data:
        accepted = next == BTControlFlow.stop.value
            ? BTControlFlow.get(next) ?? _flow
            : accepted;
        break;
      case BTControlFlow.lens:
        accepted = next == BTControlFlow.data.value
            ? BTControlFlow.get(next) ?? _flow
            : accepted;
        break;
    }
    _flow = accepted;
  }
}
