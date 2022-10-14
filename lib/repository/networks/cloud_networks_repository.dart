import 'dart:convert';

import 'package:linksys_moab/network/http/extension_requests/extension_requests.dart';
import 'package:linksys_moab/network/http/extension_requests/network_requests.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_account_info.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/network/http/model/cloud_network.dart';
import 'package:linksys_moab/repository/model/dummy_model.dart';
import 'package:linksys_moab/repository/security_context_loader_mixin.dart';

class CloudNetworksRepository with SCLoader {
  Future<MoabHttpClient> get _instance async =>
      MoabHttpClient.withCert(await get());

  Future<List<CloudNetwork>> getNetworks({required String accountId}) async {
    return _instance
        .then((client) => client.getNetworks(accountId: accountId))
        .then((response) => List.from(List.from(json.decode(response.body))
            .map((e) => CloudNetwork.fromJson(e))
            .toList()));
  }

  Future<DummyModel> getNetwork(
      {required String accountId, required String networkId}) {
    return _instance
        .then((client) =>
            client.getNetwork(accountId: accountId, networkId: networkId))
        .then((response) => json.decode(response.body));
  }
}
