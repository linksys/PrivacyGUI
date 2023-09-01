import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/constants/jnap_const.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/nodes.dart';
import 'package:linksys_app/provider/network/cloud_network_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final selectNetworkNotifierProvider =
    AsyncNotifierProvider<SelectNetworkNotifier, SelectNetworkState>(() {
  return SelectNetworkNotifier();
});

class SelectNetworkNotifier extends AsyncNotifier<SelectNetworkState> {
  @override
  Future<SelectNetworkState> build() async {
    return Future.value(const SelectNetworkState());
  }

  Future<SelectNetworkState> _getModel() async {
    final cloudRepository = ref.read(cloudRepositoryProvider);
    final routerRepository = ref.read(routerRepositoryProvider);
    // For now, we only care about node routers
    final networkModels = await Future.wait(
        (await cloudRepository.getNetworks())
            .where((element) => isNodeModel(
                modelNumber: element.network.routerModelNumber,
                hardwareVersion: element.network.routerHardwareVersion))
            .map((e) async {
      bool isOnline = await routerRepository
          .send(JNAPAction.isAdminPasswordDefault,
              extraHeaders: {
                kJNAPNetworkId: e.network.networkId,
              },
              type: CommandType.remote,
              force: true,
              cacheLevel: CacheLevel.noCache)
          .then((value) => value.result == 'OK')
          .onError((error, stackTrace) => false);
      return CloudNetworkModel(
        network: e.network,
        isOnline: isOnline,
      );
    }).toList());

    return SelectNetworkState(networks: [
      ...networkModels.where((element) => element.isOnline),
      ...networkModels.where((element) => !element.isOnline),
    ]);
  }

  Future<void> refreshCloudNetworks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_getModel);
  }

  Future<void> saveSelectedNetwork(CloudNetworkModel network) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(pSelectedNetworkId, network.network.networkId);
  }

  Future<void> deleteNetworks() async {
    //TODO: Delete function
  }
}

@immutable
class SelectNetworkState {
  final List<CloudNetworkModel> networks;
  Future<String?> get selectedNetworkId async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(pSelectedNetworkId);
  }

  const SelectNetworkState({
    this.networks = const [],
  });

  SelectNetworkState copyWith({
    List<CloudNetworkModel>? networks,
  }) {
    return SelectNetworkState(
      networks: networks ?? this.networks,
    );
  }
}
