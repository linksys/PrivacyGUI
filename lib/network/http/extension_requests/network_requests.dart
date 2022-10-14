import 'dart:convert';

import 'package:http/http.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import '../../../constants/_constants.dart';
import '../http_client.dart';

extension MoabNetworkRequests on MoabHttpClient {
  Future<Response> getNetworks({required String accountId}) async {
    final url = await combineUrl(endpointGetNetworks, args: {varAccountId: accountId});
    final header = defaultHeader..addAll({moabSiteIdKey: moabRetailSiteId});
    return this.get(Uri.parse(url), headers: header);
  }

  Future<Response> getNetwork({required String accountId, required String networkId}) async {
    final url = await combineUrl(endpointGetNetworkById, args: {varAccountId: accountId, varNetworkId: networkId});
    final header = defaultHeader..addAll({moabSiteIdKey: moabRetailSiteId});
    return this.get(Uri.parse(url), headers: header);
  }
}
