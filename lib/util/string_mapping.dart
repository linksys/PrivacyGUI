import 'package:flutter/cupertino.dart';
import 'package:linksys_moab/localization/localization_hook.dart';

ConnectionTypeData toConnectionTypeData(BuildContext context, String type) {
  switch (type) {
    case 'DHCP':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connection_type_dhcp,
        description: getAppLocalizations(context).connection_type_dhcp_desc,
      );
    case 'Static':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connection_type_static,
        description: getAppLocalizations(context).connection_type_static_desc,
      );
    case 'PPPoE':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connection_type_pppoe,
        description: getAppLocalizations(context).connection_type_pppoe_desc,
      );
    case 'PPTP':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connection_type_pptp,
        description: getAppLocalizations(context).connection_type_pptp_desc,
      );
    case 'L2TP':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connection_type_l2tp,
        description: getAppLocalizations(context).connection_type_l2tp_desc,
      );
    case 'Bridge':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connection_type_bridge,
        description: getAppLocalizations(context).connection_type_bridge_desc,
      );
    case 'Automatic':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connection_type_automatic,
        description:
        getAppLocalizations(context).connection_type_automatic_desc,
      );
    default:
      return ConnectionTypeData(type: type, title: '', description: '');
  }
}

class ConnectionTypeData {
  final String type;
  final String title;
  final String description;

  const ConnectionTypeData({
    required this.type,
    required this.title,
    required this.description,
  });
}
