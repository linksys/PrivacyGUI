import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../network/http/model/subscription_model.dart';

const linksysSecurity = 'linksys_secure';

class SubscriptionState extends Equatable {
  final List<ProductDetails>? products;
  final String? purchaseToken;
  final List<SubscriptionProductDetails>? subscriptionProductDetails;
  final SubscriptionOrderResponse? subscriptionOrderResponse;
  final List<NetworkEntitlementResponse>? networkEntitlementResponse;
  final String? serialNumber;

  const SubscriptionState(
      {this.products,
      this.purchaseToken,
      this.subscriptionProductDetails,
      this.subscriptionOrderResponse,
      this.networkEntitlementResponse,
      this.serialNumber});

  SubscriptionState copyWith(
      {List<ProductDetails>? products,
      String? purchaseToken,
      List<SubscriptionProductDetails>? subscriptionProductDetails,
      SubscriptionOrderResponse? subscriptionOrderResponse,
      List<NetworkEntitlementResponse>? networkEntitlementResponse,
      String? serialNumber}) {
    return SubscriptionState(
        products: products ?? this.products,
        purchaseToken: purchaseToken ?? this.purchaseToken,
        subscriptionProductDetails:
            subscriptionProductDetails ?? this.subscriptionProductDetails,
        subscriptionOrderResponse:
            subscriptionOrderResponse ?? this.subscriptionOrderResponse,
        networkEntitlementResponse:
            networkEntitlementResponse ?? this.networkEntitlementResponse,
        serialNumber: serialNumber ?? this.serialNumber);
  }

  @override
  List<Object?> get props => [
        products,
        purchaseToken,
        subscriptionProductDetails,
        subscriptionOrderResponse,
        networkEntitlementResponse,
        serialNumber
      ];
}
