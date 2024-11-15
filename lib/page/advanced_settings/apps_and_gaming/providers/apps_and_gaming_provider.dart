import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/_ddns.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_state.dart';

final appsAndGamingProvider =
    NotifierProvider<AppsAndGamingViewNotifier, AppsAndGamingViewState>(
        () => AppsAndGamingViewNotifier());

class AppsAndGamingViewNotifier extends Notifier<AppsAndGamingViewState> {
  @override
  AppsAndGamingViewState build() {
    return AppsAndGamingViewState(isCurrentViewStateChanged: false);
  }

  Future fetch([bool force = false]) async {
    await ref.read(ddnsProvider.notifier).fetch(force);
    await ref.read(singlePortForwardingListProvider.notifier).fetch(force);
    await ref.read(portRangeForwardingListProvider.notifier).fetch(force);
    await ref.read(portRangeTriggeringListProvider.notifier).fetch(force);
  }

  void setChanged(bool value) {
    state = state.copyWith(isCurrentViewStateChanged: value);
  }
}
