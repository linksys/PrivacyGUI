import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

/// User-editable MAC-filter settings, shared by both the MAC Filter page
/// (Deny/Disabled) and Instant Privacy (Allow/Disabled).
///
/// The device carries a single `X_LINKSYS_MACFilterMode` plus one
/// `X_LINKSYS_MACFilterList`, so both features edit the same two fields — which
/// is why they are mutually exclusive (only one non-Disabled mode at a time).
/// This is the `TSettings` of the Preservable dirty-check, so it is `Equatable`
/// and holds the list as a plain `List<String>` compared by contents.
class MacFilterSettings extends Equatable {
  final MacFilterMode mode;
  final List<String> macs;

  const MacFilterSettings({required this.mode, required this.macs});

  const MacFilterSettings.empty()
      : mode = MacFilterMode.disabled,
        macs = const [];

  /// True when a filter is active in either direction.
  bool get isEnabled => mode != MacFilterMode.disabled;

  MacFilterSettings copyWith({MacFilterMode? mode, List<String>? macs}) {
    return MacFilterSettings(
      mode: mode ?? this.mode,
      macs: macs ?? this.macs,
    );
  }

  @override
  List<Object?> get props => [mode, macs];
}
