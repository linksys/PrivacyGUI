import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_status_service.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_internet_settings_service.dart';

/// PnP state machine notifier.
///
/// Uses [Notifier] (not AsyncNotifier) because the flow has discrete
/// phase transitions rather than a single async build().
class PnpNotifier extends Notifier<PnpState> {
  PnpService get _svc => ref.read(pnpServiceProvider);

  @override
  PnpState build() => PnpState.initial();

  // ══════════════════════════════════════════════════════════
  // Admin Phase
  // ══════════════════════════════════════════════════════════

  /// Entry point — called once when PnpEntryView mounts.
  ///
  /// User is already authenticated (login handled by LoginLocalView).
  /// This method fetches device info and checks internet connectivity.
  Future<void> startPostLoginFlow() async {
    state = state.copyWith(phase: const AdminCheckingInternet());

    try {
      final result = await _svc.checkFactoryDefault();
      state = state.copyWith(
        serialNumber: result.serialNumber,
        modelName: result.modelName,
        flowMode: result.isFactoryDefault
            ? PnpFlowMode.unconfigured
            : PnpFlowMode.configured,
      );

      await _checkInternet();
    } on ServiceError catch (e) {
      // Reading device info failed (e.g. USP GET returned empty). This is a
      // read failure, not "no internet" — surface it as such.
      logger.e('[PnP] startPostLoginFlow read failure: $e (code=${e.code})');
      state = state.copyWith(
        phase: AdminReadFailure(code: e.code, detail: '$e'),
      );
    } catch (e) {
      logger.e('[PnP] startPostLoginFlow error: $e');
      state = state.copyWith(
        phase: AdminReadFailure(detail: '$e'),
      );
    }
  }

  Future<void> _checkInternet() async {
    try {
      final hasInternet = await _svc.checkInternetConnected();
      if (hasInternet) {
        state = state.copyWith(phase: const AdminInternetConnected());
        await _initWizard();
      } else {
        final results = await Future.wait([
          _svc.fetchCurrentSsid(),
          _fetchCurrentWanSettings(),
        ]);
        final ssid = results[0] as String?;
        final wanSettings = results[1] as UspInternetSettingsForm?;
        state = state.copyWith(
          phase: NoInternet(ssid: ssid, currentWanSettings: wanSettings),
        );
      }
    } on ServiceError catch (e) {
      // The WAN read threw — we could NOT determine the WAN state (router
      // unreachable / USP GET returned empty). This is distinct from the router
      // confirming "no internet" (which returns false above, no throw), so we
      // must not collapse it into NoInternet.
      logger.e('[PnP] Internet check read failure: $e (code=${e.code})');
      state = state.copyWith(
        phase: AdminReadFailure(code: e.code, detail: '$e'),
      );
    } catch (e) {
      logger.e('[PnP] Internet check unexpected error: $e');
      state = state.copyWith(phase: AdminReadFailure(detail: '$e'));
    }
  }

  Future<UspInternetSettingsForm?> _fetchCurrentWanSettings() async {
    try {
      final service = UspInternetSettingsService(_svc.usp);
      final result = await service.fetchSettings();
      return result.form;
    } catch (e) {
      logger.w('[PnP] Failed to fetch WAN settings for prefill: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════
  // Wizard Phase
  // ══════════════════════════════════════════════════════════

  /// Fetch current WiFi config + mesh nodes and enter WizardConfiguring.
  Future<void> _initWizard() async {
    state = state.copyWith(phase: const WizardInitializing());

    try {
      final results = await Future.wait([
        _svc.fetchWizardData(),
        _svc.fetchMeshTopology(),
      ]);
      final data = results[0] as PnpWizardFetchResult;
      final mesh = results[1] as MeshTopologyInfo;
      state = state.copyWith(
        phase: WizardConfiguring(
          wifiConfig: data.wifiConfig,
          meshNodes: mesh.nodes,
        ),
      );
    } catch (e) {
      logger.e('[PnP] Wizard init failed: $e');
      state = state.copyWith(
        phase: WizardError(message: '$e'),
      );
    }
  }

  // ─── Form Updates ────────────────────────────────────────

  void updateWifiSsid(String ssid) {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;
    state = state.copyWith(
      phase: WizardConfiguring(
        wifiConfig: phase.wifiConfig.copyWith(ssid: ssid),
        meshNodes: phase.meshNodes,
      ),
    );
  }

  void updateWifiPassword(String password) {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;
    state = state.copyWith(
      phase: WizardConfiguring(
        wifiConfig: phase.wifiConfig.copyWith(password: password),
        meshNodes: phase.meshNodes,
      ),
    );
  }

  void updateGuestEnabled(bool enabled) {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;
    state = state.copyWith(
      phase: WizardConfiguring(
        wifiConfig: phase.wifiConfig.copyWith(guestEnabled: enabled),
        meshNodes: phase.meshNodes,
      ),
    );
  }

  void updateGuestSsid(String ssid) {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;
    state = state.copyWith(
      phase: WizardConfiguring(
        wifiConfig: phase.wifiConfig.copyWith(guestSsid: ssid),
        meshNodes: phase.meshNodes,
      ),
    );
  }

  void updateGuestPassword(String password) {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;
    state = state.copyWith(
      phase: WizardConfiguring(
        wifiConfig: phase.wifiConfig.copyWith(guestPassword: password),
        meshNodes: phase.meshNodes,
      ),
    );
  }

  // ─── Split Mode Updates ──────────────────────────────────

  /// Update a specific band's SSID in split mode (main WiFi).
  void updateMainBandSsid(String ssidInstancePath, String ssid) {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;
    state = state.copyWith(
      phase: WizardConfiguring(
        wifiConfig:
            phase.wifiConfig.updateMainBand(ssidInstancePath, ssid: ssid),
        meshNodes: phase.meshNodes,
      ),
    );
  }

  /// Update a specific band's password in split mode (main WiFi).
  void updateMainBandPassword(String ssidInstancePath, String password) {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;
    state = state.copyWith(
      phase: WizardConfiguring(
        wifiConfig: phase.wifiConfig
            .updateMainBand(ssidInstancePath, password: password),
        meshNodes: phase.meshNodes,
      ),
    );
  }

  /// Update a specific band's SSID in split mode (guest WiFi).
  void updateGuestBandSsid(String ssidInstancePath, String ssid) {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;
    state = state.copyWith(
      phase: WizardConfiguring(
        wifiConfig:
            phase.wifiConfig.updateGuestBand(ssidInstancePath, ssid: ssid),
        meshNodes: phase.meshNodes,
      ),
    );
  }

  /// Update a specific band's password in split mode (guest WiFi).
  void updateGuestBandPassword(String ssidInstancePath, String password) {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;
    state = state.copyWith(
      phase: WizardConfiguring(
        wifiConfig: phase.wifiConfig
            .updateGuestBand(ssidInstancePath, password: password),
        meshNodes: phase.meshNodes,
      ),
    );
  }

  // ─── Save ────────────────────────────────────────────────

  /// Save WiFi changes (main + guest), then handle reconnect.
  Future<void> saveChanges() async {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;

    state = state.copyWith(phase: const WizardSaving());

    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.saveWifi(phase.wifiConfig);
      });

      // Acknowledge PnP completion and save serial number.
      // NOTE: the same acknowledge + saveSelectedNetwork pair lives in
      // bypassToDashboard(), but there errors are swallowed; here they
      // propagate to the catch below so the user stays on the form to retry.
      logger.d(
          '[PnP] Saving setup completion, serialNumber=${state.serialNumber}');
      if (state.serialNumber != null) {
        // Acknowledge via PnpStatusService (SharedPreferences now, TR-181 future)
        await ref
            .read(pnpStatusServiceProvider)
            .acknowledge(state.serialNumber!);

        // Save selected network for session management
        await ref
            .read(sessionProvider.notifier)
            .saveSelectedNetwork(state.serialNumber!, '');
      }

      if (phase.wifiConfig.isMainDirty) {
        // Main WiFi changed → connection will drop, user must reconnect
        state = state.copyWith(
          phase: WizardNeedsReconnect(
            newSsid: phase.wifiConfig.reconnectSsid,
            newPassword: phase.wifiConfig.reconnectPassword,
            wifiConfig: phase.wifiConfig,
          ),
        );
      } else {
        // No main WiFi change → skip reconnect, go to firmware check
        state = state.copyWith(phase: const WizardSaved());
        await _checkFirmware(
          ssid: phase.wifiConfig.reconnectSsid,
          password: phase.wifiConfig.reconnectPassword,
          wifiConfig: phase.wifiConfig,
        );
      }
    } catch (e) {
      logger.e('[PnP] Save failed: $e');
      state = state.copyWith(
        phase: WizardConfiguring(
          wifiConfig: phase.wifiConfig,
          meshNodes: phase.meshNodes,
        ),
        errorMessage: '$e',
      );
    }
  }

  // ─── Reconnection ────────────────────────────────────────

  /// Poll router to check if it's back after WiFi SSID change.
  /// Uses exponential backoff: 2s, 4s, 8s, 16s, 32s (5 attempts).
  Future<void> testReconnect() async {
    const maxAttempts = 5;
    String savedSsid = '';
    String savedPassword = '';
    PnpWifiConfig? savedWifiConfig;
    if (state.phase is WizardNeedsReconnect) {
      final phase = state.phase as WizardNeedsReconnect;
      savedSsid = phase.newSsid;
      savedPassword = phase.newPassword;
      savedWifiConfig = phase.wifiConfig;
    }

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      state = state.copyWith(
        phase: WizardTestingReconnect(
          attemptCount: attempt,
          maxAttempts: maxAttempts,
        ),
      );

      final delaySeconds = 1 << attempt; // 2, 4, 8, 16, 32
      await Future.delayed(Duration(seconds: delaySeconds));

      try {
        // Re-login (WASM state lost during WiFi change)
        await ref.read(uspAuthCoordinatorProvider).restoreSession(
              isRecovering: true,
            );

        final sn = await _svc.checkRouterIsBack();
        final expectedSn = state.serialNumber;

        // Strict check: serial number must match if we have one
        if (expectedSn != null && expectedSn.isNotEmpty) {
          if (sn != expectedSn) {
            logger.w(
                '[PnP] Serial number mismatch: expected=$expectedSn, got=$sn');
            continue; // Try next attempt
          }
        }

        logger.i('[PnP] Router reconnected, SN=$sn');
        state = state.copyWith(phase: const WizardSaved());
        await _checkFirmware(
          ssid: savedSsid,
          password: savedPassword,
          wifiConfig: savedWifiConfig,
        );
        return;
      } catch (e) {
        logger.d('[PnP] Reconnect attempt $attempt/$maxAttempts failed: $e');
      }
    }

    // All attempts exhausted
    state = state.copyWith(
      phase: WizardNeedsReconnect(
        newSsid: savedSsid,
        newPassword: savedPassword,
        wifiConfig: savedWifiConfig,
      ),
    );
  }

  // ─── Firmware Stage ──────────────────────────────────────

  /// Offer the router a newer firmware before setup finishes, and finish setup
  /// either way.
  ///
  /// **A flow stage, not a form step (REQ-B0).** It runs after `saveWifi` has been
  /// committed — from `saveChanges()` when the main WiFi did not change, and from
  /// [testReconnect] when it did — so `_buildStepperForm`'s step count is untouched
  /// by any of this. A user who reaches here has a configured router whatever
  /// happens next, which is what lets every failure below end in
  /// [WizardWifiReady].
  ///
  /// **Every exit is [WizardWifiReady] (REQ-B3).** A read that throws, a router
  /// with no `ota` row, a check that finds nothing, a fifteen-second wait with no
  /// answer, an install that is refused — all of them log and finish setup. The
  /// firmware update is the bonus; a configured network is the requirement.
  ///
  /// **The reboot belongs to the recovery framework, and only to it (REQ-B5).**
  /// PnP has its own reconnect — [testReconnect], with exponential backoff and
  /// `uspAuthCoordinator.restoreSession` — and it is **not** involved here. The two
  /// are sequential by construction: [testReconnect] has already returned before
  /// this method is called, and `saveChanges()`'s other arm never enters it. So the
  /// flash's reboot is waited out by `enterRecoveryWaiting()` +
  /// [appConnectionStateProvider], which is the path that also parks the SSE
  /// channel and checks the serial fingerprint on the way back. Two reconnect
  /// loops on one reboot would race for the same WASM session; there is exactly
  /// one in flight, and `pnp_notifier_test.dart` asserts it by counting calls on
  /// the other one.
  ///
  /// **No `verify()`, deliberately.** The dashboard's firmware page ends a flash by
  /// confirming the bank flip and reporting a failure card if it does not add up.
  /// PnP has nowhere to put that: its next screen is the WiFi credentials, and a
  /// verification that failed for a benign reason — a slow TR-181 table, a router
  /// that published no `Version` — would paint "Update Failed" over a setup that
  /// worked. Reporting on an update belongs to the page that exists for it.
  Future<void> _checkFirmware({
    required String ssid,
    required String password,
    PnpWifiConfig? wifiConfig,
  }) async {
    final ready = WizardWifiReady.fromWifiConfig(
      ssid: ssid,
      password: password,
      wifiConfig: wifiConfig,
    );
    // REQ-B4 is satisfied by `ready` itself outliving the reboot, and it is built
    // here — before the stage — for the reason a persisted copy used to be written
    // here: after the flash is dispatched there may be no session left to build it
    // from. What the router reboot cannot touch is this object: it is a router
    // restart, not a page reload, so the container and `pnpProvider` (not
    // `autoDispose`) are still the same ones. Verified on hardware 2026-09-16 —
    // `..15 → ..16` from PnP, and the completion screen showed the SSID and
    // passphrase that had just been configured.
    state = state.copyWith(phase: const WizardCheckingFirmware());

    // Everything from here to the `finally` is inside the try, not just
    // `_runFirmwareStage`. REQ-B3's acceptance criterion is that setup completes
    // whatever the router does, and a narrower try only covers the throw the
    // requirement happens to name: with the `ref.listen`, the `ref.read` and the
    // cleanup outside it, a throw from any of those escapes into the caller — where
    // `saveChanges()`'s catch reverts to the form with an error banner, and
    // `testReconnect()`'s catch treats it as a failed attempt and runs the whole
    // stage again, dispatching a second install at a router already flashing. So the
    // landing is set in the `finally` and there is exactly one way out of this
    // method.
    ProviderSubscription<FirmwareUpdateState>? keepAlive;
    try {
      // `firmwareUpdateNotifierProvider` is `autoDispose` and `ref.read` registers
      // no dependency, so between two awaits here the notifier holding the phase
      // this stage is driving can be disposed and rebuilt at `idle` — losing the
      // progress mid-flash, with nothing watching it yet because the view only
      // starts watching when the phase below is published. A listener whose
      // callback does nothing is the keep-alive: what it is for is the
      // subscription, not the notifications.
      keepAlive = ref.listen(firmwareUpdateNotifierProvider, (_, __) {});
      final firmware = ref.read(firmwareUpdateNotifierProvider.notifier);
      try {
        await _runFirmwareStage(firmware);
      } finally {
        // The shared notifier must not be left carrying this stage's outcome.
        // `_firmwareExitGuard` in `route_usp_dashboard.dart` silently vetoes the
        // back arrow on `isUpdating`, so a phase left set here would follow the
        // user to the firmware page and trap them there — and a `failed` left set
        // would show them "Update Failed" for an attempt PnP deliberately never
        // reported, with a Try Again that re-dispatches it.
        //
        // **Unconditional, not `if (isUpdating)`.** That flag excludes `failed`
        // and `done` by definition, which are two of the three states this stage
        // can leave behind; and sampling it once, here, samples it at the one
        // moment a check abandoned by `.timeout()` has not resolved yet. `cancel()`
        // is idempotent — it resets to a clean state keeping the banks, and every
        // operation clears its own `_cancelRequested` on entry, so this cannot
        // poison a later update the user starts themselves.
        firmware.cancel();
      }
    } catch (e) {
      // One `catch`, not `on ServiceError`, because `UspMutationLock` throws a bare
      // `TimeoutException` and `.timeout()` below throws another — neither is a
      // `ServiceError`, and all of them mean the same thing here.
      logger.w('[PnP] the firmware stage did not complete ($e) — '
          'finishing setup without an update');
    } finally {
      keepAlive?.close();
      // REQ-B3, structurally: the credentials screen is the landing for every
      // outcome — no update, no internet, a timeout, a throw, a flash that worked.
      //
      // The value just computed, **not** a read-back of the store. Reading back
      // would put the durable copy on the live path, which is why it was written
      // that way first — but `store()` swallows its failures by design and so does
      // `clear()`, so a snapshot from an earlier setup run can still be in the
      // keystore when this run's write silently fails. The read would then find it,
      // be non-null, and render a *previous* network's SSID and passphrase into
      // this screen's QR code. The in-memory value is the authority; the stored one
      // exists for a restore after a page reload.
      state = state.copyWith(phase: ready);
    }
  }

  /// The four branches REQ-B1 names, in the order the router answers them.
  ///
  /// Returns normally for all three "nothing to do" outcomes; the caller finishes
  /// setup on every path including a throw.
  ///
  /// **The check is dispatched rather than `Available` being read.** Branch 3 in the
  /// requirement is `Available=false`, and read on its own that would make this
  /// feature dead on the router it is for: the router reports `Status=NoImage` with
  /// `Available=false` both when a check has just found nothing *and* when no check
  /// has ever run, which is the state of a factory-fresh router at first
  /// connection. So `checkForUpdate()` is what makes the field mean anything, and it
  /// already answers all four branches — no `ota` row and "an update is already
  /// running" both come back as `notChecked`, which is why they share an arm here.
  Future<void> _runFirmwareStage(FirmwareUpdateNotifier firmware) async {
    // One deadline over the whole stage up to the dispatch, not per request: the
    // image-table read, the Operate and the check's own polling are all inside it.
    final check = await firmware
        .checkForUpdate()
        .timeout(ref.read(pnpFirmwareCheckDeadlineProvider));

    if (!check.isUpdateAvailable) {
      // Branches 2 and 3. Logged at info and **not** recorded as an error: a
      // router with no fwup stack is an OEM build, which is a permanent property
      // of the device rather than a fault, and "checked, found nothing" is the
      // ordinary answer.
      logger.i('[PnP] no firmware update to install '
          '(${check.verdict.name}) — finishing setup');
      return;
    }

    // `hasError` before `valueOrNull`: Riverpod attaches the previous value to an
    // `AsyncError` whether asked to or not, so reading the value first would
    // dispatch an install against a row from a read that has since failed.
    final banks = ref.read(firmwareBanksDataProvider);
    final ota = banks.hasError ? null : banks.valueOrNull?.otaInstance;
    if (ota == null) {
      // Only reachable if the row disappeared between the check and this read —
      // `checkForUpdate()` could not have returned `updateAvailable` without it.
      logger.w('[PnP] an update was found but the ota row is no longer '
          'readable — finishing setup');
      return;
    }

    // Branch 4, and the one that locks the flow (REQ-B2). Published before the
    // dispatch so the progress card is on screen for the seconds the router spends
    // deciding, and so the route guard is closed before anything is committed.
    state = state.copyWith(
      phase: WizardUpdatingFirmware(version: check.version),
    );

    final result = await firmware.triggerRouterOtaInstall(
      otaInstance: ota.instance,
    );
    if (!result.isFlashing) {
      // `flashing` is the only verdict with a reboot behind it. `idle` means mode 2
      // checked again and found nothing — it checks before it downloads, so an
      // accepted dispatch can still come back empty — and the failed verdicts have
      // already failed the phase.
      logger.i('[PnP] the router did not start an install '
          '(${result.verdict.name}) — finishing setup');
      return;
    }

    await _awaitFirmwareReboot(firmware);
  }

  /// Wait out the reboot the flash causes, through the recovery framework.
  ///
  /// No recovery dialog, unlike the firmware page: PnP is already a full-screen
  /// flow, and REQ-B0 asks for the firmware stage to be one too. A modal over it
  /// would put a second "waiting for the router" surface on top of the one the
  /// wizard is already showing, with its own dismiss.
  ///
  /// Ends on any state other than `waitingForRecovery`, not only on
  /// `authenticated`: the probe can also end the session (a serial mismatch means
  /// this is a different router), and there is nothing to wait for after that.
  Future<void> _awaitFirmwareReboot(FirmwareUpdateNotifier firmware) async {
    firmware.enterRecoveryWaiting();

    // `enterWaiting` can decline — the proximity strategy decides whether this
    // trigger needs recovery on this surface — and then the state never leaves
    // `authenticated`, so a listener waiting for it to change would wait out the
    // whole deadline for a reboot nobody is watching.
    if (ref.read(appConnectionStateProvider) !=
        AppConnectionState.waitingForRecovery) {
      logger.i('[PnP] recovery was not entered for the firmware reboot — '
          'finishing setup');
      return;
    }

    final settled = Completer<void>();
    final sub = ref.listen<AppConnectionState>(
      appConnectionStateProvider,
      (_, next) {
        if (next != AppConnectionState.waitingForRecovery &&
            !settled.isCompleted) {
          settled.complete();
        }
      },
    );
    try {
      await settled.future.timeout(ref.read(pnpFirmwareRebootDeadlineProvider));
      logger.i('[PnP] the router came back after the firmware update '
          '(${ref.read(appConnectionStateProvider).name})');
    } on TimeoutException {
      // The connection state is left in `waitingForRecovery` on purpose: the probe
      // loop is still the thing that will notice the router returning, and forcing
      // it to `authenticated` here would claim a session this code has not seen.
      // What PnP does is stop waiting — the credentials are what a user with an
      // unreachable router needs, and they are on the next screen.
      logger.w('[PnP] the router did not come back within '
          '${ref.read(pnpFirmwareRebootDeadlineProvider).inMinutes} minutes — '
          'showing the WiFi credentials anyway');
    } finally {
      sub.close();
    }
  }

  // ─── No Internet Flow ───────────────────────────────────

  /// Retry internet check after modem restart flow.
  Future<void> retryInternetCheck() async {
    state = state.copyWith(phase: const AdminCheckingInternet());
    await _checkInternet();
  }

  /// Bypass the no-internet page and let the user into the dashboard.
  ///
  /// Ports the dev-1.3.0 "Log into router" escape hatch. Unlike 1.3.0 — which
  /// routed into a trimmed-down setup wizard — the USP flow goes straight to the
  /// dashboard (the USP wizard is phase-driven and has no forceLogin branch, and
  /// the dashboard does not depend on internet being up).
  ///
  /// We acknowledge PnP completion here so a later redirect through `/` does not
  /// bounce the user back into PnP (`router_provider._prepare` re-checks
  /// `needsPnp`; without acknowledging, a full-page reload would kick them out
  /// again). This mirrors 1.3.0, where a configured router's save already sends
  /// `SetUserAcknowledgedAutoConfig`. Acknowledge is fire-and-forget and does not
  /// need WAN, so it succeeds while the router is offline.
  ///
  /// The caller performs the actual navigation once this completes.
  ///
  /// This never throws: an escape hatch must always let the user through. A
  /// failed acknowledge / save is logged and swallowed — at worst the router
  /// stays un-acknowledged and PnP is re-offered on the next `/` redirect, which
  /// is strictly better than trapping the user on the no-internet page.
  Future<void> bypassToDashboard() async {
    final sn = state.serialNumber;
    if (sn == null || sn.isEmpty) {
      logger
          .w('[PnP] bypassToDashboard: no serial number, skipping acknowledge');
      return;
    }
    try {
      // Same acknowledge + saveSelectedNetwork pair as saveChanges(), but the
      // error handling is intentionally the opposite: saveChanges() lets errors
      // propagate (a failed WiFi save should keep the user on the form to
      // retry), whereas here we swallow them (an escape hatch must never block
      // navigation). Keep the two in sync when changing this pair.
      await ref.read(pnpStatusServiceProvider).acknowledge(sn);
      // Persist selected network for session management, matching saveChanges().
      await ref.read(sessionProvider.notifier).saveSelectedNetwork(sn, '');
      logger.i('[PnP] bypassToDashboard: acknowledged, entering dashboard');
    } catch (e) {
      // Do not block navigation — see method doc.
      logger
          .w('[PnP] bypassToDashboard: acknowledge/save failed (ignored): $e');
    }
  }

  // ─── Modem Restart Flow ───────────────────────────────────

  /// Start the modem restart countdown (150s).
  /// Called when user confirms they plugged the modem back in.
  Future<void> startModemRestartCountdown() async {
    const total = 150;
    for (int s = total; s >= 0; s--) {
      // Check if user navigated away (phase changed externally)
      if (state.phase is! ModemRestartCountdown &&
          state.phase is! NoInternet &&
          s < total) {
        return;
      }
      state = state.copyWith(
        phase: ModemRestartCountdown(remainingSeconds: s, totalSeconds: total),
      );
      if (s > 0) await Future.delayed(const Duration(seconds: 1));
    }
    await _modemRestartCheckInternet();
  }

  /// Poll internet after modem restart (up to 30 attempts, 5s apart).
  Future<void> _modemRestartCheckInternet() async {
    const maxAttempts = 30;
    for (int i = 1; i <= maxAttempts; i++) {
      state = state.copyWith(
        phase: ModemRestartCheckingInternet(
          attemptCount: i,
          maxAttempts: maxAttempts,
        ),
      );
      await Future.delayed(const Duration(seconds: 5));
      try {
        final hasInternet = await _svc.checkInternetConnected();
        if (hasInternet) {
          state = state.copyWith(phase: const AdminInternetConnected());
          await _initWizard();
          return;
        }
      } catch (_) {}
    }
    state = state.copyWith(phase: const NoInternet());
  }

  // ─── ISP Save with Progress ───────────────────────────────

  /// Save ISP settings with multi-step progress indication.
  Future<void> saveIspWithProgress(PnpIspConfig config) async {
    try {
      state = state.copyWith(
        phase: const IspSaving(step: IspSaveStep.saving),
      );
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.saveIspSettings(config);
      });

      state = state.copyWith(
        phase: const IspSaving(step: IspSaveStep.checkingSettings),
      );
      await Future.delayed(const Duration(seconds: 3));

      state = state.copyWith(
        phase: const IspSaving(step: IspSaveStep.checkingInternet),
      );
      await Future.delayed(const Duration(seconds: 5));
      await _checkInternet();
    } catch (e) {
      logger.e('[PnP] ISP save failed: $e');
      state = state.copyWith(
        phase: const NoInternet(),
        errorMessage: '$e',
      );
    }
  }

  // ─── Demo ─────────────────────────────────────────────────

  /// Demo only: directly set phase for UI testing.
  void setDemoPhase(PnpPhase phase) {
    state = state.copyWith(phase: phase);
  }
}
