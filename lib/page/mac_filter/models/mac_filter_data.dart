import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_mode.dart';

/// The MAC filter as the device has it applied: the mode and its list.
///
/// One state behind both Instant Privacy (`Allow`) and MAC Filter (`Deny`).
class MacFilterData extends Equatable {
  final MacFilterMode mode;
  final List<String> macs;

  const MacFilterData({required this.mode, required this.macs});

  /// Reads the two leaves as the firmware returns them. The list leaf is
  /// comma-joined with no spaces, and an empty string when the list is empty,
  /// so it is split on ',' only after guarding for empty.
  factory MacFilterData.fromWire(String mode, String list) {
    final trimmed = list.trim();
    return MacFilterData(
      mode: MacFilterMode.fromWire(mode),
      macs: trimmed.isEmpty
          ? const []
          : trimmed
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
    );
  }

  /// Instant Privacy is the filter in `Allow`; MAC Filter's `Deny` is not it.
  bool get isInstantPrivacyOn => mode == MacFilterMode.allow;

  @override
  List<Object?> get props => [mode, macs];
}
