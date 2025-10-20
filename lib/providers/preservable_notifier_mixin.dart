import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';

import 'feature_state.dart';
import 'preservable.dart';
import 'preservable_contract.dart';

// The Mixin (The "How")
// This provides the reusable implementation for any Notifier.
mixin PreservableNotifierMixin<
        TSettings extends Equatable,
        TStatus extends Equatable,
        TState extends FeatureState<TSettings, TStatus>> on Notifier<TState>
    implements PreservableContract<TSettings, TStatus> {
  // --- Public Template Methods (Called by UI) ---

  /// Fetches the latest settings and/or status.
  Future<void> fetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final (newSettings, newStatus) = await performFetch(
      forceRemote: forceRemote,
      updateStatusOnly: updateStatusOnly,
    );

    if (updateStatusOnly) {
      // If only updating status, only apply the new status if it's not null.
      if (newStatus != null) {
        state = state.copyWith(status: newStatus) as TState;
      }
    } else {
      // If fetching settings, apply them and reset the preservable state.
      // Also apply a new status if one was returned.
      if (newSettings != null) {
        state = state.copyWith(
          settings: Preservable(original: newSettings, current: newSettings),
          status: newStatus ?? state.status,
        ) as TState;
      }
    }
  }

  /// Saves the current settings, marks the state as clean, and then re-fetches from source.
  Future<void> save() async {
    await performSave();
    markAsSaved();
    try {
      await fetch();
    } catch (e) {
      // The save was successful, but the subsequent fetch failed.
      // The state is clean locally, but may be out of sync.
      // The next fetch will resolve this. For now, we can log this
      // error but we should not rethrow it, as the primary save
      // operation was successful.
       logger.e('Post-save fetch failed', error: e);
    }
  }

  // --- Mixin's Internal Logic & Provided Implementations ---

  @override
  void revert() {
    state = state.copyWith(
      settings: state.settings.copyWith(current: state.settings.original),
    ) as TState;
  }

  @override
  bool isDirty() => state.isDirty;

  void markAsSaved() {
    state = state.copyWith(settings: state.settings.saved()) as TState;
  }
}
