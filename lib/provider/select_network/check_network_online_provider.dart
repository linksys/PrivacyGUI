import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/constants/jnap_const.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/network/cloud_network_model.dart';
import 'package:linksys_app/provider/select_network/select_network_provider.dart';

final checkNetworkOnlineProvider =
    AsyncNotifierProvider<CheckNetworkOnlineNotifier, CheckNetworkOnlineState>(
        () {
  return CheckNetworkOnlineNotifier();
});

class CheckNetworkOnlineNotifier
    extends AsyncNotifier<CheckNetworkOnlineState> {
  @override
  Future<CheckNetworkOnlineState> build() async {
    return Future.value(const CheckNetworkOnlineState());
  }

  Future<CheckNetworkOnlineState> _checkNetworkOnline() async {
    final routerRepository = ref.read(routerRepositoryProvider);
    final networkModels = ref.read(selectNetworkProvider).value?.networks ?? [];
    // For now, we only care about node routers
    await Future.wait(networkModels.map((e) async {
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
      final cloudNetworkModel = CloudNetworkModel(
        network: e.network,
        isOnline: isOnline,
      );

      ref.read(selectNetworkProvider.notifier).updateCloudNetworkModel(cloudNetworkModel);
      return cloudNetworkModel;
    }));

    return const CheckNetworkOnlineState();
  }

  Future<void> checkNetworkOnline() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_checkNetworkOnline);
  }
}

@immutable
class CheckNetworkOnlineState {
  const CheckNetworkOnlineState();
  // CheckNetworkOnlineState copyWith({
  //   List<CloudNetworkModel>? networks,
  // }) {
  //   return CheckNetworkOnlineState(
  //     networks: networks ?? this.networks,
  //   );
  // }
}
