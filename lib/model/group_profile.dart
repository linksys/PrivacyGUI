import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/profile_service_data.dart';

class GroupProfile extends Equatable {
  final String id;
  final String icon;
  final String name;

  final List<PDevice> devices;
  final Map<PService, MoabServiceData> serviceDetails;

  const GroupProfile({
    required this.id,
    required this.icon,
    required this.name,
    this.devices = const [],
    this.serviceDetails = const {},
  });

  GroupProfile copyWith({
    String? id,
    String? name,
    String? icon,
    List<PDevice>? devices,
    Map<PService, MoabServiceData>? serviceDetails,
  }) {
    return GroupProfile(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      name: name ?? this.name,
      devices: devices ?? this.devices,
      serviceDetails: serviceDetails ?? this.serviceDetails,
    );
  }

  bool hasServiceDetail(PService category) {
    return serviceDetails.containsKey(category);
  }

  // TODO move
  String serviceOverallStatus(BuildContext context, PService category) {
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
      bool hasData = serviceDetails.containsKey(category);
      bool isEnable = false;
      if (hasData) {
        final details = serviceDetails[category] as ContentFilterData;
        isEnable = hasData & details.isEnabled;
      }
      return hasData
          ? isEnable
          ? getAppLocalizations(context).on
          : getAppLocalizations(context).off
          : getAppLocalizations(context).no_filters;
    }
    return '';
  }

  @override
  List<Object?> get props => [
    id,
    name,
    icon,
    devices,
    serviceDetails,
  ];
}

// TODO rename
class PDevice extends Equatable {
  const PDevice({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}


enum CFSecureProfileType { child, teen, adult }

enum FilterStatus {
  allowed,
  someAllowed,
  notAllowed,
  force,
}