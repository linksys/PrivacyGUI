import 'dart:core';

import 'package:equatable/equatable.dart';

///{
///     "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
///     "channel": {
///       "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
///       "family": "GOOGLE",
///       "identifier": "string",
///       "name": "string",
///       "flow": "MOCK",
///       "publicFlag": true,
///       "autoRenewalSupported": true
///     },
///     "product": {
///       "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
///       "identifier": "string",
///       "name": "string",
///       "type": "NON_CONSUMABLE",
///       "publicFlag": true
///     },
///     "plan": {
///       "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
///       "identifier": "string",
///       "name": "string",
///       "effectiveDuration": "PT720H",
///       "beginsAtDelta": "PT0S",
///       "serviceEndsAtDelta": "PT72H",
///       "expiresAtDelta": "PT720H",
///       "publicFlag": true
///     },
///     "provider": {
///       "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
///       "identifier": "string",
///       "name": "string",
///       "active": true
///     },
///     "publicFlag": true
///   }
class SubscriptionProductDetails extends Equatable {
  final String id;
  final SubscriptionChannel channel;
  final SubscriptionProduct product;
  final SubscriptionPlan plan;
  final SubscriptionProvider provider;
  final bool publicFlag;

  const SubscriptionProductDetails(
      {required this.id,
      required this.channel,
      required this.product,
      required this.plan,
      required this.provider,
      required this.publicFlag});

  factory SubscriptionProductDetails.fromJson(Map<String, dynamic> json) {
    return SubscriptionProductDetails(
        id: json['id'],
        channel: SubscriptionChannel.fromJson(json['channel']),
        product: SubscriptionProduct.fromJson(json['product']),
        plan: SubscriptionPlan.fromJson(json['plan']),
        provider: SubscriptionProvider.fromJson(json['provider']),
        publicFlag: json['publicFlag']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel': channel.toJson(),
      'product': product.toJson(),
      'plan': plan.toJson(),
      'provider': provider.toJson(),
      'publicFlag': publicFlag
    };
  }

  @override
  List<Object> get props => [id, channel, product, plan, provider, publicFlag];
}

class SubscriptionChannel extends Equatable {
  final String id;
  final String family;
  final String identifier;
  final String name;
  final String flow;
  final bool publicFlag;
  final bool autoRenewalSupported;

  const SubscriptionChannel(
      {required this.id,
      required this.family,
      required this.identifier,
      required this.name,
      required this.flow,
      required this.publicFlag,
      required this.autoRenewalSupported});

  factory SubscriptionChannel.fromJson(Map<String, dynamic> json) {
    return SubscriptionChannel(
        id: json['id'],
        family: json['family'],
        identifier: json['identifier'],
        name: json['name'],
        flow: json['flow'],
        publicFlag: json['publicFlag'],
        autoRenewalSupported: json['autoRenewalSupported']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family': family,
      'identifier': identifier,
      'name': name,
      'flow': flow,
      'publicFlag': publicFlag,
      'autoRenewalSupported': autoRenewalSupported
    };
  }

  @override
  List<Object> get props =>
      [id, family, identifier, name, flow, publicFlag, autoRenewalSupported];
}

class SubscriptionProduct extends Equatable {
  final String id;
  final String identifier;
  final String name;
  final String type;
  final bool publicFlag;

  const SubscriptionProduct(
      {required this.id,
      required this.identifier,
      required this.name,
      required this.type,
      required this.publicFlag});

  factory SubscriptionProduct.fromJson(Map<String, dynamic> json) {
    return SubscriptionProduct(
        id: json['id'],
        identifier: json['identifier'],
        name: json['name'],
        type: json['type'],
        publicFlag: json['publicFlag']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identifier': identifier,
      'name': name,
      'type': type,
      'publicFlag': publicFlag
    };
  }

  @override
  List<Object> get props => [id, identifier, name, type, publicFlag];
}

class SubscriptionPlan extends Equatable {
  final String id;
  final String identifier;
  final String name;
  final String effectiveDuration;
  final String beginsAtDelta;
  final String serviceEndsAtDelta;
  final String expiresAtDelta;
  final bool publicFlag;

  const SubscriptionPlan(
      {required this.id,
      required this.identifier,
      required this.name,
      required this.effectiveDuration,
      required this.beginsAtDelta,
      required this.serviceEndsAtDelta,
      required this.expiresAtDelta,
      required this.publicFlag});

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
        id: json['id'],
        identifier: json['identifier'],
        name: json['name'],
        effectiveDuration: json['effectiveDuration'],
        beginsAtDelta: json['beginsAtDelta'],
        serviceEndsAtDelta: json['serviceEndsAtDelta'],
        expiresAtDelta: json['expiresAtDelta'],
        publicFlag: json['publicFlag']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identifier': identifier,
      'name': name,
      'effectiveDuration': effectiveDuration,
      'beginsAtDelta': beginsAtDelta,
      'serviceEndsAtDelta': serviceEndsAtDelta,
      'expiresAtDelta': expiresAtDelta,
      'publicFlag': publicFlag
    };
  }

  @override
  List<Object> get props => [
        id,
        identifier,
        name,
        effectiveDuration,
        beginsAtDelta,
        serviceEndsAtDelta,
        expiresAtDelta,
        publicFlag
      ];
}

class SubscriptionProvider extends Equatable {
  final String id;
  final String identifier;
  final String name;
  final bool active;

  const SubscriptionProvider(
      {required this.id,
      required this.identifier,
      required this.name,
      required this.active});

  factory SubscriptionProvider.fromJson(Map<String, dynamic> json) {
    return SubscriptionProvider(
        id: json['id'],
        identifier: json['identifier'],
        name: json['name'],
        active: json['active']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'identifier': identifier, 'name': name, 'active': active};
  }

  @override
  List<Object> get props => [id, identifier, name, active];
}

class SubscriptionOrderResponse extends Equatable {
  final String id;
  final String serialNumber;
  final String productId;
  final String channelId;
  final String status;
  final bool purchaseInProgress;
  final String planId;
  final String providerId;
  final ProviderOrder providerOrder;
  final String purchasedAt;
  final String verifiedAt;
  final String providerVerifiedAt;
  final String cancelledAt;
  final String startTime;
  final String renewTime;
  final String endTime;
  final String serviceEndTime;
  final String expireTime;
  final bool active;
  final String linksysPurchaseId;

  const SubscriptionOrderResponse(
      {required this.id,
      required this.serialNumber,
      required this.productId,
      required this.channelId,
      required this.status,
      required this.purchaseInProgress,
      required this.planId,
      required this.providerId,
      required this.providerOrder,
      required this.purchasedAt,
      required this.verifiedAt,
      required this.providerVerifiedAt,
      required this.cancelledAt,
      required this.startTime,
      required this.renewTime,
      required this.endTime,
      required this.serviceEndTime,
      required this.expireTime,
      required this.active,
      required this.linksysPurchaseId});

  factory SubscriptionOrderResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionOrderResponse(
        id: json['id'],
        serialNumber: json['serialNumber'],
        productId: json['productId'],
        channelId: json['channelId'],
        status: json['status'],
        purchaseInProgress: json['purchaseInProgress'],
        planId: json['planId'],
        providerId: json['providerId'],
        providerOrder: json['providerOrder'],
        purchasedAt: json['purchasedAt'],
        verifiedAt: json['verifiedAt'],
        providerVerifiedAt: json['providerVerifiedAt'],
        cancelledAt: json['cancelledAt'],
        startTime: json['startTime'],
        renewTime: json['renewTime'],
        endTime: json['endTime'],
        serviceEndTime: json['serviceEndTime'],
        expireTime: json['expireTime'],
        active: json['active'],
        linksysPurchaseId: json['linksysPurchaseId']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'productId': productId,
      'channelId': channelId,
      'status': status,
      'purchaseInProgress': purchaseInProgress,
      'planId': planId,
      'providerId': providerId,
      'providerOrder': providerOrder,
      'purchasedAt': purchasedAt,
      'verifiedAt': verifiedAt,
      'providerVerifiedAt': providerVerifiedAt,
      'cancelledAt': cancelledAt,
      'startTime': startTime,
      'renewTime': renewTime,
      'endTime': endTime,
      'serviceEndTime': serviceEndTime,
      'expireTime': expireTime,
      'active': active,
      'linksysPurchaseId': linksysPurchaseId
    };
  }

  @override
  List<Object> get props => [
        id,
        serialNumber,
        productId,
        channelId,
        status,
        purchaseInProgress,
        planId,
        providerId,
        providerOrder,
        purchasedAt,
        verifiedAt,
        providerVerifiedAt,
        cancelledAt,
        startTime,
        renewTime,
        endTime,
        serviceEndTime,
        expireTime,
        active,
        linksysPurchaseId
      ];
}

class ProviderOrder extends Equatable {
  final String id;
  final String orderId;
  final String status;
  final bool active;

  const ProviderOrder(
      {required this.id,
      required this.orderId,
      required this.status,
      required this.active});

  factory ProviderOrder.fromJson(Map<String, dynamic> json) {
    return ProviderOrder(
        id: json['id'],
        orderId: json['orderId'],
        status: json['status'],
        active: json['active']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'orderId': orderId, 'status': status, 'active': active};
  }

  @override
  List<Object> get props => [id, orderId, status, active];
}

class NetworkEntitlementResponse extends Equatable {
  final String siteId;
  final String serialNumber;
  final SubscriptionProduct product;
  final SubscriptionChannel channel;
  final SubscriptionPlan plan;
  final SubscriptionProvider provider;
  final String status;
  final bool active;
  final SubscriptionOrderResponse order;
  final ProviderOrder providerOrder;
  final String startTime;
  final String renewTime;
  final String endTime;
  final String serviceEndTime;
  final String expireTime;

  const NetworkEntitlementResponse({
    required this.siteId,
    required this.serialNumber,
    required this.product,
    required this.channel,
    required this.plan,
    required this.provider,
    required this.status,
    required this.active,
    required this.order,
    required this.providerOrder,
    required this.startTime,
    required this.renewTime,
    required this.endTime,
    required this.serviceEndTime,
    required this.expireTime,
  });

  @override
  String toString() {
    return 'NetworkEntitlementResponse{' +
        ' siteId: $siteId,' +
        ' serialNumber: $serialNumber,' +
        ' product: ${product.toString()},' +
        ' channel: ${channel.toString()},' +
        ' plan: ${plan.toString()},' +
        ' provider: ${provider.toString()},' +
        ' status: $status,' +
        ' active: $active,' +
        ' order: ${order.toString()},' +
        ' providerOrder: ${providerOrder.toString()},' +
        ' startTime: $startTime,' +
        ' renewTime: $renewTime,' +
        ' endTime: $endTime,' +
        ' serviceEndTime: $serviceEndTime,' +
        ' expireTime: $expireTime,' +
        '}';
  }

  Map<String, dynamic> toJson() {
    return {
      'siteId': siteId,
      'serialNumber': serialNumber,
      'product': product.toJson(),
      'channel': channel.toJson(),
      'plan': plan.toJson(),
      'provider': provider.toJson(),
      'status': status,
      'active': active,
      'order': order.toJson(),
      'providerOrder': providerOrder.toJson(),
      'startTime': startTime,
      'renewTime': renewTime,
      'endTime': endTime,
      'serviceEndTime': serviceEndTime,
      'expireTime': expireTime,
    };
  }

  factory NetworkEntitlementResponse.fromJson(Map<String, dynamic> json) {
    return NetworkEntitlementResponse(
      siteId: json['siteId'],
      serialNumber: json['serialNumber'],
      product: SubscriptionProduct.fromJson(json['product']),
      channel: SubscriptionChannel.fromJson(json['channel']),
      plan: SubscriptionPlan.fromJson(json['plan']),
      provider: SubscriptionProvider.fromJson(json['provider']),
      status: json['status'],
      active: json['active'],
      order: SubscriptionOrderResponse.fromJson(json['order']),
      providerOrder: ProviderOrder.fromJson(json['providerOrder']),
      startTime: json['startTime'],
      renewTime: json['renewTime'],
      endTime: json['endTime'],
      serviceEndTime: json['serviceEndTime'],
      expireTime: json['expireTime'],
    );
  }

  @override
  List<Object> get props => [
    siteId,
    serialNumber,
    product,
    channel,
    plan,
    provider,
    status,
    active,
    order,
    providerOrder,
    startTime,
    renewTime,
    endTime,
    serviceEndTime,
    expireTime
  ];
}
