import 'dart:convert';

import 'package:linksys_moab/network/http/extension_requests/subscriptions_request.dart';
import 'package:linksys_moab/network/http/model/subscription_model.dart';
import 'package:linksys_moab/repository/security_context_loader_mixin.dart';

import '../../network/http/http_client.dart';

const String CHANNELIDENTIFIER = 'GOOGLE';
const String PRODUCTIDENTIFIER = 'linksys_secure';

class SubscriptionRepository with SCLoader {
  Future<MoabHttpClient> get _instance async =>
      MoabHttpClient.withCert(await get());

  Future<List<SubscriptionProductDetails>> queryProductList() async {
    return _instance
        .then((client) =>
            client.queryProductListings(CHANNELIDENTIFIER, PRODUCTIDENTIFIER))
        .then((response) => List<SubscriptionProductDetails>.from(json
            .decode(response.body)
            .map((item) => SubscriptionProductDetails.fromJson(item))));
  }

  Future<SubscriptionOrderResponse> createCloudOrders(
      String serialNumber,
      String productListingId,
      String purchaseToken
      ) {
    return _instance
        .then((client) => client.createCloudOrder(
            serialNumber, CHANNELIDENTIFIER, PRODUCTIDENTIFIER, productListingId, purchaseToken))
        .then((response) =>
            SubscriptionOrderResponse.fromJson(json.decode(response.body)));
  }

  Future<List<NetworkEntitlementResponse>> getNetworkEntitlement(
      String serialNumber) {
    return _instance
        .then((client) => client.getNetworkEntitlement(serialNumber))
        .then((response) => List<NetworkEntitlementResponse>.from(json
            .decode(response.body)
            .map((item) => NetworkEntitlementResponse.fromJson(item))));
  }
}
