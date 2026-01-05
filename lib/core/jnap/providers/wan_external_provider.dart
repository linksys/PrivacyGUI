import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/wan_external_state.dart';
import 'package:privacy_gui/core/jnap/services/wan_external_service.dart';
import 'package:privacy_gui/core/utils/logger.dart';

final wanExternalProvider =
    NotifierProvider<WANExternalNotifier, WANExternalState>(
        () => WANExternalNotifier());

class WANExternalNotifier extends Notifier<WANExternalState> {
  @override
  WANExternalState build() {
    return const WANExternalState();
  }

  FutureOr<WANExternalState> fetch({bool force = false}) async {
    if (!serviceHelper.isSupportWANExternal()) {
      return state;
    }
    if (!force &&
        DateTime.now().millisecondsSinceEpoch - state.lastUpdate <
            3600 * 1000) {
      return state;
    }

    try {
      final service = ref.read(wanExternalServiceProvider);
      final wanExternalData = await service.fetchWanExternal(force: force);
      state = state.copyWith(
          wanExternal: wanExternalData,
          lastUpdate: DateTime.now().millisecondsSinceEpoch);
      return state;
    } catch (error) {
      logger.d('[WanExternal]: error fetch wan external data: $error');
      state = state.copyWith(lastUpdate: DateTime.now().millisecondsSinceEpoch);
      return state;
    }
  }
}
