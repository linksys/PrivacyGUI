import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:linksys_moab/bloc/subscription/subscription_state.dart';
import 'package:linksys_moab/repository/subscription/subscription_repository.dart';
import 'package:linksys_moab/util/logger.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({required SubscriptionRepository repository})
      : _repo = repository,
        super(const SubscriptionState());
  final SubscriptionRepository _repo;

  void loadingProducts() async {
    const Set<String> _kIds = <String>{linksysSecurity};
    final ProductDetailsResponse response =
        await InAppPurchase.instance.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      logger.e('subscription doesn\'t found any product');
      return;
    }
    List<ProductDetails> products = response.productDetails;
    products.map((item) => logger.d('subscription product: ${item.id} + ${item.price} + ${item.description}')).toList();
    emit(state.copyWith(products: products));
    print('products: ${state.products?.first.id}');
  }

  void restoreProducts() async {
    InAppPurchase.instance.restorePurchases();
  }

  void buy(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void updatePurchaseToken({String? purchaseToken = ''}) {
    emit(state.copyWith(purchaseToken: purchaseToken));
  }

  void queryProductsFromCloud() async {
    final productList = await _repo.queryProductList();
    emit(state.copyWith(subscriptionProductDetails: productList));
  }

  void createOrderToCloud(String serialNumber, String purchaseToken) async {
    final orderResponse = await _repo.createCloudOrders(serialNumber, purchaseToken);
    emit(state.copyWith(subscriptionOrderResponse: orderResponse));
  }

  void getNetworkEntitlement(String serialNumber) async {
    final entitlements = await _repo.getNetworkEntitlement(serialNumber);
    emit(state.copyWith(networkEntitlementResponse: entitlements));
  }

  @override
  void onChange(Change<SubscriptionState> change) {
    logger.d('subscription cubit state change : ${change.nextState}');
  }
}
