import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';
import 'package:privacy_gui/page/instant_safety/services/instant_safety_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class UspInstantSafetyState extends Equatable {
  /// Presentation Layer UI Model (for views).
  final SafeBrowsingUIModel uiModel;

  /// User's pending selection — may differ from [uiModel.type] before save.
  final SafeBrowsingType pendingType;

  /// Whether a save operation is in progress.
  final bool isSaving;

  const UspInstantSafetyState({
    required this.uiModel,
    required this.pendingType,
    this.isSaving = false,
  });

  bool get isDirty => pendingType != uiModel.type;
  bool get isEnabled => pendingType != SafeBrowsingType.off;

  UspInstantSafetyState copyWith({
    SafeBrowsingUIModel? uiModel,
    SafeBrowsingType? pendingType,
    bool? isSaving,
  }) {
    return UspInstantSafetyState(
      uiModel: uiModel ?? this.uiModel,
      pendingType: pendingType ?? this.pendingType,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [uiModel, pendingType, isSaving];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspInstantSafetyProvider =
    AsyncNotifierProvider<UspInstantSafetyNotifier, UspInstantSafetyState>(
  UspInstantSafetyNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspInstantSafetyNotifier extends AsyncNotifier<UspInstantSafetyState> {
  @override
  Future<UspInstantSafetyState> build() async {
    final svc = ref.read(uspInstantSafetyServiceProvider);
    final uiModel = await svc.fetch();

    logger.d('[USP][Safety]Instant Safety fetched — type: ${uiModel.type}');

    return UspInstantSafetyState(
      uiModel: uiModel,
      pendingType: uiModel.type,
    );
  }

  /// Toggle safe browsing on/off.
  void setEnabled(bool enabled) {
    final s = state.valueOrNull;
    if (s == null) return;
    final newType = enabled ? SafeBrowsingType.openDNS : SafeBrowsingType.off;
    state = AsyncData(s.copyWith(pendingType: newType));
  }

  /// Save the pending selection to the router.
  Future<void> save() async {
    final s = state.requireValue;
    if (!s.isDirty) return;

    state = AsyncData(s.copyWith(isSaving: true));
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        final svc = ref.read(uspInstantSafetyServiceProvider);
        await svc.save(s.pendingType);
      });
      logger.d('[USP][Safety]Instant Safety saved — type: ${s.pendingType}');

      // Re-fetch to confirm the change took effect.
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(s.copyWith(isSaving: false));
      rethrow;
    }
  }
}
