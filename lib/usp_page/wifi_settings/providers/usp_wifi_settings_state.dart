import 'package:equatable/equatable.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/usp_page/wifi_settings/models/wifi_network_ui_model.dart';

class UspWifiSettingsState extends Equatable {
  // --- Raw codegen data (kept for future mutation operations) ---
  final WiFiSsids ssids;
  final WiFiAccessPoints accessPoints;
  final WiFiRadios radios;

  // --- UI models for views ---
  final List<WifiNetworkUIModel> networks;

  const UspWifiSettingsState({
    required this.ssids,
    required this.accessPoints,
    required this.radios,
    required this.networks,
  });

  UspWifiSettingsState copyWith({
    WiFiSsids? ssids,
    WiFiAccessPoints? accessPoints,
    WiFiRadios? radios,
    List<WifiNetworkUIModel>? networks,
  }) {
    return UspWifiSettingsState(
      ssids: ssids ?? this.ssids,
      accessPoints: accessPoints ?? this.accessPoints,
      radios: radios ?? this.radios,
      networks: networks ?? this.networks,
    );
  }

  @override
  List<Object?> get props => [ssids, accessPoints, radios, networks];

  Map<String, dynamic> toMap() => {
        'ssids': ssids.items.length,
        'accessPoints': accessPoints.items.length,
        'radios': radios.items.length,
        'networks': networks.map((n) => n.toMap()).toList(),
      };

  Map<String, dynamic> toJson() => toMap();

  factory UspWifiSettingsState.fromMap(Map<String, dynamic> map) =>
      throw UnimplementedError('Use provider build() to construct state');
}
