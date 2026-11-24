import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/models/local_network_feature_state.dart';
import 'package:privacy_gui/page/local_network/models/local_network_settings.dart';
import 'package:privacy_gui/page/local_network/models/local_network_status.dart';
import 'package:privacy_gui/page/local_network/models/local_network_ui_model.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/local_network/services/usp_local_network_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspLocalNetworkProvider = AutoDisposeNotifierProvider<
    UspLocalNetworkNotifier, LocalNetworkFeatureState>(
  UspLocalNetworkNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspLocalNetworkNotifier
    extends AutoDisposeNotifier<LocalNetworkFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<LocalNetworkSettings,
            LocalNetworkStatus, LocalNetworkFeatureState> {
  UspLocalNetworkService get _svc => ref.read(uspLocalNetworkServiceProvider);

  @override
  LocalNetworkFeatureState build() {
    // No SSE listener: a push must not move the page under the user
    // (constitution Article IV Rule 2). lanDataProvider follows the router's
    // pool pushes, and the page reads it on entry.

    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return LocalNetworkFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<(LocalNetworkSettings?, LocalNetworkStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      // Clone data from the shared data provider (read, not watch).
      final data = await ref.read(lanDataProvider.future);
      final lan = data.model;
      final dnsParts = lan.dnsServers.split(',').map((s) => s.trim()).toList();
      final uiModel = LocalNetworkUIModel(
        hostName: lan.hostName,
        ipAddress: lan.ipAddress,
        subnetMask: lan.subnetMask,
        dhcpEnabled: lan.dhcpEnabled,
        minAddress: lan.minAddress,
        maxAddress: lan.maxAddress,
        leaseTimeMinutes: lan.leaseTimeMinutes,
        dnsServer1: dnsParts.isNotEmpty ? dnsParts[0] : '',
        dnsServer2: dnsParts.length > 1 ? dnsParts[1] : '',
        dnsServer3: dnsParts.length > 2 ? dnsParts[2] : '',
      );

      logger.d('[USP][Network][LAN]: Fetched — '
          'ip: ${uiModel.ipAddress}, '
          'dhcp: ${uiModel.dhcpEnabled}, '
          'pool: ${uiModel.minAddress}-${uiModel.maxAddress}');

      return (
        LocalNetworkSettings(model: uiModel),
        LocalNetworkStatus(
          isLoading: false,
          lockedOctetCount: _svc.lockedOctetCount(uiModel.subnetMask),
        ),
      );
    } on ServiceError catch (e) {
      logger.e('[USP][Network][LAN]: Fetch failed', error: e);
      return (
        null,
        LocalNetworkStatus(isLoading: false, error: e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // save — override the mixin's default (performSave -> markAsSaved -> refetch)
  // to special-case a router IP / subnet change, which restarts the LAN and,
  // for an IP change, makes the router unreachable on this origin.
  // ---------------------------------------------------------------------------

  @override
  Future<LocalNetworkFeatureState> save() async {
    // Detect the change BEFORE saving: markAsSaved() below collapses original
    // into current, so this must be read up front. Only an IP address change
    // (not a mask-only change) drops the current connection, so that is the
    // trigger for the redirect + SSE disconnect.
    final ipChanged = state.hasIpAddressChange;
    // Also true for an IP change saved with a mask change: that save takes the
    // IP branch, which returns before the mask branch reads this.
    final maskChanged = state.hasSubnetMaskChange;
    final hostNameChanged = state.hasHostNameChange;

    await performSave();
    markAsSaved();

    if (ipChanged) {
      // Changing the router LAN IP makes it unreachable on this origin
      // (the old address stops answering). Two effects are handled here, both
      // specific to this transition:
      //
      // 1. Drop SSE intentionally. disconnect() sets _intentionalDisconnect,
      //    which stops the reconnect backoff and suppresses onReconnectFailed,
      //    so the app-level recovery flow (2 reconnect failures ->
      //    waitingForRecovery) never fires on top of the LAN IP redirect
      //    dialog.
      // 2. Skip the post-save re-fetch. The SET already succeeded; the device
      //    is now gone from this origin, so fetch(forceRemote: true) would only
      //    time out and surface a spurious error for an operation that actually
      //    succeeded. The redirect dialog is the only valid next step.
      await ref.read(sseManagerProvider)?.disconnect();
      return state;
    }

    // The host name is also the controller's name when nobody has named it
    // (#1751), and that comes through system info into the master node, which
    // this page's LAN read does not refresh. Refresh both, as the router rename
    // does. The order holds without awaiting here: the devices refetch awaits
    // `systemInfoDataProvider.future` (`_readEnrichment`), which after the
    // invalidate is the new read. Not awaited, so the save confirms as before.
    // Done for a mask change too: the SET has stored the host name, and these
    // reads run in the background, so one that meets the LAN restart only
    // fails.
    if (hostNameChanged) {
      ref.invalidate(systemInfoDataProvider);
      unawaited(ref.read(devicesDataProvider.notifier).refetch());
    }

    if (maskChanged) {
      // A mask change makes the router take the LAN down and back up after
      // SetResp, and the pool settles only once it is back (PrivacyGUI#1729,
      // bench 2026-11-02: the LAN went down ~3 s after the Set, the pool
      // settled ~8 s after it). A read inside that window holds the old or a
      // half-converted range, or fails, so it is not made: the page stays on
      // what was sent, which the Set reported stored. A write that restarts
      // what it wrote is not read back in save() (dirty guard guide).
      //
      // The guide's other half, reading back once the router has recovered,
      // is deliberately not done: the app cannot tell when the LAN restart is
      // over. A probe answers before the LAN even goes down, so it would read
      // the half-converted range this branch exists to avoid. Instead the
      // router reports the settled values itself: its pool push (which a mask
      // change always sends, as Pool.{i}.SubnetMask) re-reads
      // lanDataProvider, and the page shows them on its next entry.
      //
      // lanDataProvider is not re-read now either, for the same reason: a read
      // now would hand every page the half-converted range.
      return state;
    }

    // No IP or mask change (e.g. only DHCP fields changed): the LAN keeps
    // running, so re-fetch so the dashboard card updates too.
    ref.invalidate(lanDataProvider);
    return confirmSaved();
  }

  // ---------------------------------------------------------------------------
  // performSave — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );

    try {
      final o = state.settings.original.model;
      final p = state.settings.current.model;

      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.save(original: o, pending: p);
        logger.d('[USP][Network][LAN]: Saved');
      });
    } on ServiceError catch (e) {
      logger.e('[USP][Network][LAN]: Save failed', error: e);
      rethrow;
    } finally {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // revert — override to also clear validation errors
  // ---------------------------------------------------------------------------

  @override
  void revert() {
    state = state.copyWith(
      settings: state.settings.copyWith(current: state.settings.original),
      status: state.status.copyWith(validationErrors: const {}),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Mutation (synchronous — no network call)
  // ---------------------------------------------------------------------------

  /// Update a single setting WITHOUT triggering validation.
  ///
  /// Use this for onChange handlers to avoid TextField unfocus on Web.
  /// Call [validate] separately on unfocus.
  ///
  /// When router IP OR subnet mask changes, locked-prefix octets of pool IPs
  /// are automatically synced so the user doesn't have to retype them.
  void updateSetting(
      LocalNetworkUIModel Function(LocalNetworkUIModel) updater) {
    final current = state.settings.current;
    var newModel = updater(current.model);

    // Apply sensible defaults when DHCP is toggled from disabled → enabled
    if (!current.model.dhcpEnabled && newModel.dhcpEnabled) {
      newModel = _svc.applyDhcpDefaults(newModel);
    }

    // Auto-sync pool prefix when the router IP OR the subnet mask changes.
    // The mask must be included: it determines lockedOctetCount, which the UI
    // uses to lock pool prefix octets read-only. If only the IP triggered the
    // sync, changing the mask (e.g. /16 → /24) would widen the locked range
    // without updating the pool, leaving pool octets that are both out-of-subnet
    // (validation error) AND read-only (uneditable) — a dead end.
    final ipChanged = newModel.ipAddress != current.model.ipAddress;
    final maskChanged = newModel.subnetMask != current.model.subnetMask;
    if ((ipChanged || maskChanged) && newModel.subnetMask.isNotEmpty) {
      final locked = _svc.lockedOctetCount(newModel.subnetMask);
      if (locked > 0) {
        newModel = newModel.copyWith(
          minAddress:
              _svc.syncPrefix(newModel.minAddress, newModel.ipAddress, locked),
          maxAddress:
              _svc.syncPrefix(newModel.maxAddress, newModel.ipAddress, locked),
        );
      }
    }

    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(model: newModel),
      ),
      status: state.status.copyWith(
        lockedOctetCount: _svc.lockedOctetCount(newModel.subnetMask),
      ),
    );
  }

  /// Trigger validation on current settings.
  ///
  /// Call this on TextField unfocus to avoid unfocus issues on Web.
  void validate() {
    final current = state.settings.current.model;
    final errors = _svc.validateAll(current);
    state = state.copyWith(
      status: state.status.copyWith(validationErrors: errors),
    );
  }
}
