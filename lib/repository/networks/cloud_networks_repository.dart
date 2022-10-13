import 'dart:convert';

import 'package:linksys_moab/network/http/extension_requests/extension_requests.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_account_info.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/repository/model/dummy_model.dart';
import 'package:linksys_moab/repository/security_context_loader_mixin.dart';

class CloudNetworksRepository with SCLoader {
  Future<MoabHttpClient> get _instance async =>
      MoabHttpClient.withCert(await get());

  Future<DummyModel> getNetworks() async {
    return _instance.then((client) => client.getAccountSelf()).then(
        (response) => json.decode(response.body));
  }
}
