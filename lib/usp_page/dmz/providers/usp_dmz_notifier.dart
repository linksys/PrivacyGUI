import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/usp_page/dmz/services/usp_dmz_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class UspDmzState extends Equatable {
  /// Original UI model (from last fetch).
  final DmzUIModel original;

  /// User's pending changes — may differ from [original] before save.
  final DmzUIModel pending;

  /// Instance path of the existing DMZ entry, or null if none exists.
  final String? instancePath;

  /// Whether a save operation is in progress.
  final bool isSaving;

  const UspDmzState({
    required this.original,
    required this.pending,
    this.instancePath,
    this.isSaving = false,
  });

  bool get isDirty => original != pending;

  /// True when there is no existing DMZ entry on the router.
  bool get isNewEntry => instancePath == null;

  UspDmzState copyWith({
    DmzUIModel? original,
    DmzUIModel? pending,
    String? instancePath,
    bool clearInstancePath = false,
    bool? isSaving,
  }) {
    return UspDmzState(
      original: original ?? this.original,
      pending: pending ?? this.pending,
      instancePath:
          clearInstancePath ? null : (instancePath ?? this.instancePath),
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [original, pending, instancePath, isSaving];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspDmzProvider =
    AsyncNotifierProvider.autoDispose<UspDmzNotifier, UspDmzState>(
  UspDmzNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspDmzNotifier extends AutoDisposeAsyncNotifier<UspDmzState> {
  @override
  Future<UspDmzState> build() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    // SSE invalidation: re-fetch when DMZ config changes externally.
    // Only invalidate if user has no unsaved edits.
    ref.listen(sseInvalidationProvider, (prev, next) {
      if (next.valueOrNull == InvalidationDomain.dmz) {
        final s = state.valueOrNull;
        if (s != null && !s.isDirty && !s.isSaving) {
          ref.invalidateSelf();
        }
      }
    });

    final dmzData = await Dmz.fetch(usp);

    final svc = ref.read(uspDmzServiceProvider);
    final uiModel = svc.buildUIModel(dmzData);
    final instancePath =
        dmzData.items.isNotEmpty ? dmzData.items.first.instancePath : null;

    logger.d('[USP][Firewall][DMZ]DMZ fetched — '
        'entries: ${dmzData.items.length}, '
        'enabled: ${uiModel.isEnabled}, '
        'instancePath: $instancePath');

    return UspDmzState(
      original: uiModel,
      pending: uiModel,
      instancePath: instancePath,
    );
  }

  /// Update a single setting synchronously (no network call).
  void updateSetting(DmzUIModel Function(DmzUIModel) updater) {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(pending: updater(s.pending)));
  }

  /// Save pending changes to the router.
  ///
  /// Logic:
  /// - No existing entry + enabling → ADD new entry
  /// - Existing entry + changes → UPDATE entry
  /// - Existing entry + disabling → UPDATE with enable=false
  Future<void> save() async {
    final s = state.requireValue;
    if (!s.isDirty) return;

    state = AsyncData(s.copyWith(isSaving: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      final pending = s.pending;

      if (s.isNewEntry && pending.isEnabled) {
        // ADD new DMZ entry
        final sourcePrefix = pending.sourceType == DmzSourceType.any
            ? '0.0.0.0/0'
            : pending.sourcePrefix;
        await Dmz.add(
          usp,
          enable: true,
          destIp: pending.destIp,
          sourcePrefix: sourcePrefix,
          description: 'DMZ',
        );
        logger.d(
            '[USP][Firewall][DMZ]DMZ entry added — destIp: ${pending.destIp}');
      } else if (!s.isNewEntry) {
        // UPDATE existing entry
        final sourcePrefix = pending.sourceType == DmzSourceType.any
            ? '0.0.0.0/0'
            : pending.sourcePrefix;
        await Dmz.update(
          usp,
          DmzEntryUpdate(
            instancePath: s.instancePath!,
            enable: pending.isEnabled,
            destIp: pending.destIp,
            sourcePrefix: sourcePrefix,
          ),
        );
        logger.d('[USP][Firewall][DMZ]DMZ entry updated — '
            'enabled: ${pending.isEnabled}, destIp: ${pending.destIp}');
      }

      // Re-fetch to confirm changes.
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(s.copyWith(isSaving: false));
      rethrow;
    }
  }
}
