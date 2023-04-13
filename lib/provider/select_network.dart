import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/network/cloud_network_model.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/model/router/network.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/provider/low_level_provider.dart';
import 'package:linksys_moab/repository/linksys_cloud_repository.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

final selectNetworkRepositoryProvider = Provider(
  (ref) => SelectNetworkRepository(
    cloudRepository: ref.watch(cloudRepositoryProvider),
    routerRepository: ref.watch(routerRepositoryProvider),
  ),
);

class SelectNetworkRepository {
  LinksysCloudRepository cloudRepository;
  RouterRepository routerRepository;

  SelectNetworkRepository({
    required this.cloudRepository,
    required this.routerRepository,
  });

  Future<SelectNetworkModel> getUserNetworks() async {
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
      return CloudNetworkModel(network: e.network, isOnline: isOnline);
    }).toList());
    return SelectNetworkModel(
      networks: [
        ...networkModels.where((element) => element.isOnline),
        ...networkModels.where((element) => !element.isOnline),
      ],
      selected: null,
    );
  }
}

class SelectNetworkModel {
  final List<CloudNetworkModel> networks;
  final MoabNetwork? selected;

  SelectNetworkModel({
    this.networks = const [],
    this.selected,
  });

  SelectNetworkModel copyWith({
    List<CloudNetworkModel>? networks,
    MoabNetwork? selected,
  }) {
    return SelectNetworkModel(
      networks: networks ?? this.networks,
      selected: selected ?? this.selected,
    );
  }
}
