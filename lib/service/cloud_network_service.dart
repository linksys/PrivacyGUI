import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/provider/network/cloud_network_model.dart';
import 'package:linksys_app/provider/select_network/select_network_provider.dart';

class CloudNetworkService {
  WidgetRef ref;
  CloudNetworkService(this.ref);

  AsyncValue<SelectNetworkState> watchSelectNetwork() {
    return ref.watch(selectNetworkProvider);
  }

  Future<void> refreshNetworks() async {
    await ref
        .read(selectNetworkProvider.notifier)
        .refreshCloudNetworks();
  }

  Future<void> saveNetwork(CloudNetworkModel network) async {
    await ref
        .read(selectNetworkProvider.notifier)
        .saveSelectedNetwork(network);
  }
}
