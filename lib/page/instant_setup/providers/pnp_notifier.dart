import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
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

  // ─── Firmware Check ──────────────────────────────────────

  Future<void> _checkFirmware({
    required String ssid,
    required String password,
    PnpWifiConfig? wifiConfig,
  }) async {
    state = state.copyWith(phase: const WizardCheckingFirmware());

    // NOTE: Firmware update via USP Operate is a P3 feature.
    // For now, skip directly to WizardWifiReady.
    // TODO: Integrate FirmwareImages.fetch(usp) when firmware Operate is available.

    state = state.copyWith(
      phase: WizardWifiReady(
        ssid: ssid,
        password: password,
        wifiConfig: wifiConfig,
      ),
    );
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
