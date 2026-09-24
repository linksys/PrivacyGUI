import 'package:privacy_gui/generated/firmware_auto_update.g.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
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

  // ---------------------------------------------------------------------------
  // Auto-update (fwup) status
  // ---------------------------------------------------------------------------

  /// A `FirmwareAutoUpdate` reading as the codegen layer hands it over. Both
  /// sysevent values arrive as strings, including the ones that look numeric —
  /// which is the whole reason the mapping has to be explicit.
  /// The four diagnostics leaves default to **null — the router did not report
  /// them** — rather than to `'0'`. That is the shape the merged definition has
  /// (`optional: true`, no `default_value`), and defaulting them to a value would let
  /// a test assert "no error" against a fixture that never said so.
  static FirmwareAutoUpdate autoUpdate({
    String fwupState = '0',
    String fwupProgress = '0',
    String autoupdateFlags = '2',
    String? fwupErrorCode,
    String? fwupTriggerSource,
    String? fwupCheckedAfterBoot,
    String? newfirmwareVersion,
  }) =>
      FirmwareAutoUpdate(
        autoupdateFlags: autoupdateFlags,
        fwupState: fwupState,
        fwupProgress: fwupProgress,
        fwupErrorCode: fwupErrorCode,
        fwupTriggerSource: fwupTriggerSource,
        fwupCheckedAfterBoot: fwupCheckedAfterBoot,
        newfirmwareVersion: newfirmwareVersion,
      );

  /// The same reading one layer lower — the raw `Get` map, for stubbing
  /// `UspClient.get()` where [autoUpdate] would skip the codegen parse.
  ///
  /// The two optional sysevent paths are deliberately absent: `optional: true` in
  /// the definition means a router without the fwup stack answers without them, and
  /// this app never reads either one (REQ-C2 — `fwup_periodic_check` is not ours to
  /// write, and `update_firmware_now` is a second flash entry point we do not use).
  static Map<String, dynamic> autoUpdateResponse({
    String fwupState = '0',
    String fwupProgress = '0',
    String autoupdateFlags = '2',
    String? fwupErrorCode,
    String? fwupTriggerSource,
    String? fwupCheckedAfterBoot,
  }) =>
      <String, dynamic>{
        'Device.X_LINKSYS_UCI.linksys.fwup.autoupdate_flags': autoupdateFlags,
        'Device.X_LINKSYS_Sysevent.fwup_state': fwupState,
        'Device.X_LINKSYS_Sysevent.fwup_progress': fwupProgress,
        // Present only when asked for: a key absent from the map is how a router
        // without the diagnostics leaves answers, and the codegen turns that into
        // null rather than into a value.
        if (fwupErrorCode != null)
          'Device.X_LINKSYS_Sysevent.fwup_error_code': fwupErrorCode,
        if (fwupTriggerSource != null)
          'Device.X_LINKSYS_Sysevent.fwup_trigger_source': fwupTriggerSource,
        if (fwupCheckedAfterBoot != null)
          'Device.X_LINKSYS_Sysevent.fwup_checked_after_boot':
              fwupCheckedAfterBoot,
      };

  /// A `FirmwareAutoUpdateUIModel` as the service hands it to a provider.
  static FirmwareAutoUpdateUIModel autoUpdateModel({
    FirmwareAutoUpdateStatus status = FirmwareAutoUpdateStatus.idle,
    int progress = 0,
    String rawState = '0',
    FirmwareAutoUpdatePolicy policy = FirmwareAutoUpdatePolicy.autoInstall,
    String? rawFlags,
    FirmwareUpdateErrorCode errorCode = FirmwareUpdateErrorCode.unreported,
    String? rawErrorCode,
    FirmwareUpdateTriggerSource triggerSource =
        FirmwareUpdateTriggerSource.unreported,
    bool? checkedAfterBoot,
  }) =>
      FirmwareAutoUpdateUIModel(
        status: status,
        progress: progress,
        rawState: rawState,
        policy: policy,
        rawFlags: rawFlags ?? policy.rawValue,
        errorCode: errorCode,
        rawErrorCode: rawErrorCode,
        triggerSource: triggerSource,
        checkedAfterBoot: checkedAfterBoot,
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
