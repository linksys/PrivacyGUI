import 'package:flutter/cupertino.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

ConnectionTypeData toConnectionTypeData(BuildContext context, String type) {
  switch (type) {
    case 'DHCP':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connectionTypeDhcp,
      );
    case 'Static':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connectionTypeStatic,
      );
    case 'PPPoE':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connectionTypePppoe,
      );
    case 'PPTP':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connectionTypePptp,
      );
    case 'L2TP':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connectionTypeL2tp,
      );
    case 'Bridge':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connectionTypeBridge,
      );
    case 'Automatic':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connectionTypeAutomatic,
      );
    case 'Pass-through':
      return ConnectionTypeData(
        type: type,
        title: getAppLocalizations(context).connectionTypePassThrough,
      );
    default:
      return ConnectionTypeData(type: type, title: ' ');
  }
}

class ConnectionTypeData {
  final String type;
  final String title;

  const ConnectionTypeData({
    required this.type,
    required this.title,
  });
}
