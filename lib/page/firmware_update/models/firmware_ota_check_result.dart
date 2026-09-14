import 'package:equatable/equatable.dart';

/// What the last OTA check said — three values, and the third is not a fourth.
///
/// [notChecked] is the resting state and also where a *failed* check lands: a
/// check that could not run has said nothing, and the one thing it must not be
/// allowed to say is [noUpdateFound]. That conflation is the whole reason this is
/// an enum rather than the pair of `otaInfo`/`otaUpToDate` flags it replaces —
/// with two booleans, "no info and not up to date" and "checked, nothing new"
/// were one state away from each other and nothing named the difference.
///
/// "The router has no ota row at all" is deliberately *not* a value here. It is a
/// property of the router, not of a check, and it is read from
/// `FirmwareBanksData.otaInstance` — a card that renders it from the same enum
/// would be able to show "not available" after a check that ran.
enum FirmwareOtaCheckVerdict { notChecked, updateAvailable, noUpdateFound }

/// The result of one OTA check.
class FirmwareOtaCheckResult extends Equatable {
  final FirmwareOtaCheckVerdict verdict;

  /// The version the router is offering, for [FirmwareOtaCheckVerdict.updateAvailable].
  ///
  /// Empty rather than null when the router reports an image with no version
  /// string, which it is allowed to do — the same reading the dashboard banner
  /// keys its dismissal on. Callers render the version only when it is non-empty;
  /// an offer with no name is still an offer.
  final String version;

  const FirmwareOtaCheckResult.notChecked()
      : verdict = FirmwareOtaCheckVerdict.notChecked,
        version = '';

  const FirmwareOtaCheckResult.updateAvailable({this.version = ''})
      : verdict = FirmwareOtaCheckVerdict.updateAvailable;

  const FirmwareOtaCheckResult.noUpdateFound()
      : verdict = FirmwareOtaCheckVerdict.noUpdateFound,
        version = '';

  bool get isUpdateAvailable =>
      verdict == FirmwareOtaCheckVerdict.updateAvailable;

  @override
  List<Object?> get props => [verdict, version];
}
