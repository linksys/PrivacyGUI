import 'dart:convert';
import 'dart:io';

import 'package:linksys_moab/network/http/extension_requests/subscriptions_request.dart';
import 'package:linksys_moab/network/http/model/subscription_model.dart';
import 'package:linksys_moab/repository/security_context_loader_mixin.dart';

import '../../network/http/http_client.dart';

const String GOOGLE_CHANNELIDENTIFIER = 'GOOGLE';
const String GOOGLE_PRODUCTIDENTIFIER = 'linksys_secure';
const String APPLE_CHANNLEINDENTIFIER = 'APPLE';
const String APPLE_PRODUCTIDENTIFIER = 'test_sub_annually';

class SubscriptionRepository with SCLoader {
  Future<MoabHttpClient> get _instance async =>
      MoabHttpClient.withCert(await get());

  Future<List<SubscriptionProductDetails>> queryProductList() async {
    return _instance
        .then((client) => Platform.isIOS
            ? client.queryProductListings(
                APPLE_CHANNLEINDENTIFIER, APPLE_PRODUCTIDENTIFIER)
            : client.queryProductListings(
                GOOGLE_CHANNELIDENTIFIER, GOOGLE_PRODUCTIDENTIFIER))
        .then((response) => List<SubscriptionProductDetails>.from(json
            .decode(response.body)
            .map((item) => SubscriptionProductDetails.fromJson(item))));
  }

  Future<SubscriptionOrderResponse> createCloudOrders(
      String serialNumber, String productListingId, String purchaseToken) {
    return _instance
        .then((client) => Platform.isIOS
            ? client.createCloudOrder(serialNumber, APPLE_CHANNLEINDENTIFIER,
                APPLE_PRODUCTIDENTIFIER, productListingId, purchaseToken)
            : client.createCloudOrder(serialNumber, GOOGLE_CHANNELIDENTIFIER,
                GOOGLE_PRODUCTIDENTIFIER, productListingId, purchaseToken))
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
