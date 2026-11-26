import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/_ddns.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_state.dart';

final appsAndGamingProvider =
    NotifierProvider<AppsAndGamingViewNotifier, AppsAndGamingViewState>(
        () => AppsAndGamingViewNotifier());

class AppsAndGamingViewNotifier extends Notifier<AppsAndGamingViewState> {
  @override
  AppsAndGamingViewState build() {
    return AppsAndGamingViewState();
  }

  /// Reads each tab on its own, so that a refused read leaves only its own tab
  /// unread. Then rethrows the first refusal, if any.
  ///
  /// A tab that was read keeps what it read, to tell an edit from it. A tab
  /// that was not read keeps nothing, which also drops what an earlier visit
  /// read: it does not count as changed and is never saved, because a save
  /// replaces the router's whole list with what the tab shows (#1974).
  Future<AppsAndGamingViewState> fetch([bool force = false]) async {
    (Object, StackTrace)? failure;
    Future<T?> read<T>(Future<T> Function() fetchTab) async {
      try {
        return await fetchTab();
      } catch (error, stackTrace) {
        failure ??= (error, stackTrace);
        return null;
      }
    }

    final pDDNSState =
        await read(() => ref.read(ddnsProvider.notifier).fetch(force));
    final pSinglePortState = await read(
        () => ref.read(singlePortForwardingListProvider.notifier).fetch(force));
    final pPortRangeForwardingState = await read(
        () => ref.read(portRangeForwardingListProvider.notifier).fetch(force));
    final pPortRangeTriggeringState = await read(
        () => ref.read(portRangeTriggeringListProvider.notifier).fetch(force));
    state = state.copyWith(
      preserveDDNSState: () => pDDNSState,
      preserveSinglePortForwardingListState: () => pSinglePortState,
      preservePortRangeForwardingListState: () => pPortRangeForwardingState,
      preservePortRangeTriggeringListState: () => pPortRangeTriggeringState,
    );
    if (failure case (final error, final stackTrace)) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    return state;
  }

  Future<AppsAndGamingViewState> save() async {
    if (_isDDNSChanged()) {
      await ref.read(ddnsProvider.notifier).save();
    }
    bool saveForwardingSuccess = false;

    /// Because UI can edit all rules at a same time
    /// Here is an edge case - Port range deleted a exist rule and Single port add a rule which conflict with
    /// the deleted rule. Then save will get overlap error becaule single port JNAP is called first, the Router
    /// doesn't delete the deleted rule yet.
    /// Workaround - if save failed, tried save vice verse.
    try {
      if (_isSinglePortForwardingChanged()) {
        await ref.read(singlePortForwardingListProvider.notifier).save();
      }
      if (_isPortRangeForwardingChanged()) {
        await ref.read(portRangeForwardingListProvider.notifier).save();
      }
      saveForwardingSuccess = true;
    } catch (e) {
      logger.d('Save forwarding rules failed! try another combination');
    }
    if (!saveForwardingSuccess) {
      if (_isPortRangeForwardingChanged()) {
        await ref.read(portRangeForwardingListProvider.notifier).save();
      }
      if (_isSinglePortForwardingChanged()) {
        await ref.read(singlePortForwardingListProvider.notifier).save();
      }
    }

    if (_isPortRangeTriggeringChanged()) {
      await ref.read(portRangeTriggeringListProvider.notifier).save();
    }
    return fetch(true);
  }

  /// Whether a tab that was read differs from what it read. A tab that was
  /// not read never counts (#1974).
  bool isChanged() {
    return _isDDNSChanged() ||
        _isSinglePortForwardingChanged() ||
        _isPortRangeForwardingChanged() ||
        _isPortRangeTriggeringChanged();
  }

  /// Whether every tab was read. Until then the page offers no save, so that
  /// an edit on a tab that was not read is not dropped unseen (#1974).
  bool isReadComplete() {
    return state.preserveDDNSState != null &&
        state.preserveSinglePortForwardingListState != null &&
        state.preservePortRangeForwardingListState != null &&
        state.preservePortRangeTriggeringListState != null;
  }

  bool _isDDNSChanged() {
    final preserved = state.preserveDDNSState;
    return preserved != null &&
        ref.read(ddnsProvider).provider != preserved.provider;
  }

  bool _isSinglePortForwardingChanged() {
    final preserved = state.preserveSinglePortForwardingListState;
    return preserved != null &&
        ref.read(singlePortForwardingListProvider) != preserved;
  }

  bool _isPortRangeForwardingChanged() {
    final preserved = state.preservePortRangeForwardingListState;
    return preserved != null &&
        ref.read(portRangeForwardingListProvider) != preserved;
  }

  bool _isPortRangeTriggeringChanged() {
    final preserved = state.preservePortRangeTriggeringListState;
    return preserved != null &&
        ref.read(portRangeTriggeringListProvider) != preserved;
  }

  bool isDataValid() {
    return ref.read(ddnsProvider.notifier).isDataValid();
  }
}
