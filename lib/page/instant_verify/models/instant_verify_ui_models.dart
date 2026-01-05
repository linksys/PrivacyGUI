// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/wan_external.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';

/// ============================================================================
/// Instant Verify UI Models
///
/// These models represent the UI layer's view of instant verify data.
/// Service layer transforms JNAP models to these UI models.
/// ============================================================================

/// UI Model for Ping status result
class PingStatusUIModel extends Equatable {
  final bool isRunning;
  final String pingLog;

  const PingStatusUIModel({
    required this.isRunning,
    required this.pingLog,
  });

  const PingStatusUIModel.initial()
      : isRunning = false,
        pingLog = '';

  PingStatusUIModel copyWith({
    bool? isRunning,
    String? pingLog,
  }) {
    return PingStatusUIModel(
      isRunning: isRunning ?? this.isRunning,
      pingLog: pingLog ?? this.pingLog,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isRunning': isRunning,
      'pingLog': pingLog,
    };
  }

  factory PingStatusUIModel.fromMap(Map<String, dynamic> map) {
    return PingStatusUIModel(
      isRunning: map['isRunning'] as bool,
      pingLog: map['pingLog'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PingStatusUIModel.fromJson(String source) =>
      PingStatusUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isRunning, pingLog];
}

/// UI Model for Traceroute status result
class TracerouteStatusUIModel extends Equatable {
  final bool isRunning;
  final String tracerouteLog;

  const TracerouteStatusUIModel({
    required this.isRunning,
    required this.tracerouteLog,
  });

  const TracerouteStatusUIModel.initial()
      : isRunning = false,
        tracerouteLog = '';

  TracerouteStatusUIModel copyWith({
    bool? isRunning,
    String? tracerouteLog,
  }) {
    return TracerouteStatusUIModel(
      isRunning: isRunning ?? this.isRunning,
      tracerouteLog: tracerouteLog ?? this.tracerouteLog,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isRunning': isRunning,
      'tracerouteLog': tracerouteLog,
    };
  }

  factory TracerouteStatusUIModel.fromMap(Map<String, dynamic> map) {
    return TracerouteStatusUIModel(
      isRunning: map['isRunning'] as bool,
      tracerouteLog: map['tracerouteLog'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory TracerouteStatusUIModel.fromJson(String source) =>
      TracerouteStatusUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isRunning, tracerouteLog];
}

/// UI Model for WAN connection information
class WANConnectionUIModel extends Equatable {
  final String wanType;
  final String ipAddress;
  final int networkPrefixLength;
  final String gateway;
  final int mtu;
  final int? dhcpLeaseMinutes;
  final String dnsServer1;
  final String? dnsServer2;
  final String? dnsServer3;

  const WANConnectionUIModel({
    required this.wanType,
    required this.ipAddress,
    required this.networkPrefixLength,
    required this.gateway,
    required this.mtu,
    this.dhcpLeaseMinutes,
    required this.dnsServer1,
    this.dnsServer2,
    this.dnsServer3,
  });

  /// Factory constructor to create from JNAP model
  factory WANConnectionUIModel.fromJnap(WANConnectionInfo info) {
    return WANConnectionUIModel(
      wanType: info.wanType,
      ipAddress: info.ipAddress,
      networkPrefixLength: info.networkPrefixLength,
      gateway: info.gateway,
      mtu: info.mtu,
      dhcpLeaseMinutes: info.dhcpLeaseMinutes,
      dnsServer1: info.dnsServer1,
      dnsServer2: info.dnsServer2,
      dnsServer3: info.dnsServer3,
    );
  }

  WANConnectionUIModel copyWith({
    String? wanType,
    String? ipAddress,
    int? networkPrefixLength,
    String? gateway,
    int? mtu,
    int? dhcpLeaseMinutes,
    String? dnsServer1,
    String? dnsServer2,
    String? dnsServer3,
  }) {
    return WANConnectionUIModel(
      wanType: wanType ?? this.wanType,
      ipAddress: ipAddress ?? this.ipAddress,
      networkPrefixLength: networkPrefixLength ?? this.networkPrefixLength,
      gateway: gateway ?? this.gateway,
      mtu: mtu ?? this.mtu,
      dhcpLeaseMinutes: dhcpLeaseMinutes ?? this.dhcpLeaseMinutes,
      dnsServer1: dnsServer1 ?? this.dnsServer1,
      dnsServer2: dnsServer2 ?? this.dnsServer2,
      dnsServer3: dnsServer3 ?? this.dnsServer3,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'wanType': wanType,
      'ipAddress': ipAddress,
      'networkPrefixLength': networkPrefixLength,
      'gateway': gateway,
      'mtu': mtu,
      'dhcpLeaseMinutes': dhcpLeaseMinutes,
      'dnsServer1': dnsServer1,
      'dnsServer2': dnsServer2,
      'dnsServer3': dnsServer3,
    }..removeWhere((key, value) => value == null);
  }

  factory WANConnectionUIModel.fromMap(Map<String, dynamic> map) {
    return WANConnectionUIModel(
      wanType: map['wanType'] as String,
      ipAddress: map['ipAddress'] as String,
      networkPrefixLength: map['networkPrefixLength'] as int,
      gateway: map['gateway'] as String,
      mtu: map['mtu'] as int,
      dhcpLeaseMinutes: map['dhcpLeaseMinutes'] as int?,
      dnsServer1: map['dnsServer1'] as String,
      dnsServer2: map['dnsServer2'] as String?,
      dnsServer3: map['dnsServer3'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory WANConnectionUIModel.fromJson(String source) =>
      WANConnectionUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
        wanType,
        ipAddress,
        networkPrefixLength,
        gateway,
        mtu,
        dhcpLeaseMinutes,
        dnsServer1,
        dnsServer2,
        dnsServer3,
      ];
}

/// UI Model for Radio information
class RadioInfoUIModel extends Equatable {
  final bool isBandSteeringSupported;
  final List<RouterRadioUIModel> radios;

  const RadioInfoUIModel({
    required this.isBandSteeringSupported,
    required this.radios,
  });

  const RadioInfoUIModel.initial()
      : isBandSteeringSupported = false,
        radios = const [];

  /// Factory constructor to create from JNAP model
  factory RadioInfoUIModel.fromJnap(GetRadioInfo info) {
    return RadioInfoUIModel(
      isBandSteeringSupported: info.isBandSteeringSupported,
      radios: info.radios.map((r) => RouterRadioUIModel.fromJnap(r)).toList(),
    );
  }

  RadioInfoUIModel copyWith({
    bool? isBandSteeringSupported,
    List<RouterRadioUIModel>? radios,
  }) {
    return RadioInfoUIModel(
      isBandSteeringSupported:
          isBandSteeringSupported ?? this.isBandSteeringSupported,
      radios: radios ?? this.radios,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isBandSteeringSupported': isBandSteeringSupported,
      'radios': radios.map((x) => x.toMap()).toList(),
    };
  }

  factory RadioInfoUIModel.fromMap(Map<String, dynamic> map) {
    return RadioInfoUIModel(
      isBandSteeringSupported: map['isBandSteeringSupported'] as bool,
      radios: List<RouterRadioUIModel>.from(
        (map['radios'] as List<dynamic>).map<RouterRadioUIModel>(
          (x) => RouterRadioUIModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory RadioInfoUIModel.fromJson(String source) =>
      RadioInfoUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isBandSteeringSupported, radios];
}

/// UI Model for Router Radio
class RouterRadioUIModel extends Equatable {
  final String radioID;
  final String band;
  final bool isEnabled;
  final String ssid;
  final int channel;
  final String channelWidth;
  final String security;

  const RouterRadioUIModel({
    required this.radioID,
    required this.band,
    required this.isEnabled,
    required this.ssid,
    required this.channel,
    required this.channelWidth,
    required this.security,
  });

  /// Factory constructor to create from JNAP model
  factory RouterRadioUIModel.fromJnap(RouterRadio radio) {
    return RouterRadioUIModel(
      radioID: radio.radioID,
      band: radio.band,
      isEnabled: radio.settings.isEnabled,
      ssid: radio.settings.ssid,
      channel: radio.settings.channel,
      channelWidth: radio.settings.channelWidth,
      security: radio.settings.security,
    );
  }

  RouterRadioUIModel copyWith({
    String? radioID,
    String? band,
    bool? isEnabled,
    String? ssid,
    int? channel,
    String? channelWidth,
    String? security,
  }) {
    return RouterRadioUIModel(
      radioID: radioID ?? this.radioID,
      band: band ?? this.band,
      isEnabled: isEnabled ?? this.isEnabled,
      ssid: ssid ?? this.ssid,
      channel: channel ?? this.channel,
      channelWidth: channelWidth ?? this.channelWidth,
      security: security ?? this.security,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'radioID': radioID,
      'band': band,
      'isEnabled': isEnabled,
      'ssid': ssid,
      'channel': channel,
      'channelWidth': channelWidth,
      'security': security,
    };
  }

  factory RouterRadioUIModel.fromMap(Map<String, dynamic> map) {
    return RouterRadioUIModel(
      radioID: map['radioID'] as String,
      band: map['band'] as String,
      isEnabled: map['isEnabled'] as bool,
      ssid: map['ssid'] as String,
      channel: map['channel'] as int,
      channelWidth: map['channelWidth'] as String,
      security: map['security'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory RouterRadioUIModel.fromJson(String source) =>
      RouterRadioUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props =>
      [radioID, band, isEnabled, ssid, channel, channelWidth, security];
}

/// UI Model for Guest Radio settings
class GuestRadioSettingsUIModel extends Equatable {
  final bool isGuestNetworkACaptivePortal;
  final bool isGuestNetworkEnabled;
  final List<GuestRadioUIModel> radios;

  const GuestRadioSettingsUIModel({
    required this.isGuestNetworkACaptivePortal,
    required this.isGuestNetworkEnabled,
    required this.radios,
  });

  const GuestRadioSettingsUIModel.initial()
      : isGuestNetworkACaptivePortal = false,
        isGuestNetworkEnabled = false,
        radios = const [];

  /// Factory constructor to create from JNAP model
  factory GuestRadioSettingsUIModel.fromJnap(GuestRadioSettings settings) {
    return GuestRadioSettingsUIModel(
      isGuestNetworkACaptivePortal: settings.isGuestNetworkACaptivePortal,
      isGuestNetworkEnabled: settings.isGuestNetworkEnabled,
      radios:
          settings.radios.map((r) => GuestRadioUIModel.fromJnap(r)).toList(),
    );
  }

  GuestRadioSettingsUIModel copyWith({
    bool? isGuestNetworkACaptivePortal,
    bool? isGuestNetworkEnabled,
    List<GuestRadioUIModel>? radios,
  }) {
    return GuestRadioSettingsUIModel(
      isGuestNetworkACaptivePortal:
          isGuestNetworkACaptivePortal ?? this.isGuestNetworkACaptivePortal,
      isGuestNetworkEnabled:
          isGuestNetworkEnabled ?? this.isGuestNetworkEnabled,
      radios: radios ?? this.radios,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isGuestNetworkACaptivePortal': isGuestNetworkACaptivePortal,
      'isGuestNetworkEnabled': isGuestNetworkEnabled,
      'radios': radios.map((x) => x.toMap()).toList(),
    };
  }

  factory GuestRadioSettingsUIModel.fromMap(Map<String, dynamic> map) {
    return GuestRadioSettingsUIModel(
      isGuestNetworkACaptivePortal: map['isGuestNetworkACaptivePortal'] as bool,
      isGuestNetworkEnabled: map['isGuestNetworkEnabled'] as bool,
      radios: List<GuestRadioUIModel>.from(
        (map['radios'] as List<dynamic>).map<GuestRadioUIModel>(
          (x) => GuestRadioUIModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory GuestRadioSettingsUIModel.fromJson(String source) =>
      GuestRadioSettingsUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props =>
      [isGuestNetworkACaptivePortal, isGuestNetworkEnabled, radios];
}

/// UI Model for Guest Radio
class GuestRadioUIModel extends Equatable {
  final String radioID;
  final bool isEnabled;
  final bool broadcastGuestSSID;
  final String guestSSID;

  const GuestRadioUIModel({
    required this.radioID,
    required this.isEnabled,
    required this.broadcastGuestSSID,
    required this.guestSSID,
  });

  /// Factory constructor to create from JNAP model
  factory GuestRadioUIModel.fromJnap(GuestRadioInfo info) {
    return GuestRadioUIModel(
      radioID: info.radioID,
      isEnabled: info.isEnabled,
      broadcastGuestSSID: info.broadcastGuestSSID,
      guestSSID: info.guestSSID,
    );
  }

  GuestRadioUIModel copyWith({
    String? radioID,
    bool? isEnabled,
    bool? broadcastGuestSSID,
    String? guestSSID,
  }) {
    return GuestRadioUIModel(
      radioID: radioID ?? this.radioID,
      isEnabled: isEnabled ?? this.isEnabled,
      broadcastGuestSSID: broadcastGuestSSID ?? this.broadcastGuestSSID,
      guestSSID: guestSSID ?? this.guestSSID,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'radioID': radioID,
      'isEnabled': isEnabled,
      'broadcastGuestSSID': broadcastGuestSSID,
      'guestSSID': guestSSID,
    };
  }

  factory GuestRadioUIModel.fromMap(Map<String, dynamic> map) {
    return GuestRadioUIModel(
      radioID: map['radioID'] as String,
      isEnabled: map['isEnabled'] as bool,
      broadcastGuestSSID: map['broadcastGuestSSID'] as bool,
      guestSSID: map['guestSSID'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory GuestRadioUIModel.fromJson(String source) =>
      GuestRadioUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [radioID, isEnabled, broadcastGuestSSID, guestSSID];
}

/// UI Model for WAN external information
class WanExternalUIModel extends Equatable {
  final String? publicWanIPv4;
  final String? publicWanIPv6;
  final String? privateWanIPv4;
  final String? privateWanIPv6;

  const WanExternalUIModel({
    this.publicWanIPv4,
    this.publicWanIPv6,
    this.privateWanIPv4,
    this.privateWanIPv6,
  });

  const WanExternalUIModel.initial()
      : publicWanIPv4 = null,
        publicWanIPv6 = null,
        privateWanIPv4 = null,
        privateWanIPv6 = null;

  /// Factory constructor to create from JNAP model
  factory WanExternalUIModel.fromJnap(WanExternal external) {
    return WanExternalUIModel(
      publicWanIPv4: external.publicWanIPv4,
      publicWanIPv6: external.publicWanIPv6,
      privateWanIPv4: external.privateWanIPv4,
      privateWanIPv6: external.privateWanIPv6,
    );
  }

  WanExternalUIModel copyWith({
    String? publicWanIPv4,
    String? publicWanIPv6,
    String? privateWanIPv4,
    String? privateWanIPv6,
  }) {
    return WanExternalUIModel(
      publicWanIPv4: publicWanIPv4 ?? this.publicWanIPv4,
      publicWanIPv6: publicWanIPv6 ?? this.publicWanIPv6,
      privateWanIPv4: privateWanIPv4 ?? this.privateWanIPv4,
      privateWanIPv6: privateWanIPv6 ?? this.privateWanIPv6,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'publicWanIPv4': publicWanIPv4,
      'publicWanIPv6': publicWanIPv6,
      'privateWanIPv4': privateWanIPv4,
      'privateWanIPv6': privateWanIPv6,
    }..removeWhere((key, value) => value == null);
  }

  factory WanExternalUIModel.fromMap(Map<String, dynamic> map) {
    return WanExternalUIModel(
      publicWanIPv4: map['publicWanIPv4'] as String?,
      publicWanIPv6: map['publicWanIPv6'] as String?,
      privateWanIPv4: map['privateWanIPv4'] as String?,
      privateWanIPv6: map['privateWanIPv6'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory WanExternalUIModel.fromJson(String source) =>
      WanExternalUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
        publicWanIPv4,
        publicWanIPv6,
        privateWanIPv4,
        privateWanIPv6,
      ];
}
