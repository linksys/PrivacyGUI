import 'package:flutter_riverpod/flutter_riverpod.dart';
// removed unused import
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

final networkAvailabilityServiceProvider =
    Provider<NetworkAvailabilityService>((ref) {
  final routerRepository = ref.watch(routerRepositoryProvider);
  return NetworkAvailabilityService(routerRepository);
});

class NetworkAvailabilityService {
  final RouterRepository _routerRepository;

  NetworkAvailabilityService(this._routerRepository);

  /// Checks if the network with [networkId] is online by sending a remote query.
  Future<bool> checkNetworkOnline(String networkId) async {
    return _routerRepository
        .send(JNAPAction.isAdminPasswordDefault,
            extraHeaders: {
              kJNAPNetworkId: networkId,
            },
            type: CommandType.remote,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache)
        .then((value) => value.result == 'OK')
        .onError((error, stackTrace) => false);
  }
}
