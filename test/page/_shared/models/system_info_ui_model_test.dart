import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';

SystemInfoUIModel _model(
        {String? userDeviceLocation, String? friendlyName, String? hostName}) =>
    SystemInfoUIModel(
      manufacturer: 'Linksys',
      modelName: 'M60',
      serialNumber: 'SN1',
      hardwareVersion: '1.0',
      softwareVersion: '2.0.3',
      uptime: 0,
      totalMemory: 0,
      freeMemory: 0,
      cpuUsage: 0,
      userDeviceLocation: userDeviceLocation,
      friendlyName: friendlyName,
      hostName: hostName,
    );

void main() {
  // The router's name (#1691) reaches the master node through this model, and
  // `systemInfoDataProvider` only notifies when it is not equal to the last
  // one. So both name fields have to take part in equality, or a rename would
  // be read back and never shown.
  group('SystemInfoUIModel router name (#1691)', () {
    test('the location takes part in equality', () {
      expect(_model(userDeviceLocation: 'Office'),
          equals(_model(userDeviceLocation: 'Office')));
      expect(_model(userDeviceLocation: 'Office'),
          isNot(equals(_model(userDeviceLocation: 'Study'))));
      expect(_model(userDeviceLocation: 'Office'), isNot(equals(_model())));
    });

    test('FriendlyName takes part in equality', () {
      expect(_model(friendlyName: 'Main'),
          isNot(equals(_model(friendlyName: 'Other'))));
    });
    // The controller's name when the user gave none (#1751): equal models
    // would hide a host name that changed or appeared.
    test('the host name takes part in equality', () {
      expect(_model(hostName: 'Linksys12345'),
          isNot(equals(_model(hostName: 'Linksys67890'))));
      expect(_model(hostName: 'Linksys12345'), isNot(equals(_model())));
    });
  });
}
