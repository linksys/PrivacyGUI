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
import 'package:privacy_gui/utils.dart';

final dmzSettingsProvider =
    NotifierProvider<DMZSettingNotifier, DMZSettingsState>(
        () => DMZSettingNotifier());

class DMZSettingNotifier extends Notifier<DMZSettingsState> {
  String _subnetMask = '255.255.0.0';
  String get subnetMask => _subnetMask;
  String _ipAddress = '192.168.1.1';
  String get ipAddress => _ipAddress;

  @override
  DMZSettingsState build() {
    return const DMZSettingsState(
        settings: DMZSettings(isDMZEnabled: false),
        sourceType: DMZSourceType.auto,
        destinationType: DMZDestinationType.ip);
  }

  Future<DMZSettingsState> fetch([bool force = false]) {
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .transaction(
      JNAPTransactionBuilder(
        commands: const [
          MapEntry(JNAPAction.getLANSettings, {}),
          MapEntry(JNAPAction.getDMZSettings, {}),
        ],
        auth: true,
      ),
      fetchRemote: force,
    )
        .then((result) {
      final lanResult = result.data
          .firstWhereOrNull(
              (element) => element.key == JNAPAction.getLANSettings)
          ?.value;
      final dmzResult = result.data
          .firstWhereOrNull(
              (element) => element.key == JNAPAction.getDMZSettings)
          ?.value;
      if (lanResult != null && lanResult is JNAPSuccess) {
        final lanSettings = RouterLANSettings.fromMap(lanResult.output);
        _subnetMask = NetworkUtils.prefixLengthToSubnetMask(
            lanSettings.networkPrefixLength);
        _ipAddress =
            NetworkUtils.getIpPrefix(lanSettings.ipAddress, subnetMask);
      }
      if (dmzResult != null && dmzResult is JNAPSuccess) {
        final dmzSettings = DMZSettings.fromMap(dmzResult.output);
        state = state.copyWith(
          settings: dmzSettings,
          sourceType: dmzSettings.sourceRestriction == null
              ? DMZSourceType.auto
              : DMZSourceType.range,
          destinationType: dmzSettings.destinationMACAddress == null
              ? DMZDestinationType.ip
              : DMZDestinationType.mac,
        );
      }
      return state;
    });
  }

  Future<DMZSettingsState> save() {
    return ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.setDMZSettings,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          auth: true,
          data: state.settings.toMap()
            ..removeWhere((key, value) => value == null),
        )
        .then((value) => fetch(true));
  }

  void setSettings(DMZSettings settings) {
    state = state.copyWith(settings: settings);
  }

  void setSourceType(DMZSourceType type) {
    state = state.copyWith(sourceType: type);
  }

  void setDestinationType(DMZDestinationType type) {
    state = state.copyWith(destinationType: type);
  }

  void clearDestinations() {
    state = state.copyWith(
        settings: DMZSettings(
      isDMZEnabled: state.settings.isDMZEnabled,
      sourceRestriction: state.settings.sourceRestriction,
    ));
  }
}
