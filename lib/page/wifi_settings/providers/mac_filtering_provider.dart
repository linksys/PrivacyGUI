import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/mac_filter_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/page/wifi_settings/providers/mac_filtering_state.dart';
import 'package:privacy_gui/util/extensions.dart';

final macFilteringProvider =
    NotifierProvider<MacFilteringNotifier, MacFilteringState>(
        () => MacFilteringNotifier());

class MacFilteringNotifier extends Notifier<MacFilteringState> {
  @override
  MacFilteringState build() => MacFilteringState.init();

  Future<MacFilteringState> fetch() async {
    final settings = await ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.getMACFilterSettings,
          fetchRemote: true,
          auth: true,
        )
        .then((result) => MACFilterSettings.fromMap(result.output));
    state = state.copyWith(
      mode: MacFilterMode.reslove(settings.macFilterMode),
      macAddresses: settings.macAddresses,
      maxMacAddresses: settings.maxMACAddresses,
    );
    return state;
  }

  Future save() async {
    await ref.read(routerRepositoryProvider).send(
          JNAPAction.setMACFilterSettings,
          data: {
            'macFilterMode': state.mode.name.capitalize(),
            'macAddresses': state.macAddresses,
          },
          auth: true,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        );
  }

  setEnable(bool isEnabled) {
    state = state.copyWith(
        mode: isEnabled ? MacFilterMode.allow : MacFilterMode.disabled);
  }

  setAccess(String value) {
    final status =
        MacFilterMode.values.firstWhereOrNull((e) => e.name == value);
    if (status != null) {
      state = state.copyWith(mode: status);
    }
  }

  setSelection(List<String> selections) {
    final List<String> unique = List.from(state.macAddresses)
      ..addAll(selections)
      ..unique();
    state = state.copyWith(macAddresses: unique);
  }

  removeSelection(List<String> selection) {
    final list = List<String>.from(state.macAddresses)
      ..removeWhere((element) => selection.contains(element));
    state = state.copyWith(macAddresses: list);
  }
}
