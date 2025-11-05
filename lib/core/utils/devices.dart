import 'package:collection/collection.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

/// An extension on [RawDevice] providing utility methods for accessing device information.
extension DeviceUtil on RawDevice {
  /// Retrieves the user-defined location of the device.
  ///
  /// This method first checks for a 'userDeviceLocation' property. If not found
  /// or empty, it falls back to returning the device name via [getDeviceName].
  ///
  /// Returns the device location as a `String`.
  String getDeviceLocation() {
    for (final property in properties) {
      if (property.name == 'userDeviceLocation' && property.value.isNotEmpty) {
        return property.value;
      }
    }
    return getDeviceName();
  }

  /// Determines the most appropriate display name for the device.
  ///
  /// The method follows a priority order:
  /// 1. A user-defined device name ('userDeviceName' property).
  /// 2. A constructed name for Android devices (e.g., 'Samsung Galaxy S8').
  /// 3. The `friendlyName` provided by the device.
  /// 4. The `modelNumber` from the device model.
  /// 5. A generic name like 'Guest Network Device' or 'Network Device' as a last resort.
  ///
  /// Returns the determined device name as a `String`.
  String getDeviceName() {
    for (final property in properties) {
      if (property.name == 'userDeviceName' && property.value.isNotEmpty) {
        return property.value;
      }
    }

    bool isAndroidDevice = false;
    if (friendlyName != null) {
      final regExp =
          RegExp(r'^Android$|^android-[a-fA-F0-9]{16}.*|^Android-[0-9]+');
      isAndroidDevice = regExp.hasMatch(friendlyName!);
    }

    String? androidDeviceName;
    if (isAndroidDevice &&
        ['Mobile', 'Phone', 'Tablet'].contains(model.deviceType)) {
      final manufacturer = this.manufacturer;
      final modelNumber = this.modelNumber;
      if (manufacturer != null && modelNumber != null) {
        // e.g. 'Samsung Galaxy S8'
        androidDeviceName = '$manufacturer $modelNumber';
      } else if (operatingSystem != null) {
        // e.g. 'Android Oreo Mobile'
        androidDeviceName = '${operatingSystem!} ${model.deviceType}';
        if (manufacturer != null) {
          // e.g. 'Samsung Android Oreo Mobile'
          androidDeviceName = manufacturer + androidDeviceName;
        }
      }
    }

    if (androidDeviceName != null) {
      return androidDeviceName;
    } else if (friendlyName != null) {
      return friendlyName!;
    } else if (model.modelNumber != null) {
      return model.modelNumber!;
    } else {
      // Check if it's connecting to the guest network
      // NOTE: This value can also be derived from 'NetworkConnections', but they should be identical
      final isGuest = connections.firstOrNull?.isGuest ?? false;
      return isGuest ? 'Guest Network Device' : 'Network Device';
    }
  }

  /// Extracts the primary MAC address of the device.
  ///
  /// It prioritizes finding a MAC address from a known, active interface.
  /// For older routers, it may fall back to using `knownMACAddresses`.
  ///
  /// Returns the MAC address as a `String`, or an empty string if none is found.
  String getMacAddress() {
    var macAddress = '';
    if (knownInterfaces != null) {
      final knownInterface = knownInterfaces!.firstWhereOrNull((element) =>
          element.band != null || element.interfaceType != 'Unknown');
      macAddress = (knownInterface ?? knownInterfaces!.first).macAddress;
    } else if (knownMACAddresses != null) {
      // This case is only for a part of old routers that does not support 'GetDevices3' action
      macAddress = knownMACAddresses!.firstOrNull ?? '';
    }
    return macAddress;
  }

  /// Checks if the device's known interfaces include the given MAC address.
  ///
  /// [mac] The MAC address to search for.
  ///
  /// Returns `true` if the MAC address is found, `false` otherwise.
  bool containsMacAddress(String mac) {
    if (knownInterfaces != null) {
      return knownInterfaces!.any((element) => element.macAddress == mac);
    } else if (knownMACAddresses != null) {
      return knownMACAddresses!.contains(mac);
    } else {
      return false;
    }
  }

  /// Checks if the device's active connections include the given IP address.
  ///
  /// [ip] The IPv4 address to search for.
  ///
  /// Returns `true` if the IP address is found, `false` otherwise.
  bool containsIpAddress(String ip) {
    return connections.any((element) => element.ipAddress == ip);
  }

  /// Checks if the device's active connections include the given IPv6 address.
  ///
  /// [ip] The IPv6 address to search for.
  ///
  /// Returns `true` if the IPv6 address is found, `false` otherwise.
  bool containsIpv6Address(String ip) {
    return connections.any((element) => element.ipv6Address == ip);
  }
}

/// An extension on [LinksysDevice] providing high-level status information.
extension LinksysDeviceExt on LinksysDevice {
  /// Determines the connection type of the device (wired, wireless, or none).
  ///
  /// If the device is not online, it returns [DeviceConnectionType.none].
  /// For slave nodes, it checks the `connectionType` property. For other nodes,
  /// it inspects the `knownInterfaces` to determine if the connection is wireless.
  ///
  /// Returns a [DeviceConnectionType] enum value.
  DeviceConnectionType getConnectionType() {
    bool ret = isOnline();
    if (!ret) {
      return DeviceConnectionType.none;
    }
    if (nodeType == 'Slave') {
      return connectionType == 'Wireless' && wirelessConnectionInfo != null
          ? DeviceConnectionType.wireless
          : DeviceConnectionType.wired;
    }
    final interfaces = knownInterfaces;
    return interfaces?.any((element) => element.interfaceType == 'Wireless') ==
            true
        ? DeviceConnectionType.wireless
        : DeviceConnectionType.wired;
  }

  /// Checks if the device is currently online.
  ///
  /// A device is considered online if it has at least one active connection.
  ///
  /// Returns `true` if the device is online, `false` otherwise.
  bool isOnline() {
    // return nodeType == 'Master'
    //     ? connections.isNotEmpty
    //     : connections.isNotEmpty &&
    //         knownInterfaces?.any((element) =>
    //                 element.interfaceType == 'Wired' ||
    //                 element.interfaceType == 'Wireless') ==
    //             true;
    return connections.isNotEmpty;
  }
}

/// Represents the physical connection type of a device on the network.
enum DeviceConnectionType {
  /// The device is connected via an Ethernet cable.
  wired,

  /// The device is connected via Wi-Fi.
  wireless,

  /// The device is not currently connected.
  none;
}
