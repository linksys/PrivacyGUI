import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/core/utils/nodes.dart';
import 'package:linksys_app/provider/network/cloud_network_model.dart';
import 'package:linksys_app/provider/select_network/check_network_online_provider.dart';
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

    return SelectNetworkState(networks: [
      ...networkModels.where((element) => element.isOnline),
      ...networkModels.where((element) => !element.isOnline),
    ]);
  }

  Future<void> refreshCloudNetworks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_getModel);
    ref.read(checkNetworkOnlineProvider.notifier).checkNetworkOnline();
  }

  Future<void> saveSelectedNetwork(CloudNetworkModel network) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(pSelectedNetworkId, network.network.networkId);
  }

  Future<void> deleteNetworks() async {
    //TODO: Delete function
  }

  void updateCloudNetworkModel(CloudNetworkModel model) {
    var networks = state.value?.networks ?? [];
    if (model.isOnline == true) {
      final index = networks.indexWhere(
          (element) => element.network.networkId == model.network.networkId);
      final updateModel = networks[index].copyWith(isOnline: model.isOnline);
      networks[index] = updateModel;
      // Update state
      state = AsyncValue.data(SelectNetworkState(networks: [
        ...networks.where((element) => element.isOnline),
        ...networks.where((element) => !element.isOnline),
      ]));
    }
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
