import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/constants/jnap_const.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/nodes.dart';
import 'package:linksys_app/provider/network/cloud_network_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final selectNetworkProvider =
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
    // For now, we only care about node routers
    final networkModels = await Future.wait(
        (await cloudRepository.getNetworks())
            .where((element) => isNodeModel(
                modelNumber: element.network.routerModelNumber,
                hardwareVersion: element.network.routerHardwareVersion))
            .map((e) async {
      return CloudNetworkModel(
        network: e.network,
        isOnline: false,
      );
    }).toList());

    return SelectNetworkState(
      networks: [
        ...networkModels.where((element) => element.isOnline),
        ...networkModels.where((element) => !element.isOnline),
      ],
      isCheckingOnline: true,
    );
  }

  Future<SelectNetworkState> _checkNetworkOnline(
      CloudNetworkModel network) async {
    final routerRepository = ref.read(routerRepositoryProvider);
    bool isOnline = await routerRepository
        .send(JNAPAction.isAdminPasswordDefault,
            extraHeaders: {
              kJNAPNetworkId: network.network.networkId,
            },
            type: CommandType.remote,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache)
        .then((value) => value.result == 'OK')
        .onError((error, stackTrace) => false);
    final cloudNetworkModel = CloudNetworkModel(
      network: network.network,
      isOnline: isOnline,
    );

    return _updateCloudNetworkModel(cloudNetworkModel);
  }

  Future<void> refreshCloudNetworks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_getModel);
    final networks = state.value?.networks ?? [];
    final finishList = [];
    for (final network in networks) {
      _checkNetworkOnline(network).then((value) {
        finishList.add(network);
        state = AsyncValue.data(value.copyWith(
            isCheckingOnline: finishList.length != networks.length));
      });
    }
  }

  Future<void> saveSelectedNetwork(CloudNetworkModel network) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(pSelectedNetworkId, network.network.networkId);
  }

  Future<void> deleteNetworks() async {
    //TODO: Delete function
  }

  Future<SelectNetworkState> _updateCloudNetworkModel(
      CloudNetworkModel model) async {
    var networks = state.value?.networks ?? [];
    if (model.isOnline == true) {
      final index = networks.indexWhere(
          (element) => element.network.networkId == model.network.networkId);
      final updateModel = networks[index].copyWith(isOnline: model.isOnline);
      networks[index] = updateModel;
      // Update state
      return SelectNetworkState(networks: [
        ...networks.where((element) => element.isOnline),
        ...networks.where((element) => !element.isOnline),
      ]);
    } else {
      return SelectNetworkState(networks: networks);
    }
  }
}

@immutable
class SelectNetworkState {
  final List<CloudNetworkModel> networks;
  final bool isCheckingOnline;

  Future<String?> get selectedNetworkId async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(pSelectedNetworkId);
  }

  const SelectNetworkState({
    this.networks = const [],
    this.isCheckingOnline = false,
  });

  SelectNetworkState copyWith({
    List<CloudNetworkModel>? networks,
    bool? isCheckingOnline,
  }) {
    return SelectNetworkState(
      networks: networks ?? this.networks,
      isCheckingOnline: isCheckingOnline ?? this.isCheckingOnline,
    );
  }
}
