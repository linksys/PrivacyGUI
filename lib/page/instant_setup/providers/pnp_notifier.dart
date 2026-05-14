import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Entry point — called once when PnpAdminView mounts.
  ///
  /// 1. Try default password login
  /// 2. If succeeds → check factory default + internet
  /// 3. If fails → show password input
  Future<void> startFlow() async {
    state = state.copyWith(phase: const AdminInitializing());

    try {
      final defaultLoginOk = await _svc.tryDefaultLogin();

      if (defaultLoginOk) {
        final result = await _svc.checkFactoryDefault();
        state = state.copyWith(
          serialNumber: result.serialNumber,
          modelName: result.modelName,
          adminPassword: PnpService.defaultPassword,
        );

        if (result.isFactoryDefault) {
          state = state.copyWith(
            flowMode: PnpFlowMode.unconfigured,
            phase: const AdminCheckingInternet(),
          );
          await _checkInternet();
        } else {
          // Default password works but not factory default —
          // user reset password back to default.
          state = state.copyWith(
            flowMode: PnpFlowMode.unconfigured,
            phase: const AdminUnconfigured(),
          );
        }
      } else {
        state = state.copyWith(
          phase: const AdminAwaitingPassword(),
        );
      }
    } catch (e) {
      logger.e('[PnP] startFlow error: $e');
      state = state.copyWith(
        phase: AdminError(message: '$e'),
      );
    }
  }

  /// User submits password from the password input form.
  Future<void> submitPassword(String password) async {
    state = state.copyWith(phase: const AdminLoggingIn());

    try {
      await _svc.login(password);

      final result = await _svc.checkFactoryDefault();
      state = state.copyWith(
        serialNumber: result.serialNumber,
        modelName: result.modelName,
        adminPassword: password,
        flowMode: result.isFactoryDefault
            ? PnpFlowMode.unconfigured
            : PnpFlowMode.configured,
      );

      state = state.copyWith(phase: const AdminCheckingInternet());
      await _checkInternet();
    } catch (e) {
      logger.w('[PnP] Login failed: $e');
      state = state.copyWith(
        phase: AdminLoginFailed(message: '$e'),
      );
    }
  }

  /// Continue from AdminUnconfigured (user acknowledges factory default).
  Future<void> continueFromUnconfigured() async {
    state = state.copyWith(phase: const AdminCheckingInternet());
    await _checkInternet();
  }

  Future<void> _checkInternet() async {
    try {
      final hasInternet = await _svc.checkInternetConnected();
      if (hasInternet) {
        state = state.copyWith(phase: const AdminInternetConnected());
        await _initWizard();
      } else {
        final ssid = await _svc.fetchCurrentSsid();
        state = state.copyWith(phase: NoInternet(ssid: ssid));
      }
    } catch (e) {
      logger.e('[PnP] Internet check failed: $e');
      state = state.copyWith(phase: const NoInternet());
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

  // ─── Save ────────────────────────────────────────────────

  /// Save WiFi changes (main + guest), then handle reconnect.
  Future<void> saveChanges() async {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;

    state = state.copyWith(phase: const WizardSaving());

    try {
      // Persist credentials BEFORE saving WiFi — if WiFi SSID changes,
      // the connection will drop and we need credentials stored for
      // automatic session restore when reconnected.
      final passwordToUse = state.adminPassword ?? PnpService.defaultPassword;
      await ref.read(authProvider.notifier).persistLocalCredentials(passwordToUse);

      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.saveWifi(phase.wifiConfig);
      });

      // Save serial number for future recognition
      logger.d('[PnP] Saving setup completion, serialNumber=${state.serialNumber}');
      if (state.serialNumber != null) {
        // Step 1: Acknowledge via API (router-authoritative)
        try {
          final bridge = ref.read(uspBridgeClientProvider);
          logger.d('[PnP] Bridge client: ${bridge != null ? "available" : "null"}');
          if (bridge != null) {
            await bridge.acknowledgeSetup();
            logger.i('[PnP] Setup acknowledged via API');
          } else {
            logger.w('[PnP] Bridge client is null, skipping API acknowledge');
          }
        } catch (e) {
          logger.w('[PnP] API acknowledge failed (non-fatal): $e');
        }

        // Step 2: SharedPreferences fallback
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(pPnpConfiguredSN, state.serialNumber!);

        // Step 3: Save selected network
        await ref
            .read(sessionProvider.notifier)
            .saveSelectedNetwork(state.serialNumber!, '');
      }

      if (phase.wifiConfig.isMainDirty) {
        // Main WiFi changed → connection will drop, user must reconnect
        state = state.copyWith(
          phase: WizardNeedsReconnect(
            newSsid: phase.wifiConfig.ssid,
            newPassword: phase.wifiConfig.password,
          ),
        );
      } else {
        // No main WiFi change → skip reconnect, go to firmware check
        state = state.copyWith(phase: const WizardSaved());
        await _checkFirmware(
          ssid: phase.wifiConfig.ssid,
          password: phase.wifiConfig.password,
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
    if (state.phase is WizardNeedsReconnect) {
      final phase = state.phase as WizardNeedsReconnect;
      savedSsid = phase.newSsid;
      savedPassword = phase.newPassword;
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
        await ref.read(uspAuthCoordinatorProvider).restoreSession();

        final sn = await _svc.checkRouterIsBack();
        final expectedSn = state.serialNumber;

        // Strict check: serial number must match if we have one
        if (expectedSn != null && expectedSn.isNotEmpty) {
          if (sn != expectedSn) {
            logger.w('[PnP] Serial number mismatch: expected=$expectedSn, got=$sn');
            continue; // Try next attempt
          }
        }

        logger.i('[PnP] Router reconnected, SN=$sn');
        state = state.copyWith(phase: const WizardSaved());
        await _checkFirmware(ssid: savedSsid, password: savedPassword);
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
      ),
    );
  }

  // ─── Firmware Check ──────────────────────────────────────

  Future<void> _checkFirmware({
    required String ssid,
    required String password,
  }) async {
    state = state.copyWith(phase: const WizardCheckingFirmware());

    // NOTE: Firmware update via USP Operate is a P3 feature.
    // For now, skip directly to WizardWifiReady.
    // TODO: Integrate FirmwareImages.fetch(usp) when firmware Operate is available.

    state = state.copyWith(
      phase: WizardWifiReady(ssid: ssid, password: password),
    );
  }

  // ─── No Internet Flow ───────────────────────────────────

  /// Save ISP settings and re-check internet.
  Future<void> saveIspSettingsAndCheck(PnpIspConfig config) async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.saveIspSettings(config);
      });

      // Wait for WAN interface to come up
      await Future.delayed(const Duration(seconds: 5));

      state = state.copyWith(phase: const AdminCheckingInternet());
      await _checkInternet();
    } catch (e) {
      logger.e('[PnP] ISP save failed: $e');
      state = state.copyWith(
        phase: const NoInternet(),
        errorMessage: '$e',
      );
    }
  }

  /// Retry internet check after modem restart flow.
  Future<void> retryInternetCheck() async {
    state = state.copyWith(phase: const AdminCheckingInternet());
    await _checkInternet();
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
