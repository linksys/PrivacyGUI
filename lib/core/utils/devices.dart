import 'package:collection/collection.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

extension DeviceUtil on RawDevice {
  String getDeviceLocation() {
    for (final property in properties) {
      if (property.name == 'userDeviceLocation' && property.value.isNotEmpty) {
        return property.value;
      }
    }
    return getDeviceName();
  }

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

  String getMacAddress() {
    var macAddress = '';
    if (knownInterfaces != null) {
      final knownInterface = knownInterfaces!.firstWhereOrNull((element) =>
          element.band != null || element.interfaceType != 'Unknown');
      macAddress = (knownInterface ?? knownInterfaces!.first).macAddress ?? '';
    } else if (knownMACAddresses != null) {
      // This case is only for a part of old routers that does not support 'GetDevices3' action
      macAddress = knownMACAddresses!.firstOrNull ?? '';
    }
    return macAddress;
  }

  bool containsMacAddress(String mac) {
    if (knownInterfaces != null) {
      return knownInterfaces!.any((element) => element.macAddress == mac);
    } else if (knownMACAddresses != null) {
      return knownMACAddresses!.contains(mac);
    } else {
      return false;
    }
  }

  bool containsIpAddress(String ip) {
    return connections.any((element) => element.ipAddress == ip);
  }

  bool containsIpv6Address(String ip) {
    return connections.any((element) => element.ipv6Address == ip);
  }

  bool isOnline() {
    return connections.isNotEmpty;
  }
}

extension LinksysDeviceExt on LinksysDevice {
  bool isWirelessConnection() {
    bool ret = false;
    if (nodeType == 'Slave') {
      ret = connectionType == 'Wireless' && wirelessConnectionInfo != null;
    }
    final interfaces = knownInterfaces;
    return ret || interfaces?.firstWhereOrNull(
            (element) => element.interfaceType == 'Wireless') !=
        null;
  }
}
