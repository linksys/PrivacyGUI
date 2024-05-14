// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

// Only for 'GetGuestRadioSettings2'
class GuestRadioSettings extends Equatable {
  final bool isGuestNetworkACaptivePortal;
  final bool isGuestNetworkEnabled;
  final List<GuestRadioInfo> radios;
  final int? maxSimultaneousGuests;
  final GuestPasswordRestriction? guestPasswordRestrictions;
  final int? maxSimultaneousGuestsLimit;

  @override
  List<Object?> get props {
    return [
      isGuestNetworkACaptivePortal,
      isGuestNetworkEnabled,
      radios,
      maxSimultaneousGuests,
      guestPasswordRestrictions,
      maxSimultaneousGuestsLimit,
    ];
  }

  const GuestRadioSettings({
    required this.isGuestNetworkACaptivePortal,
    required this.isGuestNetworkEnabled,
    required this.radios,
    this.maxSimultaneousGuests,
    this.guestPasswordRestrictions,
    this.maxSimultaneousGuestsLimit,
  });

  GuestRadioSettings copyWith({
    bool? isGuestNetworkACaptivePortal,
    bool? isGuestNetworkEnabled,
    List<GuestRadioInfo>? radios,
    int? maxSimultaneousGuests,
    GuestPasswordRestriction? guestPasswordRestrictions,
    int? maxSimultaneousGuestsLimit,
  }) {
    return GuestRadioSettings(
      isGuestNetworkACaptivePortal:
          isGuestNetworkACaptivePortal ?? this.isGuestNetworkACaptivePortal,
      isGuestNetworkEnabled:
          isGuestNetworkEnabled ?? this.isGuestNetworkEnabled,
      radios: radios ?? this.radios,
      maxSimultaneousGuests:
          maxSimultaneousGuests ?? this.maxSimultaneousGuests,
      guestPasswordRestrictions:
          guestPasswordRestrictions ?? this.guestPasswordRestrictions,
      maxSimultaneousGuestsLimit:
          maxSimultaneousGuestsLimit ?? this.maxSimultaneousGuestsLimit,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isGuestNetworkACaptivePortal': isGuestNetworkACaptivePortal,
      'isGuestNetworkEnabled': isGuestNetworkEnabled,
      'radios': radios.map((x) => x.toMap()).toList(),
      'maxSimultaneousGuests': maxSimultaneousGuests,
      'guestPasswordRestrictions': guestPasswordRestrictions?.toMap(),
      'maxSimultaneousGuestsLimit': maxSimultaneousGuestsLimit,
    }..removeWhere((key, value) => value == null);
  }

  factory GuestRadioSettings.fromMap(Map<String, dynamic> map) {
    return GuestRadioSettings(
      isGuestNetworkACaptivePortal: map['isGuestNetworkACaptivePortal'] as bool,
      isGuestNetworkEnabled: map['isGuestNetworkEnabled'] as bool,
      radios: List<GuestRadioInfo>.from(
        (map['radios']).map<GuestRadioInfo>(
          (x) => GuestRadioInfo.fromMap(x as Map<String, dynamic>),
        ),
      ),
      maxSimultaneousGuests: map['maxSimultaneousGuests'] != null
          ? map['maxSimultaneousGuests'] as int
          : null,
      guestPasswordRestrictions: map['guestPasswordRestrictions'] != null
          ? GuestPasswordRestriction.fromMap(
              map['guestPasswordRestrictions'] as Map<String, dynamic>)
          : null,
      maxSimultaneousGuestsLimit: map['maxSimultaneousGuestsLimit'] != null
          ? map['maxSimultaneousGuestsLimit'] as int
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory GuestRadioSettings.fromJson(String source) =>
      GuestRadioSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

class SetGuestRadioSettings extends Equatable {
  final bool isGuestNetworkEnabled;
  final List<GuestRadioInfo> radios;
  final int? maxSimultaneousGuests;

  const SetGuestRadioSettings({
    required this.isGuestNetworkEnabled,
    required this.radios,
    this.maxSimultaneousGuests,
  });

  factory SetGuestRadioSettings.fromGuestRadioSettings(
      GuestRadioSettings settings) {
    return SetGuestRadioSettings(
      isGuestNetworkEnabled: settings.isGuestNetworkEnabled,
      radios: settings.radios,
      maxSimultaneousGuests: settings.maxSimultaneousGuests,
    );
  }

  @override
  List<Object?> get props => [
        isGuestNetworkEnabled,
        radios,
        maxSimultaneousGuests,
      ];

  SetGuestRadioSettings copyWith({
    bool? isGuestNetworkEnabled,
    List<GuestRadioInfo>? radios,
    int? maxSimultaneousGuests,
  }) {
    return SetGuestRadioSettings(
      isGuestNetworkEnabled:
          isGuestNetworkEnabled ?? this.isGuestNetworkEnabled,
      radios: radios ?? this.radios,
      maxSimultaneousGuests:
          maxSimultaneousGuests ?? this.maxSimultaneousGuests,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isGuestNetworkEnabled': isGuestNetworkEnabled,
      'radios': radios.map((x) => x.toMap()).toList(),
      'maxSimultaneousGuests': maxSimultaneousGuests,
    }..removeWhere((key, value) => value == null);
  }

  factory SetGuestRadioSettings.fromMap(Map<String, dynamic> map) {
    return SetGuestRadioSettings(
      isGuestNetworkEnabled: map['isGuestNetworkEnabled'] as bool,
      radios: List<GuestRadioInfo>.from(
        (map['radios'] as List<int>).map<GuestRadioInfo>(
          (x) => GuestRadioInfo.fromMap(x as Map<String, dynamic>),
        ),
      ),
      maxSimultaneousGuests: map['maxSimultaneousGuests'] != null
          ? map['maxSimultaneousGuests'] as int
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SetGuestRadioSettings.fromJson(String source) =>
      SetGuestRadioSettings.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

class GuestRadioInfo extends Equatable {
  final String radioID;
  final bool isEnabled;
  final bool broadcastGuestSSID;
  final String guestSSID;
  final String? guestPassword;
  final String? guestWPAPassphrase;
  final bool? canEnableRadio;

  const GuestRadioInfo({
    required this.radioID,
    required this.isEnabled,
    required this.broadcastGuestSSID,
    required this.guestSSID,
    this.guestPassword,
    this.guestWPAPassphrase,
    this.canEnableRadio,
  });

  GuestRadioInfo copyWith({
    String? radioID,
    bool? isEnabled,
    bool? broadcastGuestSSID,
    String? guestSSID,
    String? guestPassword,
    String? guestWPAPassphrase,
    bool? canEnableRadio,
  }) {
    return GuestRadioInfo(
      radioID: radioID ?? this.radioID,
      isEnabled: isEnabled ?? this.isEnabled,
      broadcastGuestSSID: broadcastGuestSSID ?? this.broadcastGuestSSID,
      guestSSID: guestSSID ?? this.guestSSID,
      guestPassword: guestPassword ?? this.guestPassword,
      guestWPAPassphrase: guestWPAPassphrase ?? this.guestWPAPassphrase,
      canEnableRadio: canEnableRadio ?? this.canEnableRadio,
    );
  }

  @override
  List<Object?> get props {
    return [
      radioID,
      isEnabled,
      broadcastGuestSSID,
      guestSSID,
      guestPassword,
      guestWPAPassphrase,
      canEnableRadio,
    ];
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'radioID': radioID,
      'isEnabled': isEnabled,
      'broadcastGuestSSID': broadcastGuestSSID,
      'guestSSID': guestSSID,
      'guestPassword': guestPassword,
      'guestWPAPassphrase': guestWPAPassphrase,
      'canEnableRadio': canEnableRadio,
    }..removeWhere((key, value) => value == null);
  }

  factory GuestRadioInfo.fromMap(Map<String, dynamic> map) {
    return GuestRadioInfo(
      radioID: map['radioID'] as String,
      isEnabled: map['isEnabled'] as bool,
      broadcastGuestSSID: map['broadcastGuestSSID'] as bool,
      guestSSID: map['guestSSID'] as String,
      guestPassword:
          map['guestPassword'] != null ? map['guestPassword'] as String : null,
      guestWPAPassphrase: map['guestWPAPassphrase'] != null
          ? map['guestWPAPassphrase'] as String
          : null,
      canEnableRadio:
          map['canEnableRadio'] != null ? map['canEnableRadio'] as bool : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory GuestRadioInfo.fromJson(String source) =>
      GuestRadioInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

class GuestPasswordRestriction extends Equatable {
  final int minLength;
  final int maxLength;
  final List<UnicodeRange> allowedCharacters;

  @override
  List<Object> get props => [
        minLength,
        maxLength,
        allowedCharacters,
      ];

  const GuestPasswordRestriction({
    required this.minLength,
    required this.maxLength,
    required this.allowedCharacters,
  });

  GuestPasswordRestriction copyWith({
    int? minLength,
    int? maxLength,
    List<UnicodeRange>? allowedCharacters,
  }) {
    return GuestPasswordRestriction(
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      allowedCharacters: allowedCharacters ?? this.allowedCharacters,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'minLength': minLength,
      'maxLength': maxLength,
      'allowedCharacters': allowedCharacters.map((x) => x.toMap()).toList(),
    }..removeWhere((key, value) => value == null);
  }

  factory GuestPasswordRestriction.fromMap(Map<String, dynamic> map) {
    return GuestPasswordRestriction(
      minLength: map['minLength'] as int,
      maxLength: map['maxLength'] as int,
      allowedCharacters: List<UnicodeRange>.from(
        (map['allowedCharacters']).map<UnicodeRange>(
          (x) => UnicodeRange.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory GuestPasswordRestriction.fromJson(String source) =>
      GuestPasswordRestriction.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

class UnicodeRange extends Equatable {
  final int lowCodepoint;
  final int highCodepoint;

  @override
  List<Object> get props => [lowCodepoint, highCodepoint];

  const UnicodeRange({
    required this.lowCodepoint,
    required this.highCodepoint,
  });

  UnicodeRange copyWith({
    int? lowCodepoint,
    int? highCodepoint,
  }) {
    return UnicodeRange(
      lowCodepoint: lowCodepoint ?? this.lowCodepoint,
      highCodepoint: highCodepoint ?? this.highCodepoint,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lowCodepoint': lowCodepoint,
      'highCodepoint': highCodepoint,
    }..removeWhere((key, value) => value == null);
  }

  factory UnicodeRange.fromMap(Map<String, dynamic> map) {
    return UnicodeRange(
      lowCodepoint: map['lowCodepoint'] as int,
      highCodepoint: map['highCodepoint'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory UnicodeRange.fromJson(String source) =>
      UnicodeRange.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
