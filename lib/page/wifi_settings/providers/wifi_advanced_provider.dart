import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';

final wifiAdvancedProvider =
    NotifierProvider<WifiAdvancedSettingsNotifier, WifiAdvancedSettingsState>(
        () => WifiAdvancedSettingsNotifier());

class WifiAdvancedSettingsNotifier extends Notifier<WifiAdvancedSettingsState> {
  @override
  WifiAdvancedSettingsState build() {
    return const WifiAdvancedSettingsState();
  }

  List<MapEntry<JNAPAction, Map<String, dynamic>>> _buildGetCommends() {
    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands = [];
    if (isServiceSupport(JNAPService.nodesTopologyOptimization2)) {
      commands
          .add(const MapEntry(JNAPAction.getTopologyOptimizationSettings, {}));
    }
    if (isServiceSupport(JNAPService.iptv)) {
      commands.add(
        const MapEntry(JNAPAction.getIptvSettings, {}),
      );
    }
    if (isServiceSupport(JNAPService.mlo)) {
      commands.add(
        const MapEntry(JNAPAction.getMLOSettings, {}),
      );
    }
    if (isServiceSupport(JNAPService.dfs)) {
      commands.add(
        const MapEntry(JNAPAction.getDFSSettings, {}),
      );
    }
    if (isServiceSupport(JNAPService.airtimeFairness)) {
      commands.add(
        const MapEntry(JNAPAction.getAirtimeFairnessSettings, {}),
      );
    }
    return commands;
  }

  List<MapEntry<JNAPAction, Map<String, dynamic>>> _buildSetCommends({
    bool? isClientSteeringEnabled,
    bool? isNodeSteeringEnabled,
    bool? isIptvEnabled,
    bool? isMLOEnabled,
    bool? isDFSEnabled,
    bool? isAirtimeFairnessEnabled,
  }) {
    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands = [];
    if (isServiceSupport(JNAPService.nodesTopologyOptimization2)) {
      commands.add(MapEntry(
          JNAPAction.setTopologyOptimizationSettings,
          {
            'isClientSteeringEnabled': isClientSteeringEnabled,
            'isNodeSteeringEnabled': isNodeSteeringEnabled,
          }..removeWhere((key, value) => value == null)));
    }
    if (isServiceSupport(JNAPService.iptv)) {
      commands.add(
        MapEntry(JNAPAction.setIptvSettings, {'isEnabled': isIptvEnabled}),
      );
    }
    if (isServiceSupport(JNAPService.mlo) && isMLOEnabled != null) {
      commands.add(
        MapEntry(JNAPAction.setMLOSettings, {'isMLOEnabled': isMLOEnabled}),
      );
    }
    if (isServiceSupport(JNAPService.dfs) && isDFSEnabled != null) {
      commands.add(
        MapEntry(JNAPAction.setDFSSettings, {'isDFSEnabled': isDFSEnabled}),
      );
    }
    if (isServiceSupport(JNAPService.airtimeFairness) &&
        isAirtimeFairnessEnabled != null) {
      commands.add(
        MapEntry(JNAPAction.setAirtimeFairnessSettings,
            {'isAirtimeFairnessEnabled': isAirtimeFairnessEnabled}),
      );
    }
    return commands;
  }

  Future fetch([bool force = false]) {
    return ref
        .read(routerRepositoryProvider)
        .transaction(
          fetchRemote: force,
          JNAPTransactionBuilder(commands: _buildGetCommends(), auth: true),
        )
        .then((successWrap) => Map.fromEntries(successWrap.data))
        .then((data) => (
              data[JNAPAction.getTopologyOptimizationSettings] as JNAPSuccess?,
              data[JNAPAction.getIptvSettings] as JNAPSuccess?,
              data[JNAPAction.getMLOSettings] as JNAPSuccess?,
              data[JNAPAction.getDFSSettings] as JNAPSuccess?,
              data[JNAPAction.getAirtimeFairnessSettings] as JNAPSuccess?,
            ))
        .then((data) {
      final bool? isClientSteeringEnabled =
          data.$1?.output['isClientSteeringEnabled'];
      final bool? isNodeSteeringEnabled =
          data.$1?.output['isNodeSteeringEnabled'];
      // iptv
      final bool? isIptvEnabled = data.$2?.output['isEnabled'];
      // mlo
      final bool? isMLOSupported = data.$3?.output['isMLOSupported'];
      bool? isMLOEnabled;
      if (isMLOSupported ?? false) {
        isMLOEnabled = data.$3?.output['isMLOEnabled'];
      }
      // dfs
      final bool? isDFSSupported = data.$4?.output['isDFSSupported'];
      bool? isDFSEnabled;
      if (isDFSSupported ?? false) {
        isDFSEnabled = data.$4?.output['isDFSEnabled'];
      }
      // airtimefairness
      final bool? isAirtimeFairnessSupported =
          data.$3?.output['isAirtimeFairnessSupported'];
      bool? isAirtimeFairnessEnabled;
      if (isAirtimeFairnessSupported ?? false) {
        isAirtimeFairnessEnabled = data.$5?.output['isAirtimeFairnessEnabled'];
      }

      state = state.copyWith(
        isClientSteeringEnabled: isClientSteeringEnabled,
        isNodesSteeringEnabled: isNodeSteeringEnabled,
        isIptvEnabled: isIptvEnabled,
        isMLOEnabled: isMLOEnabled,
        isDFSEnabled: isDFSEnabled,
        isAirtimeFairnessEnabled: isAirtimeFairnessEnabled,
      );
    });
  }

  Future save() {
    return ref
        .read(routerRepositoryProvider)
        .transaction(
          JNAPTransactionBuilder(
              commands: _buildSetCommends(
                isClientSteeringEnabled: state.isClientSteeringEnabled,
                isNodeSteeringEnabled: state.isNodesSteeringEnabled,
                isIptvEnabled: state.isIptvEnabled,
                isDFSEnabled: state.isDFSEnabled,
                isMLOEnabled: state.isMLOEnabled,
                isAirtimeFairnessEnabled: state.isAirtimeFairnessEnabled,
              ),
              auth: true),
        )
        .then((_) => fetch(true));
  }

  void setClientSteeringEnabled(bool value) {
    state = state.copyWith(isClientSteeringEnabled: value);
  }

  void setNodesSteeringEnabled(bool value) {
    state = state.copyWith(isNodesSteeringEnabled: value);
  }

  void setIptvEnabled(bool value) {
    state = state.copyWith(isIptvEnabled: value);
  }

  void setDFSEnabled(bool value) {
    state = state.copyWith(isDFSEnabled: value);
  }

  void setMLOEnabled(bool value) {
    state = state.copyWith(isMLOEnabled: value);
  }

  void setAirtimeFairnessEnabled(bool value) {
    state = state.copyWith(isAirtimeFairnessEnabled: value);
  }
}
