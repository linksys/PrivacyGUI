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
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_status.dart';
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
    with PreservableNotifierMixin<DMZUISettings, DMZStatus, DMZSettingsState> {
  @override
  DMZSettingsState build() {
    const settings = DMZUISettings(
      isDMZEnabled: false,
      sourceType: DMZSourceType.auto,
      destinationType: DMZDestinationType.ip,
    );
    return const DMZSettingsState(
      settings: Preservable(original: settings, current: settings),
      status: DMZStatus(),
    );
  }

  @override
  Future<(DMZUISettings?, DMZStatus?)> performFetch(
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

    DMZStatus? status;
    if (lanResult != null && lanResult is JNAPSuccess) {
      final lanSettings = RouterLANSettings.fromMap(lanResult.output);
      final subnetMask = NetworkUtils.prefixLengthToSubnetMask(
          lanSettings.networkPrefixLength);
      final ipAddress =
          NetworkUtils.getIpPrefix(lanSettings.ipAddress, subnetMask);
      status = DMZStatus(ipAddress: ipAddress, subnetMask: subnetMask);
    }

    if (dmzResult != null && dmzResult is JNAPSuccess) {
      final dmzSettings = DMZSettings.fromMap(dmzResult.output);
      final uiSettings = DMZUISettings(
        isDMZEnabled: dmzSettings.isDMZEnabled,
        sourceRestriction: dmzSettings.sourceRestriction,
        destinationIPAddress: dmzSettings.destinationIPAddress,
        destinationMACAddress: dmzSettings.destinationMACAddress,
        sourceType: dmzSettings.sourceRestriction == null
            ? DMZSourceType.auto
            : DMZSourceType.range,
        destinationType: dmzSettings.destinationMACAddress == null
            ? DMZDestinationType.ip
            : DMZDestinationType.mac,
      );
      return (uiSettings, status ?? const DMZStatus());
    }

    return (null, null);
  }

  @override
  Future<void> performSave() async {
    final uiSettings = state.settings.current;
    final domainSettings = DMZSettings(
      isDMZEnabled: uiSettings.isDMZEnabled,
      sourceRestriction: uiSettings.sourceRestriction,
      destinationIPAddress: uiSettings.destinationIPAddress,
      destinationMACAddress: uiSettings.destinationMACAddress,
    );
    await ref.read(routerRepositoryProvider).send(
          JNAPAction.setDMZSettings,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          auth: true,
          data: domainSettings.toMap()
            ..removeWhere((key, value) => value == null),
        );
  }

  void setSettings(DMZUISettings settings) {
    state =
        state.copyWith(settings: state.settings.copyWith(current: settings));
  }

  void setSourceType(DMZSourceType type) {
    final currentSettings = state.settings.current;
    final originalSettings = state.settings.original;
    final newSettings = type == DMZSourceType.auto
        ? currentSettings.copyWith(sourceRestriction: () => null)
        : currentSettings.copyWith(
            sourceRestriction: () =>
                originalSettings.sourceRestriction ??
                const DMZSourceRestriction(
                    firstIPAddress: '', lastIPAddress: ''));

    state = state.copyWith(
      settings: state.settings
          .copyWith(current: newSettings.copyWith(sourceType: type)),
    );
  }

  void setDestinationType(DMZDestinationType type) {
    final currentSettings = state.settings.current;
    final newSettings = type == DMZDestinationType.ip
        ? currentSettings.copyWith(
            destinationMACAddress: () => null,
            destinationIPAddress: () =>
                state.settings.original.destinationIPAddress ?? '')
        : currentSettings.copyWith(
            destinationIPAddress: () => null,
            destinationMACAddress: () =>
                state.settings.original.destinationMACAddress ?? '');
    state = state.copyWith(
      settings: state.settings
          .copyWith(current: newSettings.copyWith(destinationType: type)),
    );
  }
}
