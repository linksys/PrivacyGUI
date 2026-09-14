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

  /// Three-instance response as measured on the target firmware: two physical
  /// NAND banks (`fw1`/`fw2`) plus the virtual `ota` instance.
  ///
  /// The spare bank deliberately reports `Available=1` with an **empty**
  /// `Version` — a non-active bank cannot report its version, which is a fact
  /// of the data plane rather than a defect.
  static Map<String, dynamic> threeInstanceResponse({
    String activeVersion = '2.0.1.26091007',
    bool otaAvailable = false,
    String otaVersion = '',
  }) =>
      <String, dynamic>{
        'Device.DeviceInfo.FirmwareImage.1.Alias': 'fw1',
        'Device.DeviceInfo.FirmwareImage.1.Name': '2.0.1',
        'Device.DeviceInfo.FirmwareImage.1.Version': activeVersion,
        'Device.DeviceInfo.FirmwareImage.1.Status': 'Active',
        'Device.DeviceInfo.FirmwareImage.1.Available': true,
        'Device.DeviceInfo.FirmwareImage.2.Alias': 'fw2',
        'Device.DeviceInfo.FirmwareImage.2.Name': '',
        'Device.DeviceInfo.FirmwareImage.2.Version': '',
        'Device.DeviceInfo.FirmwareImage.2.Status': 'Available',
        'Device.DeviceInfo.FirmwareImage.2.Available': true,
        'Device.DeviceInfo.FirmwareImage.3.Alias': 'ota',
        'Device.DeviceInfo.FirmwareImage.3.Name': '',
        'Device.DeviceInfo.FirmwareImage.3.Version': otaVersion,
        'Device.DeviceInfo.FirmwareImage.3.Status':
            otaAvailable ? 'Available' : 'NoImage',
        'Device.DeviceInfo.FirmwareImage.3.Available': otaAvailable,
      };

  /// A row carrying nothing but `Alias='ota'` — every other field empty/false.
  ///
  /// Pins the vendored-codegen phantom-row skip: `_fromResponse` drops a row
  /// whose every field is null/empty/`'0'`/false, and `Alias` is the only thing
  /// holding this one up. Not a known defect — a boundary guard, so a
  /// `usp-codegen` bump that changes that logic says so out loud.
  static Map<String, dynamic> otaAliasOnlyResponse() => <String, dynamic>{
        'Device.DeviceInfo.FirmwareImage.3.Alias': 'ota',
        'Device.DeviceInfo.FirmwareImage.3.Name': '',
        'Device.DeviceInfo.FirmwareImage.3.Version': '',
        'Device.DeviceInfo.FirmwareImage.3.Status': '',
        'Device.DeviceInfo.FirmwareImage.3.Available': false,
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
    String? alias,
  }) =>
      FirmwareImageUIModel(
        instance: instance,
        instancePath: 'Device.DeviceInfo.FirmwareImage.$instance.',
        alias: alias,
        name: 'Bank$instance',
        version: version,
        status: 'Active',
        available: true,
      );

  static FirmwareImageUIModel availableBank({
    int instance = 2,
    String version = '1.0.15.25090212',
    String? alias,
  }) =>
      FirmwareImageUIModel(
        instance: instance,
        instancePath: 'Device.DeviceInfo.FirmwareImage.$instance.',
        alias: alias,
        name: 'Bank$instance',
        version: version,
        status: 'Available',
        available: true,
      );

  /// The virtual `ota` instance — the source of "there is a newer version".
  /// Not a bank: nothing that presents banks may show it.
  static FirmwareImageUIModel otaInstance({
    int instance = 3,
    bool available = false,
    String version = '',
  }) =>
      FirmwareImageUIModel(
        instance: instance,
        instancePath: 'Device.DeviceInfo.FirmwareImage.$instance.',
        alias: 'ota',
        name: '',
        version: version,
        status: available ? 'Available' : 'NoImage',
        available: available,
      );

  /// A physical spare bank reporting an empty version — the measured shape of
  /// `fw2` on a router that is already up to date. A non-active bank cannot
  /// report its version, so this is a normal state, not a read failure.
  static FirmwareImageUIModel emptyVersionBank({
    int instance = 2,
    String? alias = 'fw2',
  }) =>
      FirmwareImageUIModel(
        instance: instance,
        instancePath: 'Device.DeviceInfo.FirmwareImage.$instance.',
        alias: alias,
        name: '',
        version: '',
        status: 'Available',
        available: true,
      );

  /// Flexible bank builder for verify tests.
  static FirmwareImageUIModel bankWithStatus({
    required int instance,
    required String status,
    String? version,
    bool available = true,
    String? alias,
  }) =>
      FirmwareImageUIModel(
        instance: instance,
        instancePath: 'Device.DeviceInfo.FirmwareImage.$instance.',
        alias: alias,
        name: 'Bank$instance',
        version: version ?? '1.0.16.26013014',
        status: status,
        available: available,
      );
}
