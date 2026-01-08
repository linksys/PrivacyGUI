/// UI-specific models for the PnP (Plug and Play) flow.
/// These models are designed to contain only the data required by the UI,
/// pre-formatted and ready for display, abstracting away the complexities
/// of the underlying JNAP domain models.
library pnp_ui_models;

import 'package:equatable/equatable.dart';

/// Represents device information specifically for UI display in the PnP flow.
/// This model flattens and formats data from NodeDeviceInfo for direct UI consumption.
class PnpDeviceInfoUIModel extends Equatable {
  /// The model name of the device.
  final String modelName;

  /// Pre-formatted image URL for the router model.
  final String image;

  /// The serial number of the device.
  final String serialNumber;

  /// The firmware version of the device.
  final String firmwareVersion;

  const PnpDeviceInfoUIModel({
    required this.modelName,
    required this.image,
    required this.serialNumber,
    required this.firmwareVersion,
  });

  @override
  List<Object?> get props => [
        modelName,
        image,
        serialNumber,
        firmwareVersion,
      ];
}

/// Represents the capabilities of a PnP device relevant to the UI.
class PnpDeviceCapabilitiesUIModel extends Equatable {
  /// Indicates if Guest WiFi is supported by the device.
  final bool isGuestWiFiSupported;

  /// Indicates if Night Mode (LED control) is supported by the device.
  final bool isNightModeSupported;

  /// Indicates if the PnP (Plug and Play) flow itself is supported by the device.
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

  /// Creates a copy of this model with optional new values.
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

/// Represents a child node (e.g., a mesh node) in the network for UI display.
class PnpChildNodeUIModel extends Equatable {
  /// The location of the child node (e.g., "Living Room").
  final String location;

  /// The model number of the child node.
  final String modelNumber;

  const PnpChildNodeUIModel({
    required this.location,
    required this.modelNumber,
  });

  @override
  List<Object?> get props => [location, modelNumber];
}

/// The auto-configuration method for the device (UI layer).
///
/// This enum is used by the UI layer to determine the configuration flow.
/// - [preConfigured]: Standard PnP flow for pre-configured devices.
/// - [autoParent]: Auto-parent flow for devices that connect to an existing network.
enum AutoConfigurationMethodUI {
  preConfigured,
  autoParent,
}

/// Represents the auto-configuration settings for UI display.
///
/// This model abstracts the JNAP AutoConfigurationSettings and provides
/// only the data needed by the UI layer for routing decisions.
class AutoConfigurationUIModel extends Equatable {
  /// Indicates if auto-configuration is supported by the device.
  final bool? isSupported;

  /// Indicates if the user has acknowledged the auto-configuration.
  final bool? userAcknowledged;

  /// The method of auto-configuration.
  final AutoConfigurationMethodUI? method;

  const AutoConfigurationUIModel({
    this.isSupported,
    this.userAcknowledged,
    this.method,
  });

  @override
  List<Object?> get props => [isSupported, userAcknowledged, method];

  /// Creates a copy of this model with optional new values.
  AutoConfigurationUIModel copyWith({
    bool? isSupported,
    bool? userAcknowledged,
    AutoConfigurationMethodUI? method,
  }) {
    return AutoConfigurationUIModel(
      isSupported: isSupported ?? this.isSupported,
      userAcknowledged: userAcknowledged ?? this.userAcknowledged,
      method: method ?? this.method,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isSupported': isSupported,
      'userAcknowledged': userAcknowledged,
      'method': method?.name,
    };
  }

  factory AutoConfigurationUIModel.fromMap(Map<String, dynamic> map) {
    return AutoConfigurationUIModel(
      isSupported: map['isSupported'] as bool?,
      userAcknowledged: map['userAcknowledged'] as bool?,
      method: map['method'] != null
          ? AutoConfigurationMethodUI.values.byName(map['method'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory AutoConfigurationUIModel.fromJson(Map<String, dynamic> json) =>
      AutoConfigurationUIModel.fromMap(json);
}

/// Represents the default Wi-Fi settings for both main and guest networks.
class PnpDefaultSettingsUIModel extends Equatable {
  /// The default SSID for the main Wi-Fi network.
  final String wifiSsid;

  /// The default password for the main Wi-Fi network.
  final String wifiPassword;

  /// The default SSID for the guest Wi-Fi network.
  final String guestWifiSsid;

  /// The default password for the guest Wi-Fi network.
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

  /// Creates a copy of this model with optional new values.
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
