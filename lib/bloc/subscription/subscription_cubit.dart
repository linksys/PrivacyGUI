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

  Future<void> loadingProducts() async {
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

  void buy(ProductDetails productDetails, String serialNumber) async {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    emit(state.copyWith(serialNumber: serialNumber));
    InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void updatePurchaseToken({String? purchaseToken = ''}) {
    emit(state.copyWith(purchaseToken: purchaseToken));
  }

  void queryProductsFromCloud() async {
    final productList = await _repo.queryProductList();
    emit(state.copyWith(subscriptionProductDetails: productList));
  }

  void createOrderToCloud() async {
    final orderResponse = await _repo.createCloudOrders(state.serialNumber!, state.subscriptionProductDetails!.first.id, state.purchaseToken!);
    emit(state.copyWith(subscriptionOrderResponse: orderResponse));
    getNetworkEntitlement(state.serialNumber!!);
  }

  void getNetworkEntitlement(String serialNumber) async {
    final entitlements = await _repo.getNetworkEntitlement(serialNumber);
    emit(state.copyWith(networkEntitlementResponse: entitlements));
  }

  @override
  void onChange(Change<SubscriptionState> change) {
    logger.d('subscription cubit state change : ${change.nextState}');
  }

  void onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          logger.e('subscription error : ${purchaseDetails.error!.toString()}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          logger.d('subscription cubit purchaseDetails : ${purchaseDetails.purchaseID}');
          _deliverProduct(purchaseDetails);
        }
      }
    });
  }

  void _deliverProduct(PurchaseDetails purchaseDetails) {
    emit(state.copyWith(purchaseToken: purchaseDetails.purchaseID));
    createOrderToCloud();
  }
}
