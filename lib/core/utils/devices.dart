import 'package:linksys_app/core/jnap/models/device.dart';

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
}
