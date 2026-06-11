import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

class PnpWiFiRadio extends Equatable {
  final String radioId;
  final String band;
  final String ssid;
  final String password;
  final String security;
  final bool isEnabled;

  const PnpWiFiRadio({
    required this.radioId,
    required this.band,
    required this.ssid,
    required this.password,
    required this.security,
    required this.isEnabled,
  });

  PnpWiFiRadio copyWith({
    String? radioId,
    String? band,
    String? ssid,
    String? password,
    String? security,
    bool? isEnabled,
  }) {
    return PnpWiFiRadio(
      radioId: radioId ?? this.radioId,
      band: band ?? this.band,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      security: security ?? this.security,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  List<Object?> get props => [radioId, band, ssid, password, security, isEnabled];
}

class PnpWiFiSettings extends Equatable {
  final bool isSplitMode;
  final List<PnpWiFiRadio> radios;

  const PnpWiFiSettings({
    required this.isSplitMode,
    required this.radios,
  });

  /// Primary radio: prioritize 2.4GHz, fallback to first
  PnpWiFiRadio? get primaryRadio =>
      radios.firstWhereOrNull((r) => r.band.contains('2.4')) ??
      radios.firstOrNull;

  @override
  List<Object?> get props => [isSplitMode, radios];
}
