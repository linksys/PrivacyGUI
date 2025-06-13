import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/sse/modular_apps_sse/modular_apps_sse_provider.dart';
import 'package:privacy_gui/page/modular_apps/models/modular_app_data.dart';
import 'package:privacy_gui/page/modular_apps/models/modular_app_type.dart';
import 'package:privacy_gui/page/modular_apps/provider/modular_app_list_state.dart';

final modularAppListProvider =
    NotifierProvider<ModularAppListNotifier, ModularAppListState>(
  () => ModularAppListNotifier(),
);

class ModularAppListNotifier extends Notifier<ModularAppListState> {
  @override
  ModularAppListState build() {
    final sseState = ref.watch(sseConnectionProvider);
    // if not connected, return empty state
    if (!sseState.isConnected) {
      return ModularAppListState();
    }
    // parse the initial or last file_changed event packet
    final packets = sseState.packets;
    final lastPacket = packets.lastWhereOrNull(
        (p) => p.eventType == 'initial' || p.eventType == 'file_changed');
    // if no initial or file_changed event, return empty state
    if (lastPacket == null) {
      return ModularAppListState();
    }
    // parse the json from data
    // need to remove --- BEGIN FILE CONTENT --- and --- END FILE CONTENT ---
    final data = json.decode(lastPacket.data
        .replaceAll('--- BEGIN FILE CONTENT ---', '')
        .replaceAll('--- END FILE CONTENT ---', ''));

    final version = data['api']['version'];
    final lastUpdated = lastPacket.timestamp;
    final defaultApps = List.from(data['apps'])
        .map(
            (e) => ModularAppData.fromMap(e).copyWith(type: ModularAppType.app))
        .toList();
    final userApps = List.from(data['userApps'])
        .map((e) =>
            ModularAppData.fromMap(e).copyWith(type: ModularAppType.user))
        .toList();
    final premiumApps = List.from(data['premiumApps'])
        .map((e) =>
            ModularAppData.fromMap(e).copyWith(type: ModularAppType.premium))
        .toList();

    return ModularAppListState(
        version: version,
        lastUpdated: lastUpdated,
        apps: [...defaultApps, ...userApps, ...premiumApps]);
  }
}