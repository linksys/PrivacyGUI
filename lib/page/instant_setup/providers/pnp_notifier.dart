import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
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
        state = state.copyWith(phase: const NoInternet());
      }
    } catch (e) {
      logger.e('[PnP] Internet check failed: $e');
      state = state.copyWith(phase: const NoInternet());
    }
  }

  // ══════════════════════════════════════════════════════════
  // Wizard Phase
  // ══════════════════════════════════════════════════════════

  /// Fetch current WiFi config and enter WizardConfiguring.
  Future<void> _initWizard() async {
    state = state.copyWith(phase: const WizardInitializing());

    try {
      final data = await _svc.fetchWizardData();
      state = state.copyWith(
        phase: WizardConfiguring(wifiConfig: data.wifiConfig),
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
      ),
    );
  }

  void updateWifiPassword(String password) {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;
    state = state.copyWith(
      phase: WizardConfiguring(
        wifiConfig: phase.wifiConfig.copyWith(password: password),
      ),
    );
  }

  void updateGuestEnabled(bool enabled) {
    final phase = state.phase;
    if (phase is! WizardConfiguring) return;
    state = state.copyWith(
      phase: WizardConfiguring(
        wifiConfig: phase.wifiConfig.copyWith(guestEnabled: enabled),
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

      // Persist credentials via AuthNotifier (use default password for now;
      // admin password change deferred until FW provides factory password API).
      await ref
          .read(authProvider.notifier)
          .localLogin(PnpService.defaultPassword);

      // Save serial number for future recognition
      if (state.serialNumber != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(pPnpConfiguredSN, state.serialNumber!);
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
        phase: WizardConfiguring(wifiConfig: phase.wifiConfig),
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
        if (sn == state.serialNumber || state.serialNumber == null) {
          state = state.copyWith(phase: const WizardSaved());
          await _checkFirmware(ssid: savedSsid, password: savedPassword);
          return;
        }
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
}
