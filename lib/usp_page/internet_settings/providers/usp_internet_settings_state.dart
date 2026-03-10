import 'package:equatable/equatable.dart';
import 'package:privacy_gui/generated/ipv6settings.g.dart';
import 'package:privacy_gui/generated/wan_settings.g.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_wan_connection_type.dart';

/// State for the USP Internet Settings page.
///
/// Holds both the raw fetched data (for read-only display) and an editable
/// form snapshot for dirty checking and save operations.
class UspInternetSettingsState extends Equatable {
  /// Raw fetched WAN settings (for display of read-only fields).
  final WanSettings wanSettings;

  /// Raw fetched IPv6 settings (for display of read-only fields).
  final Ipv6Settings ipv6Settings;

  /// Form snapshot captured after fetch — used as the baseline for dirty checking.
  final UspInternetSettingsForm original;

  /// Actively-edited form — updated on every user interaction.
  final UspInternetSettingsForm edited;

  /// Whether the user is in edit mode.
  final bool isEditing;

  const UspInternetSettingsState({
    required this.wanSettings,
    required this.ipv6Settings,
    required this.original,
    required this.edited,
    this.isEditing = false,
  });

  /// Whether the edited form differs from the original.
  bool get isDirty => original != edited;

  /// Current connection type from the edited form.
  UspWanConnectionType get connectionType => edited.connectionType;

  /// Whether the device is in bridge mode.
  bool get isBridgeMode => connectionType == UspWanConnectionType.bridge;

  // --- Read-only convenience getters ---
  String get currentMacAddress => wanSettings.currentMacAddress;
  String get pppConnectionStatus => wanSettings.pppConnectionStatus;
  String get dhcpv6Duid => ipv6Settings.dhcpv6Duid;

  UspInternetSettingsState copyWith({
    WanSettings? wanSettings,
    Ipv6Settings? ipv6Settings,
    UspInternetSettingsForm? original,
    UspInternetSettingsForm? edited,
    bool? isEditing,
  }) {
    return UspInternetSettingsState(
      wanSettings: wanSettings ?? this.wanSettings,
      ipv6Settings: ipv6Settings ?? this.ipv6Settings,
      original: original ?? this.original,
      edited: edited ?? this.edited,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [
        wanSettings.toString(),
        ipv6Settings.toString(),
        original,
        edited,
        isEditing,
      ];
}
