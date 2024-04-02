import 'package:equatable/equatable.dart';

// Only for 'GetGuestRadioSettings2'
class GuestRadioSetting extends Equatable {
  final bool isGuestNetworkACaptivePortal;
  final bool isGuestNetworkEnabled;
  final List<GuestRadioInfo> radios;
  final int? maxSimultaneousGuests;
  final GuestPasswordRestriction? guestPasswordRestrictions;
  final int? maxSimultaneousGuestsLimit;

  @override
  List<Object?> get props => [
        isGuestNetworkACaptivePortal,
        isGuestNetworkEnabled,
        radios,
        maxSimultaneousGuests,
        guestPasswordRestrictions,
        maxSimultaneousGuestsLimit,
      ];

  const GuestRadioSetting({
    required this.isGuestNetworkACaptivePortal,
    required this.isGuestNetworkEnabled,
    required this.radios,
    this.maxSimultaneousGuests,
    this.guestPasswordRestrictions,
    this.maxSimultaneousGuestsLimit,
  });

  GuestRadioSetting copyWith({
    bool? isGuestNetworkACaptivePortal,
    bool? isGuestNetworkEnabled,
    List<GuestRadioInfo>? radios,
    int? maxSimultaneousGuests,
    GuestPasswordRestriction? guestPasswordRestrictions,
    int? maxSimultaneousGuestsLimit,
  }) {
    return GuestRadioSetting(
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

  Map<String, dynamic> toJson() {
    return {
      'isGuestNetworkACaptivePortal': isGuestNetworkACaptivePortal,
      'isGuestNetworkEnabled': isGuestNetworkEnabled,
      'radios': radios,
      'maxSimultaneousGuests': maxSimultaneousGuests,
      'guestPasswordRestrictions': guestPasswordRestrictions,
      'maxSimultaneousGuestsLimit': maxSimultaneousGuestsLimit,
    }..removeWhere((key, value) => value == null);
  }

  factory GuestRadioSetting.fromJson(Map<String, dynamic> json) {
    return GuestRadioSetting(
      isGuestNetworkACaptivePortal: json['isGuestNetworkACaptivePortal'],
      isGuestNetworkEnabled: json['isGuestNetworkEnabled'],
      radios: List.from(json['radios'])
          .map((e) => GuestRadioInfo.fromJson(e))
          .toList(),
      maxSimultaneousGuests: json['maxSimultaneousGuests'],
      guestPasswordRestrictions: json['guestPasswordRestrictions'] != null
          ? GuestPasswordRestriction.fromJson(json['guestPasswordRestrictions'])
          : null,
      maxSimultaneousGuestsLimit: json['maxSimultaneousGuestsLimit'],
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'radioID': radioID,
      'isEnabled': isEnabled,
      'broadcastGuestSSID': broadcastGuestSSID,
      'guestSSID': guestSSID,
      'guestPassword': guestPassword,
      'guestWPAPassphrase': guestWPAPassphrase,
      'canEnableRadio': canEnableRadio,
    }..removeWhere((key, value) => value == null);
  }

  factory GuestRadioInfo.fromJson(Map<String, dynamic> json) {
    return GuestRadioInfo(
      radioID: json['radioID'],
      isEnabled: json['isEnabled'],
      broadcastGuestSSID: json['broadcastGuestSSID'],
      guestSSID: json['guestSSID'],
      guestPassword: json['guestPassword'],
      guestWPAPassphrase: json['guestWPAPassphrase'],
      canEnableRadio: json['canEnableRadio'],
    );
  }

  @override
  List<Object?> get props => [
        radioID,
        isEnabled,
        broadcastGuestSSID,
        guestSSID,
        guestPassword,
        guestWPAPassphrase,
        canEnableRadio,
      ];
}

class GuestPasswordRestriction extends Equatable {
  final int minLength;
  final int maxLength;
  final List<UnicodeRange> allowedCharacters;

  @override
  List<Object?> get props => [
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

  Map<String, dynamic> toJson() {
    return {
      'minLength': minLength,
      'maxLength': maxLength,
      'allowedCharacters': allowedCharacters,
    }..removeWhere((key, value) => value == null);
  }

  factory GuestPasswordRestriction.fromJson(Map<String, dynamic> json) {
    return GuestPasswordRestriction(
      minLength: json['minLength'],
      maxLength: json['maxLength'],
      allowedCharacters: List.from(json['allowedCharacters'])
          .map((e) => UnicodeRange.fromJson(e))
          .toList(),
    );
  }
}

class UnicodeRange extends Equatable {
  final int lowCodepoint;
  final int highCodepoint;

  @override
  List<Object?> get props => [
        lowCodepoint,
        highCodepoint,
      ];

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

  Map<String, dynamic> toJson() {
    return {
      'lowCodepoint': lowCodepoint,
      'highCodepoint': highCodepoint,
    }..removeWhere((key, value) => value == null);
  }

  factory UnicodeRange.fromJson(Map<String, dynamic> json) {
    return UnicodeRange(
      lowCodepoint: json['lowCodepoint'],
      highCodepoint: json['highCodepoint'],
    );
  }
}
