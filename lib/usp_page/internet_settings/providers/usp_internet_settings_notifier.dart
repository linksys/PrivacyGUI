import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_contract.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/usp_page/internet_settings/services/usp_internet_settings_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Main provider for the USP Internet Settings page.
final uspInternetSettingsProvider = AutoDisposeNotifierProvider<
    UspInternetSettingsNotifier, InternetSettingsFeatureState>(
  UspInternetSettingsNotifier.new,
);

/// Exposes the notifier as a [PreservableContract] for [LinksysRoute]
/// dirty-check integration.
final preservableUspInternetSettingsProvider = AutoDisposeProvider<
    PreservableContract<InternetSettingsSettings, InternetSettingsStatus>>(
  (ref) => ref.watch(uspInternetSettingsProvider.notifier),
);

/// Service provider — stateless, created from the current UspService.
final uspInternetSettingsServiceProvider =
    Provider.autoDispose<UspInternetSettingsService>((ref) {
  final usp = ref.watch(uspServiceProvider);
  if (usp == null) throw StateError('USP service not available');
  return UspInternetSettingsService(usp);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspInternetSettingsNotifier
    extends AutoDisposeNotifier<InternetSettingsFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<InternetSettingsSettings,
            InternetSettingsStatus, InternetSettingsFeatureState> {
  @override
  InternetSettingsFeatureState build() {
    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return InternetSettingsFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<(InternetSettingsSettings?, InternetSettingsStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final usp = ref.read(uspServiceProvider);
      if (usp == null) throw StateError('USP service not available');

      // Session restore on page reload (WASM state may be lost)
      if (!usp.isAuthenticated) {
        await ref.read(uspAuthCoordinatorProvider).restoreSession();
        if (!usp.isAuthenticated) {
          throw StateError('USP not authenticated after restore attempt');
        }
      }

      final service = ref.read(uspInternetSettingsServiceProvider);
      final result = await service.fetchSettings();

      logger.d('[USP][Network][WAN] Fetched — '
          'raw addressingType: "${result.debugAddressingType}", '
          'bridgeEnabled: ${result.debugBridgeEnabled}, '
          'detected type: ${result.form.connectionType.name}, '
          'mtu: ${result.debugMtu}, ipv6: ${result.debugIpv6Enabled}');

      return (
        InternetSettingsSettings(form: result.form),
        InternetSettingsStatus(
          isLoading: false,
          readOnlyInfo: result.readOnlyInfo,
        ),
      );
    } catch (e) {
      logger.e('[USP][Network][WAN] Fetch failed', error: e);
      return (
        null,
        InternetSettingsStatus(isLoading: false, errorMessage: '$e'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // performSave — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true, activeMutation: 'save'),
    );

    try {
      final service = ref.read(uspInternetSettingsServiceProvider);

      await ref.read(uspMutationLockProvider).withLock(() async {
        await service.saveAll(state.original, state.edited);
        logger.d('[USP][Network][WAN] Save complete');
      });

      // After save, exit edit mode (status will be updated by re-fetch)
      state = state.copyWith(
        status: state.status.copyWith(
          isEditing: false,
          clearActiveMutation: true,
        ),
      );
    } catch (e) {
      logger.e('[USP][Network][WAN] Save failed', error: e);
      rethrow;
    } finally {
      state = state.copyWith(
        status: state.status.copyWith(
          isSaving: false,
          clearActiveMutation: true,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Edit mode
  // ---------------------------------------------------------------------------

  void enterEditMode() {
    state = state.copyWith(
      status: state.status.copyWith(isEditing: true),
    );
  }

  void exitEditMode() {
    // Revert form to original + exit edit mode
    state = state.copyWith(
      settings: state.settings.copyWith(current: state.settings.original),
      status: state.status.copyWith(isEditing: false),
    );
  }

  // ---------------------------------------------------------------------------
  // revert — override to also clear isEditing
  // ---------------------------------------------------------------------------

  @override
  void revert() {
    exitEditMode();
  }

  // ---------------------------------------------------------------------------
  // Form field updates
  // ---------------------------------------------------------------------------

  /// Generic field updater — takes a function that returns a modified form.
  void updateField(
      UspInternetSettingsForm Function(UspInternetSettingsForm) updater) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(form: updater(current.form)),
      ),
    );
  }

  /// Update connection type with appropriate field resets.
  void updateConnectionType(UspWanConnectionType type) {
    final current = state.settings.current;
    var form = current.form.copyWith(connectionType: type);

    // Reset type-specific fields when switching away
    if (type == UspWanConnectionType.bridge) {
      form = form.copyWith(mtu: 0);
    }

    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(form: form),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DHCP Renewal (separate from form editing)
  // ---------------------------------------------------------------------------

  Future<void> renewDhcpLease() async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      state = state.copyWith(
        status: state.status.copyWith(activeMutation: 'renewIpv4'),
      );
      try {
        final service = ref.read(uspInternetSettingsServiceProvider);
        logger.d('[USP][Network][WAN] Renewing DHCPv4 lease...');
        await service.renewDhcpLease();
      } finally {
        state = state.copyWith(
          status: state.status.copyWith(clearActiveMutation: true),
        );
      }
    });
  }

  Future<void> renewDhcpv6Lease() async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      state = state.copyWith(
        status: state.status.copyWith(activeMutation: 'renewIpv6'),
      );
      try {
        final service = ref.read(uspInternetSettingsServiceProvider);
        logger.d('[USP][Network][WAN] Renewing DHCPv6 lease...');
        await service.renewDhcpv6Lease();
      } finally {
        state = state.copyWith(
          status: state.status.copyWith(clearActiveMutation: true),
        );
      }
    });
  }
}
