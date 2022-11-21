import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/util/logger.dart';

class UserProfile extends Equatable {
  final String name;
  final String icon;
  final List<ProfileDevice> devices;
  final bool enabled;
  final ContentFilterConfiguration? contentFilterConfig;

  UserProfile({
    this.name = '',
    this.icon = '',
    this.devices = const [],
    this.enabled = false,
    this.contentFilterConfig,
  });

  UserProfile copyWith({
    String? name,
    String? icon,
    List<ProfileDevice>? devices,
    bool? enabled,
    ContentFilterConfiguration? contentFilterConfig,
    // TODO: Remove below! No functionality, just provide an input for setter for now
    Map<PService, MoabServiceData>? serviceDetails,
  }) {
    return UserProfile(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      devices: devices ?? this.devices,
      enabled: enabled ?? this.enabled,
      contentFilterConfig: contentFilterConfig ?? this.contentFilterConfig,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'icon': icon,
        'devices': devices.map((e) => e.toJson()).toList(),
        'enabled': enabled,
        'contentFilterConfig': contentFilterConfig?.toJson(),
      }..removeWhere((key, value) => value == null);

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'],
        icon: json['icon'],
        devices: List.from(json['devices'])
            .map((e) => ProfileDevice.fromJson(e))
            .toList(),
        enabled: json['enabled'],
        contentFilterConfig: json['contentFilterConfig'] != null
            ? ContentFilterConfiguration.fromJson(json['contentFilterConfig'])
            : null,
      );

  @override
  List<Object?> get props => [
        name,
        icon,
        devices,
        enabled,
        contentFilterConfig,
      ];

  //TODO: Check how to handle and store the data of ContentFilter and InternetSchedule
  // ContentFilterData has been extract to contentFilterConfig
  final Map<PService, MoabServiceData> serviceDetails = {};

  bool hasServiceDetail(PService category) {
    return serviceDetails.containsKey(category);
  }

  String getContentFilterOverallStatus(
      BuildContext context, ContentFilterData? data) {
    bool hasData = data != null;
    bool isEnable = false;
    if (hasData) {
      isEnable = hasData & data.isEnabled;
    }
    logger.d('XXXXX: $data');
    return hasData
        ? isEnable
            ? getAppLocalizations(context).on
            : getAppLocalizations(context).off
        : getAppLocalizations(context).no_filters;
  }

  String serviceOverallStatus(BuildContext context, PService category) {
    // TODO REFACOR
    if (category == PService.internetSchedule) {
      bool hasData = serviceDetails.containsKey(category);
      bool isEnable = false;
      if (hasData) {
        final details = serviceDetails[category] as InternetScheduleData;
        hasData = details.scheduledPauseRule.isNotEmpty |
            details.dateTimeLimitRule.isNotEmpty;
        isEnable = hasData &
            (details.dateTimeLimitRule.any((element) => element.isEnabled) |
                details.scheduledPauseRule.any((element) => element.isEnabled));
      }
      return hasData
          ? isEnable
              ? getAppLocalizations(context).on
              : getAppLocalizations(context).off
          : getAppLocalizations(context).none;
    } else if (category == PService.contentFilter) {
      return getContentFilterOverallStatus(context, contentFilterConfig?.data);
    }
    return '';
  }
}

class ProfileDevice extends Equatable {
  const ProfileDevice({
    required this.deviceId,
    required this.name,
    required this.macAddress,
  });

  final String deviceId;
  final String name;
  final String macAddress;

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'name': name,
        'macaddress': macAddress,
      };

  factory ProfileDevice.fromJson(Map<String, dynamic> json) => ProfileDevice(
        deviceId: json['deviceId'],
        name: json['name'],
        macAddress: json['macaddress'],
      );

  @override
  List<Object?> get props => [
        deviceId,
        name,
        macAddress,
      ];
}

class ContentFilterConfiguration extends Equatable {
  final String policyId;
  final ContentFilterData data;

  const ContentFilterConfiguration({
    required this.policyId,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'policyId': policyId,
        'data': data.toJson(),
      };

  factory ContentFilterConfiguration.fromJson(Map<String, dynamic> json) {
    return ContentFilterConfiguration(
      policyId: json['policyId'],
      data: ContentFilterData.fromJson(json['data']),
    );
  }

  @override
  List<Object?> get props => [
        policyId,
        data,
      ];

  ContentFilterConfiguration copyWith({
    String? policyId,
    ContentFilterData? data,
  }) {
    return ContentFilterConfiguration(
      policyId: policyId ?? this.policyId,
      data: data ?? this.data,
    );
  }
}
