import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/usp_page/internet_settings/providers/usp_internet_settings_state.dart';
import 'package:privacy_gui/usp_page/internet_settings/services/usp_internet_settings_service.dart';

/// Main provider for the USP Internet Settings page.
final uspInternetSettingsProvider = AsyncNotifierProvider.autoDispose<
    UspInternetSettingsNotifier, UspInternetSettingsState>(
  UspInternetSettingsNotifier.new,
);

/// Adapter that exposes the async notifier as [PreservableContract] for
/// route-level dirty checking via [LinksysRoute].
final preservableUspInternetSettingsProvider =
    Provider<PreservableContract>((ref) {
  return _UspPreservableAdapter(ref);
});

/// Service provider — stateless, created from the current UspService.
final uspInternetSettingsServiceProvider =
    Provider.autoDispose<UspInternetSettingsService>((ref) {
  final usp = ref.watch(uspServiceProvider);
  if (usp == null) throw StateError('USP service not available');
  return UspInternetSettingsService(usp);
});

/// Tracks the current mutation in progress (for per-section loading overlays).
/// Values: null (idle), 'save', 'renewIpv4', 'renewIpv6'
final uspInternetMutationLoadingProvider =
    StateProvider<String?>((ref) => null);

/// Bridges the async USP notifier to the [PreservableContract] expected by
/// [LinksysRoute.onExit]. Only [isDirty] and [revert] are called at route
/// level; [performFetch] and [performSave] are unused stubs.
class _UspPreservableAdapter
    implements PreservableContract<UspInternetSettingsForm, Equatable> {
  final Ref _ref;
  const _UspPreservableAdapter(this._ref);

  @override
  bool isDirty() =>
      _ref.read(uspInternetSettingsProvider).valueOrNull?.isDirty ?? false;

  @override
  void revert() =>
      _ref.read(uspInternetSettingsProvider.notifier).exitEditMode();

  @override
  Future<(UspInternetSettingsForm?, Equatable?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) =>
      throw UnimplementedError('Use notifier.build() directly');

  @override
  Future<void> performSave() =>
      throw UnimplementedError('Use notifier.save() directly');
}

class UspInternetSettingsNotifier
    extends AutoDisposeAsyncNotifier<UspInternetSettingsState> {
  bool _mutating = false;

  @override
  Future<UspInternetSettingsState> build() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    // Session restore on page reload (WASM state may be lost)
    if (!usp.isAuthenticated) {
      await ref.read(uspAuthCoordinatorProvider).restoreSession();
      if (!usp.isAuthenticated) {
        throw StateError('USP not authenticated after restore attempt');
      }
    }

    final service = ref.read(uspInternetSettingsServiceProvider);
    final (wan, ipv6) = await service.fetchSettings();
    final form = UspInternetSettingsForm.fromGenerated(wan, ipv6);

    logger.d('[USP][Network][WAN]Fetched — '
        'raw addressingType: "${wan.addressingType}", '
        'bridgeEnabled: ${wan.bridgeEnabled}, '
        'detected type: ${UspWanConnectionType.fromWanSettings(wan).name}, '
        'mtu: ${wan.mtu}, ipv6: ${ipv6.ipv6Enabled}, '
        'staticIp: "${wan.staticIpAddress}", '
        'gateway: "${wan.defaultGateway}"');

    return UspInternetSettingsState(
      wanSettings: wan,
      ipv6Settings: ipv6,
      original: form,
      edited: form,
    );
  }

  // ---------------------------------------------------------------------------
  // Edit mode
  // ---------------------------------------------------------------------------

  void enterEditMode() {
    final s = state.requireValue;
    state = AsyncData(s.copyWith(isEditing: true));
  }

  void exitEditMode() {
    final s = state.requireValue;
    state = AsyncData(s.copyWith(
      edited: s.original,
      isEditing: false,
    ));
  }

  // ---------------------------------------------------------------------------
  // Form field updates
  // ---------------------------------------------------------------------------

  /// Generic field updater — takes a function that returns a modified form.
  void updateField(
      UspInternetSettingsForm Function(UspInternetSettingsForm) updater) {
    final s = state.requireValue;
    state = AsyncData(s.copyWith(edited: updater(s.edited)));
  }

  /// Update connection type with appropriate field resets.
  void updateConnectionType(UspWanConnectionType type) {
    final s = state.requireValue;
    var form = s.edited.copyWith(connectionType: type);

    // Reset type-specific fields when switching away
    if (type == UspWanConnectionType.bridge) {
      // Bridge mode: disable MTU, reset MAC clone
      form = form.copyWith(mtu: 0);
    }

    state = AsyncData(s.copyWith(edited: form));
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> save() async {
    await _withLock(() async {
      final s = state.requireValue;
      final service = ref.read(uspInternetSettingsServiceProvider);

      logger.d('[USP][Network][WAN]Saving changes...');
      await service.saveAll(s.original, s.edited);

      // Re-fetch to get server-confirmed values
      final (wan, ipv6) = await service.fetchSettings();
      final form = UspInternetSettingsForm.fromGenerated(wan, ipv6);

      logger.d('[USP][Network][WAN]Save complete, re-fetched');
      state = AsyncData(UspInternetSettingsState(
        wanSettings: wan,
        ipv6Settings: ipv6,
        original: form,
        edited: form,
        isEditing: false,
      ));
    });
  }

  // ---------------------------------------------------------------------------
  // DHCP Renewal
  // ---------------------------------------------------------------------------

  Future<void> renewDhcpLease() async {
    await _withLock(() async {
      final service = ref.read(uspInternetSettingsServiceProvider);
      logger.d('[USP][Network][WAN]Renewing DHCPv4 lease...');
      await service.renewDhcpLease();
    });
  }

  Future<void> renewDhcpv6Lease() async {
    await _withLock(() async {
      final service = ref.read(uspInternetSettingsServiceProvider);
      logger.d('[USP][Network][WAN]Renewing DHCPv6 lease...');
      await service.renewDhcpv6Lease();
    });
  }

  // ---------------------------------------------------------------------------
  // Sequential lock guard
  // ---------------------------------------------------------------------------

  Future<T> _withLock<T>(Future<T> Function() action) async {
    if (_mutating) throw StateError('Another mutation is in progress');
    _mutating = true;
    try {
      return await action();
    } finally {
      _mutating = false;
    }
  }
}
