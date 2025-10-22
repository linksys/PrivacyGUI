import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/dmz_settings.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_state.dart';
import 'package:privacy_gui/providers/empty_status.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/utils.dart';

final preservableDMZSettingsProvider = Provider<PreservableContract>(
    (ref) => ref.watch(dmzSettingsProvider.notifier));

final dmzSettingsProvider =
    NotifierProvider<DMZSettingsNotifier, DMZSettingsState>(
        () => DMZSettingsNotifier());


class DMZSettingsNotifier extends Notifier<DMZSettingsState>
    with PreservableNotifierMixin<DMZSettings, EmptyStatus, DMZSettingsState> {
  String _subnetMask = '255.255.0.0';
  String get subnetMask => _subnetMask;
  String _ipAddress = '192.168.1.1';
  String get ipAddress => _ipAddress;

  @override
  DMZSettingsState build() {
    const settings = DMZSettings(isDMZEnabled: false);
    return const DMZSettingsState(
      settings: Preservable(original: settings, current: settings),
      status: EmptyStatus(),
    );
  }

  @override
  Future<(DMZSettings?, EmptyStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final result = await ref.read(routerRepositoryProvider).transaction(
          JNAPTransactionBuilder(
            commands: const [
              MapEntry(JNAPAction.getLANSettings, {}),
              MapEntry(JNAPAction.getDMZSettings, {}),
            ],
            auth: true,
          ),
          fetchRemote: forceRemote,
        );

    final lanResult = result.data
        .firstWhereOrNull((element) => element.key == JNAPAction.getLANSettings)
        ?.value;
    final dmzResult = result.data
        .firstWhereOrNull((element) => element.key == JNAPAction.getDMZSettings)
        ?.value;

    if (lanResult != null && lanResult is JNAPSuccess) {
      final lanSettings = RouterLANSettings.fromMap(lanResult.output);
      _subnetMask = NetworkUtils.prefixLengthToSubnetMask(
          lanSettings.networkPrefixLength);
      _ipAddress = NetworkUtils.getIpPrefix(lanSettings.ipAddress, subnetMask);
    }

    if (dmzResult != null && dmzResult is JNAPSuccess) {
      final dmzSettings = DMZSettings.fromMap(dmzResult.output);
      return (dmzSettings, const EmptyStatus());
    }

    return (null, null);
  }

  @override
  Future<void> performSave() async {
    await ref.read(routerRepositoryProvider).send(
          JNAPAction.setDMZSettings,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          auth: true,
          data: state.settings.current.toMap()
            ..removeWhere((key, value) => value == null),
        );
  }

  void setSettings(DMZSettings settings) {
    state =
        state.copyWith(settings: state.settings.copyWith(current: settings));
  }

  void setSourceType(DMZSourceType type) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(sourceType: type)));
  }

  void setDestinationType(DMZDestinationType type) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(destinationType: type)));
  }

  void clearDestinations() {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: DMZSettings(
          isDMZEnabled: state.settings.current.isDMZEnabled,
          sourceRestriction: state.settings.current.sourceRestriction,
        ),
      ),
    );
  }
}
