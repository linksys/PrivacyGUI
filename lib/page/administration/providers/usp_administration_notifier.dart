import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/administration/models/administration_feature_state.dart';
import 'package:privacy_gui/page/administration/models/administration_settings.dart';
import 'package:privacy_gui/page/administration/models/administration_status.dart';
import 'package:privacy_gui/page/administration/services/usp_administration_service.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspAdministrationProvider = AutoDisposeNotifierProvider<
    UspAdministrationNotifier, AdministrationFeatureState>(
  UspAdministrationNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// L2 working copy for Advanced Settings → Administration (#1660, #1694, #1696).
///
/// Type A form: the switches are buffered and written by Save; the route
/// passes this notifier as its `preservableProvider`, which is the dirty guard.
class UspAdministrationNotifier
    extends AutoDisposeNotifier<AdministrationFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<AdministrationSettings,
            AdministrationStatus, AdministrationFeatureState> {
  UspAdministrationService get _svc =>
      ref.read(uspAdministrationServiceProvider);

  @override
  AdministrationFeatureState build() {
    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return AdministrationFeatureState.initial();
  }

  @override
  Future<(AdministrationSettings?, AdministrationStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final settings = await _svc.fetch();
      logger.d('[USP][Administration]: Fetched — '
          'upnpEnabled=${settings.upnpEnabled}, '
          'sipAlgEnabled=${settings.sipAlgEnabled}, '
          'managementWifiEnabled=${settings.managementWifiEnabled}');
      return (settings, const AdministrationStatus());
    } on ServiceError catch (e) {
      logger.e('[USP][Administration]: Fetch failed', error: e);
      return (null, AdministrationStatus(error: e));
    }
  }

  @override
  Future<AdministrationFeatureState> save() async {
    state = state.copyWith(status: state.status.copyWith(isSaving: true));
    try {
      return await super.save();
    } on SavedButUnconfirmedError {
      // The Set landed; only the read-back failed, and the mixin has already
      // left the page on what was written. Not a failed save: nothing to
      // re-read here, and nothing to log as one (#1212).
      rethrow;
    } on ServiceError catch (e) {
      logger.e('[USP][Administration]: Save failed', error: e);
      await _rereadAfterFailure();
      rethrow;
    } finally {
      state = state.copyWith(status: state.status.copyWith(isSaving: false));
    }
  }

  /// Writes each switch that differs from what was read, and only those.
  ///
  /// UPnP, SIP ALG and the management rule are owned by different USP
  /// services, so they are separate Sets, not one combined Set; and SIP ALG's
  /// alone takes ~9 s, which a UPnP save should not wait for. They run in order
  /// under one lock, whose 30 s window fits all three. A failure stops the
  /// rest, and `save()` re-reads the device so the page shows what landed.
  @override
  Future<void> performSave() async {
    final original = state.settings.original;
    final current = state.settings.current;
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        if (current.upnpEnabled != original.upnpEnabled) {
          await _svc.setUpnpEnabled(current.upnpEnabled);
        }
        if (current.sipAlgEnabled != original.sipAlgEnabled) {
          await _svc.setSipAlgEnabled(current.sipAlgEnabled);
        }
        final managementWifi = current.managementWifiEnabled;
        if (managementWifi != null &&
            managementWifi != original.managementWifiEnabled) {
          await _svc.setManagementWifiEnabled(managementWifi);
          // The rule is one of Device.Firewall.Chain.1's, which the Firewall
          // card and the Statistics rule counts read through this provider.
          ref.invalidate(firewallDataProvider);
        }
      });
    } on TimeoutException catch (e) {
      // The lock's own window, not a USP error, so the service never maps it.
      // As a ServiceError it reaches save()'s re-read and is localized as a
      // timeout; left bare it skipped both. Same fold as
      // `firmware_auto_update_data_provider.dart`.
      throw TimeoutError(
        detail: 'the Administration write was not answered '
            '(${e.message ?? '30s'})',
      );
    }
    logger.d('[USP][Administration]: Saved — '
        'upnpEnabled=${current.upnpEnabled}, '
        'sipAlgEnabled=${current.sipAlgEnabled}, '
        'managementWifiEnabled=${current.managementWifiEnabled}');
  }

  /// After a refused or unanswered Set, show what the device holds rather than
  /// the value that was not written, and leave nothing pending.
  ///
  /// If that read fails too, the edit is kept: nobody knows what the router
  /// holds, and the user can press Save again. The Set's error is the one the
  /// caller reports either way.
  Future<void> _rereadAfterFailure() async {
    try {
      final now = await _svc.fetch();
      state = state.copyWith(
        settings: Preservable(original: now, current: now),
      );
    } on ServiceError catch (e) {
      logger.w(
          '[USP][Administration]: Re-read after a failed save also '
          'failed',
          error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // UI Mutation (synchronous — buffers, no network call)
  // ---------------------------------------------------------------------------

  /// Toggle UPnP. Updates [settings.current] only; save() writes it.
  void setUpnpEnabled(bool enabled) {
    state = state.copyWith(
      settings: state.settings
          .update(state.settings.current.copyWith(upnpEnabled: enabled)),
    );
  }

  /// Toggle SIP ALG. Updates [settings.current] only; save() writes it.
  void setSipAlgEnabled(bool enabled) {
    state = state.copyWith(
      settings: state.settings
          .update(state.settings.current.copyWith(sipAlgEnabled: enabled)),
    );
  }

  /// Toggle management over Wi-Fi. Updates [settings.current] only; save()
  /// writes it. The view asks before a save that turns it off.
  void setManagementWifiEnabled(bool enabled) {
    state = state.copyWith(
      settings: state.settings.update(
          state.settings.current.copyWith(managementWifiEnabled: enabled)),
    );
  }
}
