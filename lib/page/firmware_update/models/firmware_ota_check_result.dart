import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';

/// What the last OTA check said — four values, and only three of them are lines the
/// card can draw.
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
enum FirmwareOtaCheckVerdict {
  notChecked,
  updateAvailable,
  noUpdateFound,

  /// The router said why the check failed — `FirmwareOtaCheckResult.errorCode` is
  /// which reason (#1572).
  ///
  /// A fourth value rather than a throw, and the difference matters at the layer
  /// above: the service's other failures are `ServiceError`s about the *transport*,
  /// which the view localizes with `localizeServiceError`, while this one is a
  /// firmware reason the router named and belongs to `localizeFirmwareFailure`.
  /// Carrying it as a verdict lets the notifier put it in
  /// `FirmwareUpdateState.failure` where that mapper already reads.
  ///
  /// It draws **no verdict line**. A failed check has said nothing about the
  /// firmware on the router, so the card stays as silent as it is for
  /// [notChecked]; the reason goes to the snack bar, which does not outlive the
  /// next check.
  checkFailed,
}

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

  /// The reason the router gave, for [FirmwareOtaCheckVerdict.checkFailed] only.
  final FirmwareUpdateErrorCode? errorCode;

  const FirmwareOtaCheckResult.notChecked()
      : verdict = FirmwareOtaCheckVerdict.notChecked,
        version = '',
        errorCode = null;

  const FirmwareOtaCheckResult.updateAvailable({this.version = ''})
      : verdict = FirmwareOtaCheckVerdict.updateAvailable,
        errorCode = null;

  const FirmwareOtaCheckResult.noUpdateFound()
      : verdict = FirmwareOtaCheckVerdict.noUpdateFound,
        version = '',
        errorCode = null;

  /// The check ran and the router named why it failed.
  ///
  /// The assert is the same contract `FirmwareFailure.routerReported` carries: a
  /// code that is not a failure cannot become one here either, because
  /// [FirmwareOtaCheckVerdict.checkFailed] is what makes the page say the check
  /// failed.
  const FirmwareOtaCheckResult.checkFailed(FirmwareUpdateErrorCode code)
      : assert(code != FirmwareUpdateErrorCode.none &&
            code != FirmwareUpdateErrorCode.unknown &&
            code != FirmwareUpdateErrorCode.unreported),
        verdict = FirmwareOtaCheckVerdict.checkFailed,
        version = '',
        errorCode = code;

  bool get isUpdateAvailable =>
      verdict == FirmwareOtaCheckVerdict.updateAvailable;

  @override
  List<Object?> get props => [verdict, version, errorCode];
}
