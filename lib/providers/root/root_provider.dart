import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/providers/root/root_config.dart';

final rootProvider =
    NotifierProvider<RootNotifier, AppRootConfig>(() => RootNotifier());

class RootNotifier extends Notifier<AppRootConfig> {
  @override
  AppRootConfig build() {
    return const AppRootConfig();
  }

  void showSpinner({
    String? singleMessage,
    Map<int, String>? messages,
    String tag = 'general',
    bool force = false,
  }) {
    if (state.spinnerTag != tag && state.force) {
      return;
    }
    state = state.copyWith(
      singleMessage: singleMessage,
      messages: messages,
      spinnerTag: tag,
      force: force,
    );
  }

  void hideSpinner({String tag = 'general'}) {
    if (state.spinnerTag != tag && state.force) {
      return;
    }
    state = const AppRootConfig();
  }
}
