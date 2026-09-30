import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

/// What [UspMacFilterService.fetchAll] hands a notifier: the device's current
/// mode + list, plus the connected devices for the picker / pre-populate.
class MacFilterFetchResult {
  final MacFilterMode mode;
  final List<String> macs;
  final List<MacFilterDeviceUIModel> connectedDevices;

  const MacFilterFetchResult({
    required this.mode,
    required this.macs,
    required this.connectedDevices,
  });
}
