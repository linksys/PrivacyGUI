import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';

/// Riverpod provider for DashboardHomeService
final dashboardHomeServiceProvider = Provider<DashboardHomeService>((ref) {
  return const DashboardHomeService();
});

/// Stateless service for dashboard home state transformation
///
/// Encapsulates JNAP model transformations, separating data layer
/// concerns from state management (DashboardHomeNotifier).
class DashboardHomeService {
  const DashboardHomeService();

  /// Transforms JNAP-layer state data into a complete [DashboardHomeState].
  ///
  /// This method orchestrates all the data transformation logic required
  /// to build the UI state for the dashboard home view.
  DashboardHomeState buildDashboardHomeState({
    required DashboardManagerState dashboardManagerState,
    required DeviceManagerState deviceManagerState,
    required String Function(LinksysDevice device) getBandForDevice,
    required List<LinksysDevice> deviceList,
  }) {
    // Build WiFi list
    final wifiList = _buildMainWiFiItems(
      mainRadios: dashboardManagerState.mainRadios,
      mainWifiDevices: deviceManagerState.mainWifiDevices,
      getBandForDevice: getBandForDevice,
    );

    // Add guest WiFi if exists
    final guestWifi = _buildGuestWiFiItem(
      guestRadios: dashboardManagerState.guestRadios,
      guestWifiDevices: deviceManagerState.guestWifiDevices,
      isGuestNetworkEnabled: dashboardManagerState.isGuestNetworkEnabled,
    );
    if (guestWifi != null) {
      wifiList.add(guestWifi);
    }

    // Determine node offline status
    final isAnyNodesOffline =
        deviceManagerState.nodeDevices.any((element) => !element.isOnline());

    // Get WAN type
    final wanType = deviceManagerState.wanStatus?.wanConnection?.wanType;
    final detectedWANType = deviceManagerState.wanStatus?.detectedWANType;

    // Determine if first polling
    final isFirstPolling = deviceManagerState.lastUpdateTime == 0;

    // Get master node icon
    final masterIcon = routerIconTestByModel(
      modelNumber: deviceList.firstOrNull?.model.modelNumber ?? '',
      hardwareVersion: deviceList.firstOrNull?.model.hardwareVersion,
    );

    // Determine port layout
    final deviceInfo = dashboardManagerState.deviceInfo;
    final horizontalPortLayout = isHorizontalPorts(
      modelNumber: deviceInfo?.modelNumber ?? '',
      hardwareVersion: deviceInfo?.hardwareVersion ?? '1',
    );

    return DashboardHomeState(
      wifis: wifiList,
      uptime: dashboardManagerState.uptimes,
      wanPortConnection: dashboardManagerState.wanConnection,
      lanPortConnections: dashboardManagerState.lanConnections,
      isFirstPolling: isFirstPolling,
      masterIcon: masterIcon,
      isAnyNodesOffline: isAnyNodesOffline,
      isHorizontalLayout: horizontalPortLayout,
      wanType: wanType,
      detectedWANType: detectedWANType,
    );
  }

  /// Builds main WiFi items grouped by band.
  List<DashboardWiFiUIModel> _buildMainWiFiItems({
    required List<RouterRadio> mainRadios,
    required List<LinksysDevice> mainWifiDevices,
    required String Function(LinksysDevice) getBandForDevice,
  }) {
    return mainRadios
        .groupFoldBy<String, List<RouterRadio>>(
          (element) => element.band,
          (previous, element) => [...(previous ?? []), element],
        )
        .entries
        .map((e) {
      final connectedDevices = mainWifiDevices.where((device) {
        final deviceBand = getBandForDevice(device);
        return device.nodeType == null &&
            device.isOnline() &&
            e.value.any((element) => element.band == deviceBand);
      }).length;
      return _createWiFiItemFromMainRadios(e.value, connectedDevices);
    }).toList();
  }

  /// Builds guest WiFi item if guest radios exist.
  DashboardWiFiUIModel? _buildGuestWiFiItem({
    required List<GuestRadioInfo> guestRadios,
    required List<LinksysDevice> guestWifiDevices,
    required bool isGuestNetworkEnabled,
  }) {
    if (guestRadios.isEmpty) {
      return null;
    }

    final connectedDevices =
        guestWifiDevices.where((device) => device.isOnline()).length;

    return _createWiFiItemFromGuestRadios(guestRadios, connectedDevices)
        .copyWith(isEnabled: isGuestNetworkEnabled);
  }

  /// Creates a [DashboardWiFiUIModel] from main radio list.
  ///
  /// This method replaces the `DashboardWiFiUIModel.fromMainRadios()` factory method.
  DashboardWiFiUIModel _createWiFiItemFromMainRadios(
    List<RouterRadio> radios,
    int connectedDevices,
  ) {
    final radio = radios.first;
    return DashboardWiFiUIModel(
      ssid: radio.settings.ssid,
      password: radio.settings.wpaPersonalSettings?.passphrase ?? '',
      radios: radios.map((e) => e.radioID).toList(),
      isGuest: false,
      isEnabled: radio.settings.isEnabled,
      numOfConnectedDevices: connectedDevices,
    );
  }

  /// Creates a [DashboardWiFiUIModel] from guest radio list.
  ///
  /// This method replaces the `DashboardWiFiUIModel.fromGuestRadios()` factory method.
  DashboardWiFiUIModel _createWiFiItemFromGuestRadios(
    List<GuestRadioInfo> radios,
    int connectedDevices,
  ) {
    final radio = radios.first;
    return DashboardWiFiUIModel(
      ssid: radio.guestSSID,
      password: radio.guestWPAPassphrase ?? '',
      radios: radios.map((e) => e.radioID).toList(),
      isGuest: true,
      isEnabled: radio.isEnabled,
      numOfConnectedDevices: connectedDevices,
    );
  }
}
