import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/firmware_auto_update.g.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/generated/firmware_operations.g.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';

final uspFirmwareUpdateServiceProvider = Provider<UspFirmwareUpdateService>(
  (ref) => UspFirmwareUpdateService(ref.read(uspClientProvider)!),
);

class UspFirmwareUpdateService {
  final UspClient _usp;

  UspFirmwareUpdateService(this._usp);

  static const String localFirmwarePath = '/tmp/obuspa/firmware.img';

  Future<List<FirmwareImageUIModel>> fetchAllBanks() async {
    try {
      final images = await FirmwareImages.fetch(_usp);
      return images.items.map(_toUIModel).toList();
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  Future<FirmwareImageUIModel> fetchActiveBank() async {
    final all = await fetchAllBanks();
    return all.firstWhere(
      (b) => b.isActive,
      orElse: () => throw UspCompleteFailureError(
        summary: 'No active firmware bank found',
        failures: const [],
      ),
    );
  }

  Future<FirmwareImageUIModel> fetchAvailableBank() async {
    final all = await fetchAllBanks();
    return all.firstWhere(
      (b) => b.available && !b.isActive,
      orElse: () => throw UspCompleteFailureError(
        summary: 'No available firmware bank found',
        failures: const [],
      ),
    );
  }

  Future<void> triggerLocalDownload({
    required int targetInstance,
    String localPath = localFirmwarePath,
    bool autoActivate = true,
  }) async {
    try {
      await FirmwareOperations.download(
        _usp,
        targetInstance,
        url: 'file://$localPath',
        autoActivate: autoActivate ? 'true' : 'false',
      );
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Asks the router to go and look for a newer image, and returns the key that
  /// names the request.
  ///
  /// The third `Download` on this service and the only one that is not a flash.
  /// Two things make it a look rather than an install:
  ///
  /// * `AutoActivate="false"` — `fwupd -m 3`, which checks and stops. `"true"` is
  ///   the download-and-reboot mode [requestOtaInstall] uses.
  /// * **no `URL` at all.** For the virtual `ota` instance the router ignores the
  ///   parameter and delegates to `fwupd`, which resolves the OTA server itself.
  ///   Absent rather than empty, because an empty URL is a value nothing has been
  ///   asked to interpret.
  ///
  /// Nothing is downloaded and nothing reboots, which is why this is the one
  /// `Download` here with no `DisruptionClass` seam above it.
  ///
  /// **Throws when the response carries no `commandKey`, but not on the first
  /// one.** That key is the whole of what the operate response tells us —
  /// measured, an Operate for a command that does not exist and one with a
  /// misspelled argument name both answer success — so its absence is the
  /// difference between "asked" and "did not ask", and it must never reach a
  /// caller as a check that found nothing.
  ///
  /// **One retry, measured into existence** (2026-09-16). On a real router the
  /// first `Download(ota, "false")` after login answered `{}` in 813 ms with no
  /// key; the identical call 14 s later returned one and the check completed. So
  /// the empty answer is transient at least sometimes, and the cost of finding out
  /// is one more Operate against a command that only checks. Without the retry the
  /// user's first tap reports a check that never started and they have to tap
  /// again — which is what happened.
  ///
  /// **Exactly one, and only here.** A loop would turn a genuinely broken router
  /// into a spinner; the second empty answer still throws, with the same sentence.
  /// And [requestOtaInstall] deliberately does **not** retry: `AutoActivate="true"`
  /// downloads, flashes and reboots, so a lost response is not the only thing a
  /// second dispatch could cost. The asymmetry is the point — a repeated check is
  /// free, a repeated flash is not.
  ///
  /// Both attempts run inside whatever lock the caller holds, which is correct: two
  /// dispatches are two mutations, and neither may interleave with another.
  Future<String> requestOtaCheck({required int otaInstance}) async {
    try {
      var commandKey = await _dispatchOtaCheck(otaInstance);
      if (commandKey == null) {
        logger.w('[FirmwareUpdate] the router answered Download() on instance '
            '$otaInstance with no commandKey — dispatching the check once more');
        commandKey = await _dispatchOtaCheck(otaInstance);
      }
      if (commandKey == null) {
        throw UspCompleteFailureError(
          summary: 'Firmware check was not dispatched: the router answered '
              'Download() on instance $otaInstance with no commandKey, twice',
          failures: const [],
        );
      }
      logger.d('[FirmwareUpdate] OTA check dispatched on instance '
          '$otaInstance (commandKey=$commandKey)');
      return commandKey;
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// One check dispatch: the `commandKey` it answered, or null if it answered none.
  ///
  /// Null rather than a throw so [requestOtaCheck] owns the retry decision in one
  /// place — a helper that threw would have to be caught to be retried, and the
  /// catch would be indistinguishable from the transport errors this must not
  /// swallow.
  Future<String?> _dispatchOtaCheck(int otaInstance) async {
    final response = await FirmwareOperations.download(
      _usp,
      otaInstance,
      autoActivate: 'false',
    );
    final commandKey = response['commandKey']?.toString();
    return (commandKey == null || commandKey.isEmpty) ? null : commandKey;
  }

  /// Asks the router to fetch and install a newer image, and returns the key that
  /// names the request.
  ///
  /// The same `Download` as [requestOtaCheck] with `AutoActivate` flipped, and the
  /// URL absent for the same reason: on the virtual `ota` instance the parameter
  /// is ignored and `fwupd` resolves the OTA server itself.
  ///
  /// **There is no cloud-URL sibling any more.** A `triggerOtaDownload` used to sit
  /// above, taking a URL the cloud OTA API supplied and answering `void`; the cloud
  /// path was deleted on 2026-09-16 — #1550's "separate decision", decided, because
  /// the feature is not coming. The return type is why this was never folded into it
  /// anyway: the `commandKey` is the only part of the operate response that carries
  /// information, and the install needs it to tell its own `OperationComplete` from
  /// another command's. A second optional-URL overload of the flash verb would also
  /// mean two ways to start one, which is the hazard
  /// [FirmwareRouterOtaCheckService] is arranged to make impossible.
  ///
  /// **`AutoActivate="true"` is `fwupd -m 2`, which checks first.** So this
  /// dispatch is not "install the version we just showed you": `fwup_state` goes
  /// `1` before `3`, `fwup_progress` runs `0→100` twice, and the router's own
  /// check may conclude there is nothing to fetch — in which case the flash never
  /// starts and the state returns to `0`. Callers must be able to say so.
  ///
  /// None of the three keep-config inputs (`X_LINKSYS_KeepConfig`,
  /// `X_LINKSYS_KeepOpConf`, `X_LINKSYS_ConfigScope`) is sent: the router's
  /// default applies, and the UI does not offer the choice.
  ///
  /// **Throws when the response carries no `commandKey`** — same measurement as
  /// the check (an Operate on a command that does not exist answers success), and
  /// more consequential here: with no key there is nothing to match a refusal
  /// against, so a rejected flash would look like one still running.
  ///
  /// **And unlike the check, it does not retry.** [requestOtaCheck] dispatches a
  /// second time when the first answer carries no key, because a repeated check
  /// costs one Operate. This mode downloads, flashes and reboots, so a second
  /// dispatch is not free even if the first response was merely lost — the router
  /// may already be acting on it. One empty answer here is reported, not retried.
  Future<String> requestOtaInstall({required int otaInstance}) async {
    try {
      final response = await FirmwareOperations.download(
        _usp,
        otaInstance,
        autoActivate: 'true',
      );
      final commandKey = response['commandKey']?.toString();
      if (commandKey == null || commandKey.isEmpty) {
        throw UspCompleteFailureError(
          summary: 'Firmware install was not dispatched: the router answered '
              'Download() on instance $otaInstance with no commandKey',
          failures: const [],
        );
      }
      logger.d('[FirmwareUpdate] OTA install dispatched on instance '
          '$otaInstance (commandKey=$commandKey)');
      return commandKey;
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  Future<String> pollStatus(int instance) async {
    try {
      final images = await FirmwareImages.fetch(_usp);
      final match = images.items.firstWhere(
        (i) => _instanceFromPath(i.instancePath) == instance,
        orElse: () => throw UspCompleteFailureError(
          summary: 'Firmware bank instance $instance not found',
          failures: const [],
        ),
      );
      return match.status;
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Verifies a successful firmware activation after a reboot.
  ///
  /// Primary signal: the bank at [expectedActiveInstance] has flipped to
  /// `Active`. Bank flip — not version equality — is the rigorous check,
  /// because dev/QA scenarios legitimately flash the same version onto a
  /// different bank to validate the boot path.
  ///
  /// Returns `true` when the expected bank is Active and reports the
  /// expected version, `false` for version mismatch, and throws a
  /// [ServiceError] for the more serious classes of failure (router did
  /// not boot the new image; inconsistent multi-Active state).
  Future<bool> verifyAfterReboot({
    required String expectedVersion,
    required int expectedActiveInstance,
  }) async {
    try {
      final images = await FirmwareImages.fetch(_usp);
      logger.d(
          '[FirmwareUpdate] service.verifyAfterReboot: banks=${images.items.map((i) => '${i.instancePath}:${i.status}').join(', ')}'
          ', expectedActiveInstance=$expectedActiveInstance, expectedVersion=$expectedVersion');
      final activeBanks =
          images.items.where((i) => i.status == 'Active').toList();
      if (activeBanks.length > 1) {
        throw UspCompleteFailureError(
          summary:
              'Inconsistent firmware state: ${activeBanks.length} banks reported Active',
          failures: const [],
        );
      }
      final match = images.items.firstWhere(
        (i) => _instanceFromPath(i.instancePath) == expectedActiveInstance,
        orElse: () => throw UspCompleteFailureError(
          summary: 'Expected firmware bank instance $expectedActiveInstance '
              'not present after reboot',
          failures: const [],
        ),
      );
      if (match.status != 'Active') {
        throw UspCompleteFailureError(
          summary: 'Router restarted but did not boot the new image (instance '
              '$expectedActiveInstance status=${match.status})',
          failures: const [],
        );
      }
      return match.version == expectedVersion;
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The router's auto-update setting and progress, in one read.
  ///
  /// One `Get` for both because the data plane exposes them side by side, and
  /// because the two questions a caller asks — "may the router update itself" and
  /// "is it updating right now" — are answered by the same three parameters.
  Future<FirmwareAutoUpdateUIModel> fetchAutoUpdate() async {
    try {
      return mapAutoUpdateStatus(await FirmwareAutoUpdate.fetch(_usp));
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Writes the auto-update policy, and **only** the policy.
  ///
  /// `FirmwareAutoUpdate.update()` also takes `fwupPeriodicCheck` and
  /// `updateFirmwareNow`; neither is ever passed. Scheduling is decided against
  /// (REQ-C2) — the data plane can only promise "at the next cron tick", so a UI
  /// that offered a time would be promising something nobody defined — and
  /// `update_firmware_now` is a second flash entry point this app does not use.
  /// Seeing those two parameters unread is the intended state, not an omission.
  ///
  /// [FirmwareAutoUpdatePolicy.unknown] is refused rather than sent: its raw value
  /// is the empty string, which would either clear the parameter or be rejected by
  /// the router, and both are worse than failing at the call site.
  Future<void> setAutoUpdatePolicy(FirmwareAutoUpdatePolicy policy) async {
    if (policy == FirmwareAutoUpdatePolicy.unknown) {
      throw ArgumentError.value(
        policy,
        'policy',
        'has no value to write — read-only, it means the router reported a flag '
            'this build does not define',
      );
    }
    try {
      final result = await FirmwareAutoUpdate.update(
        _usp,
        autoupdateFlags: policy.rawValue,
      );
      switch (UspResultParser.parseSetResult(result)) {
        case UspSuccess():
          break;
        // One parameter, so a "partial" success cannot mean half of the write
        // landed — it means the only write failed while the message did not. Both
        // arms are therefore the same failure to a caller, unlike the
        // multi-parameter writes in `usp_admin_service.dart` where the split
        // carries information.
        case UspPartialSuccess(:final errorSummary, :final failures):
          throw UspCompleteFailureError(
            summary: 'Auto-update policy write failed: $errorSummary',
            failures: failures,
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'Auto-update policy write failed: $errorSummary',
            failures: errors,
          );
      }
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The one place `fwup_state` becomes an app-layer status.
  ///
  /// Keeping it single-sited is the point: the raw domain is `0/1/3/4/5` (`2` is
  /// a mode of `update_firmware_now`, not a state), and a firmware that grows a
  /// sixth value must cost one enum value plus one arm here. Unknown values
  /// therefore map to [FirmwareAutoUpdateStatus.unknown] — never to `idle`, which
  /// would report "nothing is running" during an unrecognised flash — and never
  /// throw.
  ///
  /// **`5` maps to `rebooting`, not to a failure, and that one arm is the whole of
  /// this method's history.** All five values are now measured on real hardware;
  /// see [FirmwareAutoUpdateStatus.rebooting] for the four sources and for where
  /// the `5 = Error` reading came from, since the definition this app generates
  /// from still says so. This mapping deliberately disagrees with
  /// `firmware_auto_update.yaml`, which is the only place in the app that does.
  ///
  /// [FirmwareAutoUpdateUIModel.rawState] carries the value through unparsed so
  /// a diagnostic keeps the number the router sent.
  ///
  /// `autoupdate_flags` is mapped here too rather than in a second method: it
  /// arrives in the same `Get`, so splitting the mapping would mean two reads of
  /// one response.
  static FirmwareAutoUpdateUIModel mapAutoUpdateStatus(FirmwareAutoUpdate raw) {
    final status = switch (raw.fwupState) {
      '0' => FirmwareAutoUpdateStatus.idle,
      '1' => FirmwareAutoUpdateStatus.checking,
      '3' => FirmwareAutoUpdateStatus.downloading,
      '4' => FirmwareAutoUpdateStatus.installing,
      '5' => FirmwareAutoUpdateStatus.rebooting,
      _ => FirmwareAutoUpdateStatus.unknown,
    };
    if (status == FirmwareAutoUpdateStatus.unknown) {
      logger.w('[FirmwareUpdate] unrecognised fwup_state "${raw.fwupState}"');
    }
    final policy = FirmwareAutoUpdatePolicy.fromRaw(raw.autoupdateFlags);
    if (policy == FirmwareAutoUpdatePolicy.unknown) {
      logger.w('[FirmwareUpdate] unrecognised autoupdate_flags '
          '"${raw.autoupdateFlags}"');
    }
    return FirmwareAutoUpdateUIModel(
      status: status,
      // Carried verbatim. `fwup_progress` rests at both 0 and 100 after a check
      // depending on the mode used, so no value of it means "done" — reading it
      // is only valid within the status above.
      progress: int.tryParse(raw.fwupProgress) ?? 0,
      rawState: raw.fwupState,
      policy: policy,
      rawFlags: raw.autoupdateFlags,
    );
  }

  FirmwareImageUIModel _toUIModel(FirmwareImage image) => FirmwareImageUIModel(
        instance: _instanceFromPath(image.instancePath),
        instancePath: image.instancePath,
        alias: image.alias,
        name: image.name,
        version: image.version,
        status: image.status,
        available: image.available,
      );

  int _instanceFromPath(String path) {
    final trimmed =
        path.endsWith('.') ? path.substring(0, path.length - 1) : path;
    final lastDot = trimmed.lastIndexOf('.');
    if (lastDot < 0) return 0;
    return int.tryParse(trimmed.substring(lastDot + 1)) ?? 0;
  }
}
