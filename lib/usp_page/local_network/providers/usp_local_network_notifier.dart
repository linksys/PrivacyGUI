import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/local_network/models/local_network_ui_model.dart';
import 'package:privacy_gui/usp_page/local_network/services/usp_local_network_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class UspLocalNetworkState extends Equatable {
  /// Original UI model (from last fetch).
  final LocalNetworkUIModel original;

  /// User's pending changes — may differ from [original] before save.
  final LocalNetworkUIModel pending;

  /// Whether a save operation is in progress.
  final bool isSaving;

  /// Per-field validation errors (field key → error message).
  /// null value = no error for that field.
  final Map<String, String?> errors;

  const UspLocalNetworkState({
    required this.original,
    required this.pending,
    this.isSaving = false,
    this.errors = const {},
  });

  bool get isDirty => original != pending;
  bool get hasErrors => errors.values.any((e) => e != null);

  /// True when router IP or subnet mask changed — save needs confirmation.
  bool get hasNetworkChange =>
      original.ipAddress != pending.ipAddress ||
      original.subnetMask != pending.subnetMask;

  UspLocalNetworkState copyWith({
    LocalNetworkUIModel? original,
    LocalNetworkUIModel? pending,
    bool? isSaving,
    Map<String, String?>? errors,
  }) {
    return UspLocalNetworkState(
      original: original ?? this.original,
      pending: pending ?? this.pending,
      isSaving: isSaving ?? this.isSaving,
      errors: errors ?? this.errors,
    );
  }

  @override
  List<Object?> get props => [original, pending, isSaving, errors];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspLocalNetworkProvider = AsyncNotifierProvider.autoDispose<
    UspLocalNetworkNotifier, UspLocalNetworkState>(
  UspLocalNetworkNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspLocalNetworkNotifier
    extends AutoDisposeAsyncNotifier<UspLocalNetworkState> {
  @override
  Future<UspLocalNetworkState> build() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    final data = await LanNetworkInfo.fetch(usp);
    final svc = ref.read(uspLocalNetworkServiceProvider);
    final uiModel = svc.buildUIModel(data);

    logger.d('[USP] LocalNetwork fetched — '
        'ip: ${uiModel.ipAddress}, '
        'dhcp: ${uiModel.dhcpEnabled}, '
        'pool: ${uiModel.minAddress}-${uiModel.maxAddress}');

    return UspLocalNetworkState(
      original: uiModel,
      pending: uiModel,
    );
  }

  /// Update a single setting synchronously + trigger cascade validation.
  ///
  /// When router IP changes, locked-prefix octets of pool IPs are
  /// automatically synced so the user doesn't have to retype them.
  void updateSetting(
      LocalNetworkUIModel Function(LocalNetworkUIModel) updater) {
    final s = state.valueOrNull;
    if (s == null) return;

    var newPending = updater(s.pending);
    final svc = ref.read(uspLocalNetworkServiceProvider);

    // Auto-sync pool prefix when router IP changes
    if (newPending.ipAddress != s.pending.ipAddress &&
        newPending.subnetMask.isNotEmpty) {
      final locked = svc.lockedOctetCount(newPending.subnetMask);
      if (locked > 0) {
        newPending = newPending.copyWith(
          minAddress: svc.syncPrefix(
              newPending.minAddress, newPending.ipAddress, locked),
          maxAddress: svc.syncPrefix(
              newPending.maxAddress, newPending.ipAddress, locked),
        );
      }
    }

    final errors = svc.validateAll(newPending);

    state = AsyncData(s.copyWith(
      pending: newPending,
      errors: errors,
    ));
  }

  /// Revert all pending changes to original (Dirty Guard revert).
  void revert() {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(
      pending: s.original,
      errors: const {},
    ));
  }

  /// Save pending changes to the router.
  ///
  /// Only sends fields that actually changed (dirty diff).
  /// Converts UI minutes → codegen seconds for leaseTime.
  Future<void> save() async {
    final s = state.requireValue;
    if (!s.isDirty || s.hasErrors) return;

    state = AsyncData(s.copyWith(isSaving: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      final svc = ref.read(uspLocalNetworkServiceProvider);
      final o = s.original;
      final p = s.pending;

      await LanNetworkInfo.save(
        usp,
        ipAddress: o.ipAddress != p.ipAddress ? p.ipAddress : null,
        subnetMask: o.subnetMask != p.subnetMask ? p.subnetMask : null,
        hostName: o.hostName != p.hostName ? p.hostName : null,
        dhcpEnabled: o.dhcpEnabled != p.dhcpEnabled ? p.dhcpEnabled : null,
        minAddress: o.minAddress != p.minAddress ? p.minAddress : null,
        maxAddress: o.maxAddress != p.maxAddress ? p.maxAddress : null,
        leaseTime: o.leaseTimeMinutes != p.leaseTimeMinutes
            ? p.leaseTimeMinutes * 60
            : null,
        dnsServers: _dnsChanged(o, p)
            ? svc.joinDnsServers(p.dnsServer1, p.dnsServer2, p.dnsServer3)
            : null,
      );

      logger.d('[USP] LocalNetwork saved');

      // Re-fetch to confirm changes took effect.
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(s.copyWith(isSaving: false));
      rethrow;
    }
  }

  /// Check if any DNS field changed.
  static bool _dnsChanged(LocalNetworkUIModel o, LocalNetworkUIModel p) {
    return o.dnsServer1 != p.dnsServer1 ||
        o.dnsServer2 != p.dnsServer2 ||
        o.dnsServer3 != p.dnsServer3;
  }
}
