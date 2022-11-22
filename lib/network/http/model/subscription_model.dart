import 'dart:core';
import 'dart:ffi';

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

class SoftwarePackage extends Equatable {
  final String id;
  final String identifier;
  final String name;
  final bool active;

  @override
  List<Object?> get props => [id, identifier, name, active];

  const SoftwarePackage({
    required this.id,
    required this.identifier,
    required this.name,
    required this.active,
  });

  @override
  String toString() {
    return 'SoftwarePackage{' +
        ' id: $id,' +
        ' identifier: $identifier,' +
        ' name: $name,' +
        ' active: $active,' +
        '}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identifier': identifier,
      'name': name,
      'active': active,
    };
  }

  factory SoftwarePackage.fromJson(Map<String, dynamic> json) {
    return SoftwarePackage(
      id: json['id'],
      identifier: json['identifier'],
      name: json['name'],
      active: json['active'],
    );
  }
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
  final String accountId;
  final String productId;
  final SubscriptionProduct product;
  final String channelId;
  final SubscriptionChannel channel;
  final String status;
  final String planId;
  final SubscriptionPlan plan;
  final String providerId;
  final ProviderOrder? providerOrder;
  final String purchasedAt;
  final String? verifiedAt;
  final String? startTime;
  final String? renewTime;
  final String? endTime;
  final String? serviceEndTime;
  final String? expireTime;
  final String? lastCheckedAt;

  const SubscriptionOrderResponse(
      {required this.id,
      required this.serialNumber,
      required this.accountId,
      required this.productId,
      required this.product,
      required this.channelId,
      required this.channel,
      required this.status,
      required this.planId,
      required this.plan,
      required this.providerId,
      required this.providerOrder,
      required this.purchasedAt,
      required this.verifiedAt,
      required this.startTime,
      required this.renewTime,
      required this.endTime,
      required this.serviceEndTime,
      required this.expireTime,
      required this.lastCheckedAt});

  factory SubscriptionOrderResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionOrderResponse(
      id: json['id'],
      serialNumber: json['serialNumber'],
      accountId: json['accountId'],
      productId: json['productId'],
      product: SubscriptionProduct.fromJson(json['product']),
      channelId: json['channelId'],
      channel: SubscriptionChannel.fromJson(json['channel']),
      status: json['status'],
      planId: json['planId'],
      plan: SubscriptionPlan.fromJson(json['plan']),
      providerId: json['providerId'],
      providerOrder: json['providerOrder'] != null ? ProviderOrder.fromJson(json['providerOrder']) : null,
      purchasedAt: json['purchasedAt'],
      verifiedAt: json['verifiedAt'],
      startTime: json['startTime'],
      renewTime: json['renewTime'],
      endTime: json['endTime'],
      serviceEndTime: json['serviceEndTime'],
      expireTime: json['expireTime'],
      lastCheckedAt: json['lastCheckedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'accountId': accountId,
      'productId': productId,
      'product': product,
      'channelId': channelId,
      'channel': channel,
      'status': status,
      'planId': planId,
      'plan': plan,
      'providerId': providerId,
      'providerOrder': providerOrder,
      'purchasedAt': purchasedAt,
      'verifiedAt': verifiedAt,
      'startTime': startTime,
      'renewTime': renewTime,
      'endTime': endTime,
      'serviceEndTime': serviceEndTime,
      'expireTime': expireTime,
      'lastCheckedAt': lastCheckedAt,
    }..removeWhere((key, value) => value == null);
  }

  @override
  List<Object?> get props => [
        id,
        serialNumber,
        accountId,
        productId,
        product,
        channelId,
        channel,
        status,
        planId,
        plan,
        providerId,
        providerOrder,
        purchasedAt,
        verifiedAt,
        startTime,
        renewTime,
        endTime,
        serviceEndTime,
        expireTime,
        lastCheckedAt,
      ];
}

class ProviderOrder extends Equatable {
  final String id;
  final String orderId;
  final String status;
  final String expireTime;

  const ProviderOrder(
      {required this.id,
      required this.orderId,
      required this.status,
      required this.expireTime});

  factory ProviderOrder.fromJson(Map<String, dynamic> json) {
    return ProviderOrder(
        id: json['id'],
        orderId: json['orderId'],
        status: json['status'],
        expireTime: json['expireTime']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'status': status,
      'expireTime': expireTime
    };
  }

  @override
  List<Object> get props => [id, orderId, status, expireTime];
}

class NetworkEntitlementResponse extends Equatable {
  final String id;
  final String siteId;
  final String serialNumber;
  final SubscriptionChannel channel;
  final SubscriptionProduct product;
  final SubscriptionPlan plan;
  final SubscriptionProvider provider;
  final SoftwarePackage softwarePackage;
  final String? softwarePackageStatus;
  final String status;
  final SubscriptionOrderResponse order;
  final ProviderOrder? providerOrder;
  final String? startTime;
  final String? renewTime;
  final String? endTime;
  final String? serviceEndTime;
  final String? expireTime;

  const NetworkEntitlementResponse({
    required this.id,
    required this.siteId,
    required this.serialNumber,
    required this.channel,
    required this.product,
    required this.plan,
    required this.provider,
    required this.softwarePackage,
    required this.softwarePackageStatus,
    required this.status,
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
        ' id: $id,' +
        ' siteId: $siteId,' +
        ' serialNumber: $serialNumber,' +
        ' channel: ${channel.toString()},' +
        ' product: ${product.toString()},' +
        ' plan: ${plan.toString()},' +
        ' provider: ${provider.toString()},' +
        ' softwarePackage: ${softwarePackage.toString()}' +
        ' softwarePackageStatus: $softwarePackageStatus,' +
        ' status: $status,' +
        ' order: ${order.toString()},' +
        ' providerOrder: ${providerOrder?.toString()},' +
        ' startTime: $startTime,' +
        ' renewTime: $renewTime,' +
        ' endTime: $endTime,' +
        ' serviceEndTime: $serviceEndTime,' +
        ' expireTime: $expireTime,' +
        '}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'siteId': siteId,
      'serialNumber': serialNumber,
      'channel': channel.toJson(),
      'product': product.toJson(),
      'plan': plan.toJson(),
      'provider': provider.toJson(),
      'softwarePackage': softwarePackage.toJson(),
      'softwarePackageStatus': softwarePackageStatus,
      'status': status,
      'order': order.toJson(),
      'providerOrder': providerOrder?.toJson(),
      'startTime': startTime,
      'renewTime': renewTime,
      'endTime': endTime,
      'serviceEndTime': serviceEndTime,
      'expireTime': expireTime,
    };
  }

  factory NetworkEntitlementResponse.fromJson(Map<String, dynamic> json) {
    return NetworkEntitlementResponse(
      id: json['id'],
      siteId: json['siteId'],
      serialNumber: json['serialNumber'],
      channel: SubscriptionChannel.fromJson(json['channel']),
      product: SubscriptionProduct.fromJson(json['product']),
      plan: SubscriptionPlan.fromJson(json['plan']),
      provider: SubscriptionProvider.fromJson(json['provider']),
      softwarePackage: SoftwarePackage.fromJson(json['softwarePackage']),
      softwarePackageStatus: json['softwarePackageStatus'],
      status: json['status'],
      order: SubscriptionOrderResponse.fromJson(json['order']),
      providerOrder: json['providerOrder'] != null
          ? ProviderOrder.fromJson(json['providerOrder'])
          : null,
      startTime: json['startTime'],
      renewTime: json['renewTime'],
      endTime: json['endTime'],
      serviceEndTime: json['serviceEndTime'],
      expireTime: json['expireTime'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        siteId,
        serialNumber,
        channel,
        product,
        plan,
        provider,
        softwarePackage,
        softwarePackageStatus,
        status,
        order,
        providerOrder,
        startTime,
        renewTime,
        endTime,
        serviceEndTime,
        expireTime
      ];
}
