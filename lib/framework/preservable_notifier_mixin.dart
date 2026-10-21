import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:privacy_gui/core/errors/service_error.dart';

import 'feature_state.dart';
import 'has_service_error.dart';
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
    return _apply(newSettings, newStatus, updateStatusOnly: updateStatusOnly);
  }

  TState _apply(
    TSettings? newSettings,
    TStatus? newStatus, {
    required bool updateStatusOnly,
  }) {
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

  /// Saves the current settings, marks the state as clean, and then re-fetches
  /// from source.
  ///
  /// A failure in [performSave] propagates. A failure in the post-save
  /// re-fetch throws [SavedButUnconfirmedError], and leaves the page on what
  /// was written.
  ///
  /// Who asked for the read decides what its failure means, and only this
  /// method knows (#1212, #1279). `performFetch` turns a failed read into a
  /// status carrying the error, and must: the initial load runs from `build()`
  /// with no caller to catch a throw (#1274), and pull-to-refresh's
  /// `RefreshIndicator` never catches one either. After a save that same status
  /// used to land on the page — an error page under the caller's "saved" toast,
  /// for a write that had landed (11 of 14 pages, re-run on DMZ 2026-10-21).
  /// So here the status is not applied: the settings stay on what was written
  /// and clean, the status stays as it was, and the read's error is thrown for
  /// the caller to report.
  ///
  /// A failed read is `performFetch` returning no settings. Its error is taken
  /// from a status that implements [HasServiceError]; one that does not, or
  /// that carries none, keeps today's behaviour and is applied.
  Future<TState> save() async {
    await _performSave();
    markAsSaved();
    return confirmSaved();
  }

  /// The post-save half of [save]: reads the router back after a write that
  /// landed and was marked saved, under the rule documented there.
  ///
  /// For a notifier that overrides `save()` with its own sequence (one that
  /// skips the read when the router is about to be unreachable, say): call
  /// this instead of `fetch(forceRemote: true)` so the read keeps that rule.
  Future<TState> confirmSaved() async {
    final written = _getState();
    final (newSettings, newStatus) = await _performFetch(forceRemote: true);
    if (newSettings != null) {
      return _apply(newSettings, newStatus, updateStatusOnly: false);
    }
    final Object? status = newStatus;
    final cause = status is HasServiceError ? status.error : null;
    if (cause == null) {
      return _apply(newSettings, newStatus, updateStatusOnly: false);
    }
    _setState(written);
    throw SavedButUnconfirmedError(cause);
  }

  /// [confirmSaved], retried: for a write that leaves the router answering
  /// before its data has settled (every Wi-Fi write reloads the radios, and
  /// right after the reload a Wi-Fi GET comes back with no rows).
  ///
  /// [before] runs ahead of each attempt — refreshing what the read depends
  /// on. Attempts are [interval] apart; the last failure is thrown.
  Future<TState> confirmSavedRetrying({
    required int attempts,
    required Duration interval,
    Future<void> Function()? before,
  }) async {
    for (var attempt = 1;; attempt++) {
      await before?.call();
      try {
        return await confirmSaved();
      } on SavedButUnconfirmedError {
        if (attempt >= attempts) rethrow;
        await Future<void>.delayed(interval);
      }
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

  /// Saves, marks clean, then re-fetches to confirm.
  ///
  /// A failed post-save re-fetch throws [SavedButUnconfirmedError] and leaves
  /// the page on what was written. See `_PreservableDelegate.save()`.
  Future<TState> save() => _delegate.save();

  /// The read-back half of [save], for an override that sequences its own
  /// save. See `_PreservableDelegate.confirmSaved()`.
  Future<TState> confirmSaved() => _delegate.confirmSaved();

  /// [confirmSaved], retried. See `_PreservableDelegate.confirmSavedRetrying()`.
  Future<TState> confirmSavedRetrying({
    required int attempts,
    required Duration interval,
    Future<void> Function()? before,
  }) =>
      _delegate.confirmSavedRetrying(
          attempts: attempts, interval: interval, before: before);

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

  /// Saves, marks clean, then re-fetches to confirm.
  ///
  /// A failed post-save re-fetch throws [SavedButUnconfirmedError] and leaves
  /// the page on what was written. See `_PreservableDelegate.save()`.
  Future<TState> save() => _delegate.save();

  /// The read-back half of [save], for an override that sequences its own
  /// save. See `_PreservableDelegate.confirmSaved()`.
  Future<TState> confirmSaved() => _delegate.confirmSaved();

  /// [confirmSaved], retried. See `_PreservableDelegate.confirmSavedRetrying()`.
  Future<TState> confirmSavedRetrying({
    required int attempts,
    required Duration interval,
    Future<void> Function()? before,
  }) =>
      _delegate.confirmSavedRetrying(
          attempts: attempts, interval: interval, before: before);

  @override
  void revert() => _delegate.revert();

  @override
  bool isDirty() => _delegate.isDirty();

  void markAsSaved() => _delegate.markAsSaved();
}
