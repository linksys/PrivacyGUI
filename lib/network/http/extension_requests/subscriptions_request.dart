import 'dart:convert';

import 'package:http/http.dart';
import 'package:linksys_moab/network/http/http_client.dart';

import '../../../constants/cloud_const.dart';

extension MoabSubscriptionRequests on MoabHttpClient {
  Future<Response> queryProductListings(
      String channelIdentifier, String productIdentifier) async {
    final url = combineUrl(endpointSubscriptionQueryProductListings);
    final header = defaultHeader
      ..addAll({
        moabSiteIdKey: moabRetailSiteId,
        'channelIdentifier': channelIdentifier,
        'productIdentifier': productIdentifier
      });
    return this.get(Uri.parse(url), headers: header);
  }

  Future<Response> createCloudOrder(
      String serialNumber,
      String channelIdentifier,
      String productIdentifier,
      String purchaseToken) async {
    final url = combineUrl(endpointSubscriptionCreateCloudOrders);
    final header = defaultHeader..addAll({moabSiteIdKey: moabRetailSiteId});
    return this.post(Uri.parse(url),
        headers: header,
        body: jsonEncode({
          'serialNumber': serialNumber,
          'channelIdentifier': channelIdentifier,
          'productIdentifier': productIdentifier,
          'purchaseToken': purchaseToken
        }));
  }

  Future<Response> getNetworkEntitlement(String serialNumber) async {
    final url = combineUrl(endpointSubscriptionGetNetworkEntitlement);
    final header = defaultHeader
      ..addAll({
        moabSiteIdKey: moabRetailSiteId,
        'serialNumber': serialNumber,
        'includeInactive': 'false'
      });
    return this.get(Uri.parse(url), headers: header);
  }
}
