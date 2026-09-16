import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// Why a firmware update failed — as a value the view can localize.
///
/// This replaces the `String? errorMessage` the state used to carry. That field was
/// written at thirteen call sites and rendered verbatim by
/// `FirmwareInstallPhaseCard`, so **twenty-five of twenty-six locales read English**
/// — and in two of those cases English plus a bare `fwup_state` number. The string
/// was assembled in the notifier, which is the one layer that has no `BuildContext`
/// and therefore no way to translate anything.
///
/// [FirmwareFailureReason] is what the view switches on. The switch is exhaustive, so
/// a new reason is a compile-time decision about its copy rather than a fourteenth
/// English literal — the same guarantee `localizeServiceError` gets from the sealed
/// [ServiceError] hierarchy.
enum FirmwareFailureReason {
  /// A typed [ServiceError] from the service layer. Localized by delegating to
  /// `localizeServiceError`, so that file stays the only place a [ServiceError]
  /// becomes a string.
  serviceError,

  /// The picked file has no bytes.
  fileEmpty,

  /// Too small to be a firmware image — [FirmwareFailure.number] is its size.
  ///
  /// Distinct from [fileTooLarge], which it used to share a `kind` with: the
  /// validator threw `tooLarge` for a file *below* the minimum, so the two
  /// conditions were one value and would have collapsed into one sentence here.
  fileTooSmall,

  /// Above the size ceiling — [FirmwareFailure.number] is its size.
  fileTooLarge,

  /// Not an `.img` or `.bin`. The rejected extension is diagnostic and stays in the
  /// log; what the copy carries is the two that work, which is the actionable half.
  fileTypeUnsupported,

  /// An upload was started with nothing picked.
  noImageSelected,

  /// The router published `fwup_state=5` — [FirmwareFailure.detail] is the raw
  /// value.
  ///
  /// The router stopped answering while an update was in flight —
  /// [FirmwareFailure.detail] is the last raw `fwup_state`.
  ///
  /// Never reported as "nothing found": the router having stopped reporting is not
  /// the router having nothing to report.
  progressStalled,

  /// The same stall, with no reading to name — the watch timed out before the
  /// router published a `fwup_state` at all.
  ///
  /// A second reason rather than a sentinel in [progressStalled]'s placeholder. The
  /// first attempt passed the literal string `unread`, which put an English word
  /// inside twenty-five translated sentences — the defect this whole class exists to
  /// remove, reintroduced through the one hole a placeholder leaves open. A
  /// placeholder can only carry something that is the same in every language; "there
  /// was no reading" is a sentence, so it needs its own.
  progressStalledNoReading,

  /// The router came back but its firmware slots could not be read.
  banksUnreadableAfterReboot,

  /// More than one slot claims to be active — [FirmwareFailure.number] is how many.
  multipleActiveBanks,

  /// The slot the update targeted is gone — [FirmwareFailure.number] is its
  /// instance.
  expectedBankMissing,

  /// The router rebooted into the old image — [FirmwareFailure.number] is the
  /// expected instance and [FirmwareFailure.detail] its reported status.
  bootedOldImage,
}

/// One firmware failure: a [reason] plus whatever that reason needs to be rendered.
///
/// One class with named constructors rather than a sealed hierarchy of thirteen, which
/// is the shape [FirmwareOtaCheckResult] already uses in this folder. The
/// constructors are where the typing lives — [FirmwareFailure.progressStalled]
/// cannot be built without its raw state — while [detail] and [number] are two
/// generic slots the mapper reads per arm.
class FirmwareFailure extends Equatable {
  final FirmwareFailureReason reason;

  /// The service-layer error, for [FirmwareFailureReason.serviceError] only.
  final ServiceError? error;

  /// A raw, untranslated token this failure needs to name: a `fwup_state` value or a
  /// TR-181 bank status. Never a sentence — a sentence here is the defect this class
  /// exists to remove.
  final String? detail;

  /// A count, a size in bytes, or a bank instance, depending on [reason].
  final int? number;

  const FirmwareFailure.serviceError(ServiceError this.error)
      : reason = FirmwareFailureReason.serviceError,
        detail = null,
        number = null;

  const FirmwareFailure.fileEmpty()
      : reason = FirmwareFailureReason.fileEmpty,
        error = null,
        detail = null,
        number = null;

  const FirmwareFailure.fileTooSmall({required int sizeBytes})
      : reason = FirmwareFailureReason.fileTooSmall,
        error = null,
        detail = null,
        number = sizeBytes;

  const FirmwareFailure.fileTooLarge({required int sizeBytes})
      : reason = FirmwareFailureReason.fileTooLarge,
        error = null,
        detail = null,
        number = sizeBytes;

  const FirmwareFailure.fileTypeUnsupported()
      : reason = FirmwareFailureReason.fileTypeUnsupported,
        error = null,
        detail = null,
        number = null;

  const FirmwareFailure.noImageSelected()
      : reason = FirmwareFailureReason.noImageSelected,
        error = null,
        detail = null,
        number = null;

  const FirmwareFailure.progressStalled({required String fwupState})
      : reason = FirmwareFailureReason.progressStalled,
        error = null,
        detail = fwupState,
        number = null;

  const FirmwareFailure.progressStalledNoReading()
      : reason = FirmwareFailureReason.progressStalledNoReading,
        error = null,
        detail = null,
        number = null;

  const FirmwareFailure.banksUnreadableAfterReboot()
      : reason = FirmwareFailureReason.banksUnreadableAfterReboot,
        error = null,
        detail = null,
        number = null;

  const FirmwareFailure.multipleActiveBanks({required int count})
      : reason = FirmwareFailureReason.multipleActiveBanks,
        error = null,
        detail = null,
        number = count;

  const FirmwareFailure.expectedBankMissing({required int instance})
      : reason = FirmwareFailureReason.expectedBankMissing,
        error = null,
        detail = null,
        number = instance;

  const FirmwareFailure.bootedOldImage({
    required int instance,
    required String status,
  })  : reason = FirmwareFailureReason.bootedOldImage,
        error = null,
        detail = status,
        number = instance;

  /// A log line. **Not** what the user reads — that comes from
  /// `localizeFirmwareFailure`, and this deliberately does not look like a sentence
  /// so it cannot be mistaken for one and shown.
  @override
  String toString() => 'FirmwareFailure(${reason.name}'
      '${error != null ? ', error: $error' : ''}'
      '${detail != null ? ', detail: $detail' : ''}'
      '${number != null ? ', number: $number' : ''})';

  @override
  List<Object?> get props => [reason, error, detail, number];
}
