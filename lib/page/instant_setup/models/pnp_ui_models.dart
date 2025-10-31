/// UI-specific models for the PnP (Plug and Play) flow.
/// These models are designed to contain only the data required by the UI,
/// pre-formatted and ready for display, abstracting away the complexities
/// of the underlying JNAP domain models.
library pnp_ui_models;

import 'package:equatable/equatable.dart';

/// Represents device information specifically for UI display in the PnP flow.
/// This model flattens and formats data from NodeDeviceInfo for direct UI consumption.
class PnpDeviceInfoUIModel extends Equatable {
  final String modelName;
  final String imageUrl; // Pre-formatted image URL for the router model
  final String serialNumber;
  final String firmwareVersion;

  const PnpDeviceInfoUIModel({
    required this.modelName,
    required this.imageUrl,
    required this.serialNumber,
    required this.firmwareVersion,
  });

  @override
  List<Object?> get props => [
        modelName,
        imageUrl,
        serialNumber,
        firmwareVersion,
      ];
}

class PnpDeviceCapabilitiesUIModel extends Equatable {
  final bool isGuestWiFiSupported;

  final bool isNightModeSupported;

  final bool isPnpSupported;

  const PnpDeviceCapabilitiesUIModel({
    this.isGuestWiFiSupported = false,
    this.isNightModeSupported = false,
    this.isPnpSupported = false,
  });

  @override
  List<Object?> get props => [
        isGuestWiFiSupported,
        isNightModeSupported,
        isPnpSupported,
      ];

  PnpDeviceCapabilitiesUIModel copyWith({
    bool? isGuestWiFiSupported,
    bool? isNightModeSupported,
    bool? isPnpSupported,
  }) {
    return PnpDeviceCapabilitiesUIModel(
      isGuestWiFiSupported: isGuestWiFiSupported ?? this.isGuestWiFiSupported,
      isNightModeSupported: isNightModeSupported ?? this.isNightModeSupported,
      isPnpSupported: isPnpSupported ?? this.isPnpSupported,
    );
  }
}

class PnpChildNodeUIModel extends Equatable {
  final String location;

  final String modelNumber;

  const PnpChildNodeUIModel({
    required this.location,
    required this.modelNumber,
  });

  @override
  List<Object?> get props => [location, modelNumber];
}

class PnpDefaultSettingsUIModel extends Equatable {
  final String wifiSsid;

  final String wifiPassword;

  final String guestWifiSsid;

  final String guestWifiPassword;

  const PnpDefaultSettingsUIModel({
    this.wifiSsid = '',
    this.wifiPassword = '',
    this.guestWifiSsid = '',
    this.guestWifiPassword = '',
  });

  @override
  List<Object?> get props => [
        wifiSsid,
        wifiPassword,
        guestWifiSsid,
        guestWifiPassword,
      ];

  PnpDefaultSettingsUIModel copyWith({
    String? wifiSsid,
    String? wifiPassword,
    String? guestWifiSsid,
    String? guestWifiPassword,
  }) {
    return PnpDefaultSettingsUIModel(
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      guestWifiSsid: guestWifiSsid ?? this.guestWifiSsid,
      guestWifiPassword: guestWifiPassword ?? this.guestWifiPassword,
    );
  }
}
