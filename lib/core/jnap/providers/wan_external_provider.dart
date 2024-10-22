import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/wan_external.dart';
import 'package:privacy_gui/core/jnap/providers/wan_external_state.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';

final wanExternalProvider =
    NotifierProvider<WANExternalNotifier, WANExternalState>(
        () => WANExternalNotifier());

class WANExternalNotifier extends Notifier<WANExternalState> {
  @override
  WANExternalState build() {
    return WANExternalState();
  }

  FutureOr<WANExternalState> fetch({bool force = false}) {
    if (!serviceHelper.isSupportWANExternal()) {
      return state;
    }
    if (DateTime.now().millisecondsSinceEpoch - state.lastUpdate <
        3600 * 1000) {
      return state;
    }
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(JNAPAction.getWANExternal, fetchRemote: force, timeoutMs: 30000)
        .then((result) {
      final wanExternalData = WanExternal.fromMap(result.output);
      state = state.copyWith(
          wanExternal: wanExternalData,
          lastUpdate: DateTime.now().millisecondsSinceEpoch);
      return state;
    }).onError((error, stackTrace) {
      logger.d('[WanExternal]: error fetch wan external data!');
      return state;
    }).whenComplete(() {
      state = state.copyWith(lastUpdate: DateTime.now().millisecondsSinceEpoch);
    });
  }
}
