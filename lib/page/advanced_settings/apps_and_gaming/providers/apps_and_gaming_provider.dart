import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<AppsAndGamingViewState> fetch([bool force = false]) async {
    final pDDNSState = await ref.read(ddnsProvider.notifier).fetch(force);
    final pSinglePortState =
        await ref.read(singlePortForwardingListProvider.notifier).fetch(force);
    final pPortRangeForwardingState =
        await ref.read(portRangeForwardingListProvider.notifier).fetch(force);
    final pPortRangeTriggeringState =
        await ref.read(portRangeTriggeringListProvider.notifier).fetch(force);
    state = state.copyWith(
      preserveDDNSState: () => pDDNSState,
      preserveSinglePortForwardingListState: () => pSinglePortState,
      preservePortRangeForwardingListState: () => pPortRangeForwardingState,
      preservePortRangeTriggeringListState: () => pPortRangeTriggeringState,
    );
    return state;
  }

  Future<AppsAndGamingViewState> save() async {
    if (ref.read(ddnsProvider) != state.preserveDDNSState) {
      await ref.read(ddnsProvider.notifier).save();
    }
    if (ref.read(singlePortForwardingListProvider) !=
        state.preserveSinglePortForwardingListState) {
      await ref.read(singlePortForwardingListProvider.notifier).save();
    }
    if (ref.read(portRangeForwardingListProvider) !=
        state.preservePortRangeForwardingListState) {
      await ref.read(portRangeForwardingListProvider.notifier).save();
    }
    if (ref.read(portRangeTriggeringListProvider) !=
        state.preservePortRangeTriggeringListState) {
      await ref.read(portRangeTriggeringListProvider.notifier).save();
    }
    return fetch(true);
  }

  bool isChanged() {
    return ref.read(ddnsProvider) != state.preserveDDNSState ||
        ref.read(singlePortForwardingListProvider) !=
            state.preserveSinglePortForwardingListState ||
        ref.read(portRangeForwardingListProvider) !=
            state.preservePortRangeForwardingListState ||
        ref.read(portRangeTriggeringListProvider) !=
            state.preservePortRangeTriggeringListState;
  }
}
