import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';

import 'feature_state.dart';
import 'preservable.dart';
import 'preservable_contract.dart';

// ---------------------------------------------------------------------------
// Shared delegate — single implementation for both Notifier variants.
// ---------------------------------------------------------------------------

/// Encapsulates the fetch/save/revert/dirty-check logic that both
/// [PreservableNotifierMixin] and [PreservableAutoDisposeNotifierMixin] share.
///
/// This eliminates the ~80 lines of duplication that was previously required
/// because Riverpod's [Notifier] and [AutoDisposeNotifier] lack a common
/// mixin-compatible base class.
class _PreservableDelegate<
    TSettings extends Equatable,
    TStatus extends Equatable,
    TState extends FeatureState<TSettings, TStatus>> {
  final TState Function() _getState;
  final void Function(TState) _setState;
  final Future<(TSettings?, TStatus?)> Function({
    bool forceRemote,
    bool updateStatusOnly,
  }) _performFetch;
  final Future<void> Function() _performSave;

  _PreservableDelegate({
    required TState Function() getState,
    required void Function(TState) setState,
    required Future<(TSettings?, TStatus?)> Function({
      bool forceRemote,
      bool updateStatusOnly,
    }) performFetch,
    required Future<void> Function() performSave,
  })  : _getState = getState,
        _setState = setState,
        _performFetch = performFetch,
        _performSave = performSave;

  // --- Public Template Methods (Called by UI) ---

  /// Fetches the latest settings and/or status.
  Future<TState> fetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final (newSettings, newStatus) = await _performFetch(
      forceRemote: forceRemote,
      updateStatusOnly: updateStatusOnly,
    );

    var s = _getState();
    if (updateStatusOnly) {
      // If only updating status, only apply the new status if it's not null.
      if (newStatus != null) {
        s = s.copyWith(status: newStatus) as TState;
      }
    } else {
      // If fetching settings, apply them and reset the preservable state.
      // Also apply a new status if one was returned.
      if (newSettings != null) {
        s = s.copyWith(
          settings: Preservable(original: newSettings, current: newSettings),
          status: newStatus ?? s.status,
        ) as TState;
      } else if (newStatus != null) {
        // Settings unavailable but status returned (e.g. error) — apply status
        // so the UI can exit the loading state and display the error.
        s = s.copyWith(status: newStatus) as TState;
      }
    }
    _setState(s);
    return s;
  }

  /// Saves the current settings, marks the state as clean, and then re-fetches from source.
  ///
  /// If the post-save re-fetch fails, the error is logged and rethrown so
  /// callers can reliably clear transient UI flags (e.g. `isSaving`).
  ///
  /// NOTE: that rethrow is not actually guaranteed here. `performFetch` has to
  /// turn a failure into a status rather than throw — the initial load has no
  /// caller to catch it — so this method returns normally even when the
  /// re-fetch failed, and the error only reaches the caller if the notifier
  /// inspects `status.error` after `super.save()`. `instant_safety` is
  /// currently the only one that does. Tracked in #1279; until it is fixed,
  /// do not rely on this paragraph.
  Future<TState> save() async {
    await _performSave();
    markAsSaved();
    return await fetch(forceRemote: true);
  }

  // --- SSE Invalidation Guard ---

  /// Called when an SSE event indicates external data has changed.
  /// If the user has unsaved edits (isDirty), the update is ignored
  /// to avoid clobbering their work. Otherwise, re-fetches fresh data.
  void onSseInvalidation() {
    if (!isDirty()) {
      unawaited(fetch(forceRemote: true).catchError((Object e, StackTrace st) {
        logger.e('[USP][SSE]: invalidation fetch failed', error: e);
        return _getState();
      }));
    }
  }

  // --- Internal Logic ---

  void revert() {
    final s = _getState();
    _setState(s.copyWith(
      settings: s.settings.copyWith(current: s.settings.original),
    ) as TState);
  }

  bool isDirty() => _getState().isDirty;

  void markAsSaved() {
    final s = _getState();
    _setState(s.copyWith(settings: s.settings.saved()) as TState);
  }
}

// ---------------------------------------------------------------------------
// Mixin for non-autoDispose Notifier (e.g. dashboard analytics)
// ---------------------------------------------------------------------------

mixin PreservableNotifierMixin<
        TSettings extends Equatable,
        TStatus extends Equatable,
        TState extends FeatureState<TSettings, TStatus>> on Notifier<TState>
    implements PreservableContract<TSettings, TStatus> {
  late final _delegate = _PreservableDelegate<TSettings, TStatus, TState>(
    getState: () => state,
    setState: (s) => state = s,
    performFetch: performFetch,
    performSave: performSave,
  );

  Future<TState> fetch(
          {bool forceRemote = false, bool updateStatusOnly = false}) =>
      _delegate.fetch(
          forceRemote: forceRemote, updateStatusOnly: updateStatusOnly);

  Future<TState> save() => _delegate.save();

  void onSseInvalidation() => _delegate.onSseInvalidation();

  @override
  void revert() => _delegate.revert();

  @override
  bool isDirty() => _delegate.isDirty();

  void markAsSaved() => _delegate.markAsSaved();
}

// ---------------------------------------------------------------------------
// Mixin for AutoDisposeNotifier (e.g. all preservable settings pages)
// ---------------------------------------------------------------------------

mixin PreservableAutoDisposeNotifierMixin<
        TSettings extends Equatable,
        TStatus extends Equatable,
        TState extends FeatureState<TSettings, TStatus>>
    on AutoDisposeNotifier<TState>
    implements PreservableContract<TSettings, TStatus> {
  late final _delegate = _PreservableDelegate<TSettings, TStatus, TState>(
    getState: () => state,
    setState: (s) => state = s,
    performFetch: performFetch,
    performSave: performSave,
  );

  Future<TState> fetch(
          {bool forceRemote = false, bool updateStatusOnly = false}) =>
      _delegate.fetch(
          forceRemote: forceRemote, updateStatusOnly: updateStatusOnly);

  Future<TState> save() => _delegate.save();

  void onSseInvalidation() => _delegate.onSseInvalidation();

  @override
  void revert() => _delegate.revert();

  @override
  bool isDirty() => _delegate.isDirty();

  void markAsSaved() => _delegate.markAsSaved();
}
