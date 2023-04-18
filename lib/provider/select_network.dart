import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/network/cloud_network_model.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/repository/linksys_cloud_repository.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudNetworkService {
  WidgetRef ref;
  CloudNetworkService(this.ref);

  AsyncValue<SelectNetworkModel> watchSelectNetwork() {
    return ref.watch(selectNetworkNotifierProvider);
  }

  Future<void> refreshNetworks() async {
    await ref
        .read(selectNetworkNotifierProvider.notifier)
        .refreshCloudNetworks();
  }

  Future<void> saveNetwork(CloudNetworkModel network) async {
    await ref
        .read(selectNetworkNotifierProvider.notifier)
        .saveSelectedNetwork(network);
  }
}

final selectNetworkNotifierProvider =
    AsyncNotifierProvider<SelectNetworkNotifier, SelectNetworkModel>(() {
  return SelectNetworkNotifier();
});

class SelectNetworkNotifier extends AsyncNotifier<SelectNetworkModel> {
  @override
  Future<SelectNetworkModel> build() async {
    return _getModel();
  }

  Future<SelectNetworkModel> _getModel() async {
    final cloudRepository = ref.read(cloudRepositoryProvider);
    final routerRepository = ref.read(routerRepositoryProvider);
    final networkModels =
        await Future.wait((await cloudRepository.getNetworks()).map((e) async {
      bool isOnline = await routerRepository
          .send(
            JNAPAction.isAdminPasswordDefault,
            extraHeaders: {
              kJNAPNetworkId: e.network.networkId,
            },
            type: CommandType.remote,
          )
          .then((value) => value.result == 'OK')
          .onError((error, stackTrace) => false);
      return CloudNetworkModel(
        network: e.network,
        isOnline: isOnline,
      );
    }).toList());

    return SelectNetworkModel(networks: [
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
    await pref.setString(
        linksysPrefSelectedNetworkId, network.network.networkId);
  }

  Future<void> deleteNetworks() async {
    //TODO: Delete function
  }
}

@immutable
class SelectNetworkModel {
  final List<CloudNetworkModel> networks;
  Future<String?> get selectedNetworkId async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(linksysPrefSelectedNetworkId);
  }

  const SelectNetworkModel({
    this.networks = const [],
  });

  SelectNetworkModel copyWith({
    List<CloudNetworkModel>? networks,
  }) {
    return SelectNetworkModel(
      networks: networks ?? this.networks,
    );
  }
}
