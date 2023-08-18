import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/bloc/network/cloud_network_model.dart';
import 'package:linksys_app/provider/select_network_provider.dart';

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
