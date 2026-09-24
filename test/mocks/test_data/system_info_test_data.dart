import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';

/// Builders for [SystemInfoUIModel], the router-identity model nearly every
/// topology and dashboard test needs and none of them varies.
///
/// It had no builder, so the same ten-field literal was written out in nine test
/// files (measured). That is what constitution Article I §1.6.2 is about: a
/// hand-rolled copy per file means a field added to the model has to be found in
/// nine places, and a test asserting on `modelName` is coupled to whichever copy
/// it happens to sit beside.
///
/// The scene files under `scenes/` keep their own `SystemInfoUIModel` constants on
/// purpose — those are whole composed states a provider override consumes, not
/// factories (see CLAUDE.md on the `_test_data` / `_scene_data` split).
class SystemInfoTestData {
  SystemInfoTestData._();

  static const defaultModel = 'MR7500';
  static const defaultManufacturer = 'Linksys';
  static const defaultSerialNumber = 'SN123456';
  static const defaultSoftwareVersion = '1.0.16.26013014';

  /// A healthy gateway, with every field populated.
  ///
  /// Every parameter is named and defaulted, so a test states only the field it is
  /// about — which is also what makes the assertion legible, since a literal with
  /// ten fields hides which one matters.
  static SystemInfoUIModel create({
    String manufacturer = defaultManufacturer,
    String modelName = defaultModel,
    String hardwareVersion = '1.0',
    String serialNumber = defaultSerialNumber,
    String softwareVersion = defaultSoftwareVersion,
    int uptime = 3600,
    int totalMemory = 512000,
    int freeMemory = 256000,
    int cpuUsage = 25,
  }) =>
      SystemInfoUIModel(
        manufacturer: manufacturer,
        modelName: modelName,
        hardwareVersion: hardwareVersion,
        serialNumber: serialNumber,
        softwareVersion: softwareVersion,
        uptime: uptime,
        totalMemory: totalMemory,
        freeMemory: freeMemory,
        cpuUsage: cpuUsage,
      );
}
