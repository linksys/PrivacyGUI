import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_status.dart';

/// State for the WiFi Settings page.
///
/// Extends [FeatureState] to integrate with the Dirty Guard framework:
///   - [settings.original] — last state fetched from the router.
///   - [settings.current]  — live state reflecting user edits.
///   - [isDirty] — true when there are unsaved changes (custom logic below).
///   - [canSave] — true when the Save button should be enabled.
class UspWifiSettingsState
    extends FeatureState<WifiSettingsSettings, WifiSettingsStatus> {
  const UspWifiSettingsState({
    required super.settings,
    required super.status,
  });

  factory UspWifiSettingsState.initial() => UspWifiSettingsState(
        settings: Preservable(
          original: WifiSettingsSettings.empty(),
          current: WifiSettingsSettings.empty(),
        ),
        status: const WifiSettingsStatus.loading(),
      );

  // ---------------------------------------------------------------------------
  // Custom isDirty: excludes [quickSetupEnabled] (UI mode switch, not data)
  // ---------------------------------------------------------------------------

  /// True when the user has unsaved changes.
  ///
  /// Compares [networks] and Quick Setup settings between `original` and
  /// `current`. The [quickSetupEnabled] flag is intentionally excluded —
  /// toggling the mode switch is not itself a "data change", but initialising
  /// the Quick Setup settings objects (via [setQuickSetupEnabled]) will set
  /// [quickSetupMain] / [quickSetupGuest] to non-null, which does trigger dirty.
  @override
  bool get isDirty {
    final orig = settings.original;
    final curr = settings.current;
    if (orig.networks != curr.networks) return true;
    if (orig.quickSetupMain != curr.quickSetupMain) return true;
    if (orig.quickSetupGuest != curr.quickSetupGuest) return true;
    return false;
  }

  // ---------------------------------------------------------------------------
  // canSave: dirty + valid
  // ---------------------------------------------------------------------------

  /// True when the Save button should be enabled.
  ///
  /// In **Quick Setup** mode: at least one group must have ACTUAL changes vs
  /// the original (to guard against spurious dirty states), and every changed
  /// group must be [WifiQuickSetupSettings.isValid].
  ///
  /// In **Advanced** mode: any dirty state is saveable (per-field validation
  /// is handled inline in the edit dialogs before updating settings).
  bool get canSave {
    if (!isDirty) return false;
    if (settings.current.quickSetupEnabled) {
      final origMain = settings.original.quickSetupMain;
      final origGuest = settings.original.quickSetupGuest;
      final main = settings.current.quickSetupMain;
      final guest = settings.current.quickSetupGuest;

      final mainChanged = main != null && main != origMain;
      final guestChanged = guest != null && guest != origGuest;

      // At least one group must have changed from the original.
      if (!mainChanged && !guestChanged) return false;

      // All changed groups must be valid.
      if (mainChanged && !main.isValid) return false;
      if (guestChanged && !guest.isValid) return false;

      return true;
    }
    return true;
  }

  @override
  UspWifiSettingsState copyWith({
    Preservable<WifiSettingsSettings>? settings,
    WifiSettingsStatus? status,
  }) {
    return UspWifiSettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'networksCount': settings.current.networks.length,
        'quickSetupEnabled': settings.current.quickSetupEnabled,
        'isDirty': isDirty,
        'canSave': canSave,
        'isLoading': status.isLoading,
      };
}
