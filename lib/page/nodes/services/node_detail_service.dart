import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';

/// Riverpod provider for NodeDetailService
final nodeDetailServiceProvider = Provider<NodeDetailService>((ref) {
  return NodeDetailService(ref.watch(routerRepositoryProvider));
});

/// Stateless service for node detail operations
///
/// Encapsulates JNAP communication for LED blinking and provides
/// transformation helpers for converting device data to UI values.
class NodeDetailService {
  /// Constructor injection of RouterRepository dependency
  NodeDetailService(this._routerRepository);

  final RouterRepository _routerRepository;

  /// Starts LED blinking on the specified node device.
  ///
  /// Parameters:
  ///   - deviceId: The device ID of the node to blink
  ///
  /// Throws:
  ///   - [UnauthorizedError] if authentication failed
  ///   - [UnexpectedError] on JNAP communication failure
  Future<void> startBlinkNodeLED(String deviceId) async {
    try {
      await _routerRepository.send(
        JNAPAction.startBlinkNodeLed,
        data: {'deviceID': deviceId},
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        auth: true,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  /// Stops LED blinking on the node.
  ///
  /// Throws:
  ///   - [UnauthorizedError] if authentication failed
  ///   - [UnexpectedError] on JNAP communication failure
  Future<void> stopBlinkNodeLED() async {
    try {
      await _routerRepository.send(
        JNAPAction.stopBlinkNodeLed,
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  /// Transforms a device's JNAP model data into UI-appropriate primitive values.
  ///
  /// Parameters:
  ///   - device: The device to transform
  ///   - masterDevice: The master/authority node (for isMaster comparison)
  ///   - wanStatus: WAN status model (for WAN IP)
  ///
  /// Returns: Map with UI-ready values including location, isMaster, isOnline,
  /// connection info, hardware details, and more.
  Map<String, dynamic> transformDeviceToUIValues({
    required LinksysDevice device,
    required LinksysDevice? masterDevice,
    required RouterWANStatus? wanStatus,
  }) {
    final isMaster = device.deviceID == masterDevice?.deviceID;

    return {
      'location': device.getDeviceLocation(),
      'isMaster': isMaster,
      'isOnline': device.isOnline(),
      'isWiredConnection':
          device.getConnectionType() == DeviceConnectionType.wired,
      'signalStrength': device.signalDecibels ?? 0,
      'serialNumber': device.unit.serialNumber ?? '',
      'modelNumber': device.model.modelNumber ?? '',
      'firmwareVersion': device.unit.firmwareVersion ?? '',
      'hardwareVersion': device.model.hardwareVersion ?? '',
      'lanIpAddress': device.connections.firstOrNull?.ipAddress ?? '',
      'wanIpAddress': wanStatus?.wanConnection?.ipAddress ?? '',
      'upstreamDevice': isMaster
          ? 'INTERNET'
          : (device.upstream?.getDeviceLocation() ??
              masterDevice?.getDeviceLocation() ??
              ''),
      'isMLO': device.wirelessConnectionInfo?.isMultiLinkOperation ?? false,
      'macAddress': device.getMacAddress(),
    };
  }

  /// Transforms connected device list from JNAP model to UI model.
  ///
  /// Parameters:
  ///   - devices: Connected devices from JNAP
  ///   - deviceListNotifier: Notifier for creating DeviceListItem
  ///
  /// Returns: List of UI-ready DeviceListItem objects
  List<DeviceListItem> transformConnectedDevices({
    required List<LinksysDevice> devices,
    required DeviceListNotifier deviceListNotifier,
  }) {
    return devices.map((e) => deviceListNotifier.createItem(e)).toList();
  }

  /// Transforms NodeLightSettings JNAP model to NodeLightStatus UI enum.
  ///
  /// Parameters:
  ///   - settings: The NodeLightSettings from JNAP, can be null
  ///
  /// Returns: NodeLightStatus enum value (on, off, or night)
  NodeLightStatus getNodeLightStatus(NodeLightSettings? settings) {
    if (settings == null) {
      return NodeLightStatus.off;
    }
    if ((settings.allDayOff ?? false) ||
        (settings.startHour == 0 && settings.endHour == 24)) {
      return NodeLightStatus.off;
    } else if (!settings.isNightModeEnable) {
      return NodeLightStatus.on;
    } else {
      return NodeLightStatus.night;
    }
  }
}
