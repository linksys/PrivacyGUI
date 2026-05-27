import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';

/// Test data builder for the manual firmware update flow.
///
/// Provides raw USP `Get` response shapes for `Device.DeviceInfo.FirmwareImage.*`
/// so service-level tests can stub `UspClient.get()` realistically, plus
/// `FirmwareImageUIModel` factories for notifier / view tests.
class FirmwareUpdateTestData {
  // ---------------------------------------------------------------------------
  // Raw USP Get response shapes
  // ---------------------------------------------------------------------------

  /// Two-bank response: instance 1 active, instance 2 available.
  static Map<String, dynamic> dualBankResponse({
    String activeVersion = '1.0.16.26013014',
    String availableVersion = '1.0.15.25090212',
  }) =>
      <String, dynamic>{
        'Device.DeviceInfo.FirmwareImage.1.Name': 'Bank1',
        'Device.DeviceInfo.FirmwareImage.1.Version': activeVersion,
        'Device.DeviceInfo.FirmwareImage.1.Status': 'Active',
        'Device.DeviceInfo.FirmwareImage.1.Available': true,
        'Device.DeviceInfo.FirmwareImage.2.Name': 'Bank2',
        'Device.DeviceInfo.FirmwareImage.2.Version': availableVersion,
        'Device.DeviceInfo.FirmwareImage.2.Status': 'Available',
        'Device.DeviceInfo.FirmwareImage.2.Available': true,
      };

  /// Single-bank response (no available alternate) — used for negative tests.
  static Map<String, dynamic> singleBankResponse({
    String version = '1.0.16.26013014',
  }) =>
      <String, dynamic>{
        'Device.DeviceInfo.FirmwareImage.1.Name': 'Bank1',
        'Device.DeviceInfo.FirmwareImage.1.Version': version,
        'Device.DeviceInfo.FirmwareImage.1.Status': 'Active',
        'Device.DeviceInfo.FirmwareImage.1.Available': true,
      };

  /// Post-flash response where bank 2 is now Active running [newVersion].
  static Map<String, dynamic> postFlashResponse({
    String newVersion = '1.0.17.26050100',
    String oldVersion = '1.0.16.26013014',
  }) =>
      <String, dynamic>{
        'Device.DeviceInfo.FirmwareImage.1.Name': 'Bank1',
        'Device.DeviceInfo.FirmwareImage.1.Version': oldVersion,
        'Device.DeviceInfo.FirmwareImage.1.Status': 'Available',
        'Device.DeviceInfo.FirmwareImage.1.Available': true,
        'Device.DeviceInfo.FirmwareImage.2.Name': 'Bank2',
        'Device.DeviceInfo.FirmwareImage.2.Version': newVersion,
        'Device.DeviceInfo.FirmwareImage.2.Status': 'Active',
        'Device.DeviceInfo.FirmwareImage.2.Available': true,
      };

  // ---------------------------------------------------------------------------
  // UI models
  // ---------------------------------------------------------------------------

  static FirmwareImageUIModel activeBank({
    int instance = 1,
    String version = '1.0.16.26013014',
  }) =>
      FirmwareImageUIModel(
        instance: instance,
        instancePath: 'Device.DeviceInfo.FirmwareImage.$instance.',
        name: 'Bank$instance',
        version: version,
        status: 'Active',
        available: true,
      );

  static FirmwareImageUIModel availableBank({
    int instance = 2,
    String version = '1.0.15.25090212',
  }) =>
      FirmwareImageUIModel(
        instance: instance,
        instancePath: 'Device.DeviceInfo.FirmwareImage.$instance.',
        name: 'Bank$instance',
        version: version,
        status: 'Available',
        available: true,
      );

  /// Flexible bank builder for verify tests.
  static FirmwareImageUIModel bankWithStatus({
    required int instance,
    required String status,
    String? version,
  }) =>
      FirmwareImageUIModel(
        instance: instance,
        instancePath: 'Device.DeviceInfo.FirmwareImage.$instance.',
        name: 'Bank$instance',
        version: version ?? '1.0.16.26013014',
        status: status,
        available: true,
      );
}
