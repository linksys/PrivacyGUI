import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/dual_wan_ethernet_port_connections.dart';
import 'package:privacy_gui/core/jnap/models/dual_wan_settings.dart';
import 'package:privacy_gui/core/jnap/models/ethernet_port_connections.dart';
import 'package:privacy_gui/core/jnap/providers/ethernet_port_connection_state.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';

final ethernetPortConnectionProvider = NotifierProvider<
    EthernetPortConnectionNotifier,
    EthernetPortConnectionState>(() => EthernetPortConnectionNotifier());

class EthernetPortConnectionNotifier
    extends Notifier<EthernetPortConnectionState> {
  @override
  EthernetPortConnectionState build() {
    return EthernetPortConnectionState();
  }

  FutureOr<EthernetPortConnectionState> fetch({bool force = false}) async {
    final repo = ref.read(routerRepositoryProvider);
    // 1. Check if Dual WAN is supported
    //    If supported, get Dual WAN Settings
    if (serviceHelper.isSupportDualWAN()) {
      final dualWANSettings = await repo
          .send(JNAPAction.getDualWANSettings, auth: true)
          .then<RouterDualWANSettings?>((result) {
        return RouterDualWANSettings.fromMap(result.output);
      }).onError((error, stackTrace) {
        logger.e('Error getting Dual WAN Settings: $error, $stackTrace');
        return null;
      });
      // 2. Check if Dual WAN is enabled
      //    If enabled, get Ethernet Port Connection via getDualWANEthernetPortConnections
      if (dualWANSettings?.enabled ?? false) {
        final dualWANEthernetPortConnections = await repo
            .send(JNAPAction.getDualWANEthernetPortConnections, auth: true)
            .then<RouterDualWANEthernetPortConnections?>((result) {
          return RouterDualWANEthernetPortConnections.fromMap(result.output);
        }).onError((error, stackTrace) {
          logger.e(
              'Error getting Dual WAN Ethernet Port Connections: $error, $stackTrace');
          return null;
        });
        if (dualWANEthernetPortConnections != null) {
          state = state.copyWith(
            isDualWANEnabled: true,
            primaryWAN:
                dualWANEthernetPortConnections.primaryWANPortConnection.value,
            secondaryWAN:
                dualWANEthernetPortConnections.secondaryWANPortConnection.value,
            lans: dualWANEthernetPortConnections.lanPortConnections
                .map((e) => e.value)
                .toList(),
          );
          return state;
        }
      }
    }
    // 3. Not Dual WAN, get Ethernet Port Connection via getEthernetPortConnections
    final ethernetPortConnections = await repo
        .send(JNAPAction.getEthernetPortConnections, auth: true)
        .then<RouterEthernetPortConnections?>((result) {
      return RouterEthernetPortConnections.fromMap(result.output);
    }).onError((error, stackTrace) {
      logger.e('Error getting Ethernet Port Connections: $error, $stackTrace');
      return null;
    });
    if (ethernetPortConnections != null) {
      state = state.copyWith(
        isDualWANEnabled: false,
        primaryWAN: ethernetPortConnections.wanPortConnection,
        lans: ethernetPortConnections.lanPortConnections.map((e) => e).toList(),
      );
    }
    return state;
  }
}
