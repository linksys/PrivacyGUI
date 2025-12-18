import 'package:flutter/widgets.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

enum FaqItem {
  faqVisitLinksysSupport,
  faqListCannotAddChildNode,
  noInternetConnectionTitle,
  faqListLoseChildNode,
  faqListLoseDevices,
  faqListDeviceNoWiFi,
  faqListDeviceNoBestNode,
  faqListMyInternetSlowOrSpecificDeviceSlow,
  faqListLogInByRouterPassword,
  faqListForgotRouterPassword,
  faqListChangeWiFiNamePassword,
  faqListWhatLightsMean,
  faqListHowToFactoryReset,
  faqListLightsNotWorking,
  faqListNodeNotTurnOn,
  faqListEthernetPortNotWorking,
  faqListCheckIfFirmwareAutoUpdate;

  String displayString(BuildContext context) => switch (this) {
    faqVisitLinksysSupport => loc(context).faqVisitLinksysSupport,
    faqListCannotAddChildNode => loc(context).faqListCannotAddChildNode,
    noInternetConnectionTitle => loc(context).noInternetConnectionTitle,
    faqListLoseChildNode => loc(context).faqListLoseChildNode,
    faqListLoseDevices => loc(context).faqListLoseDevices,
    faqListDeviceNoWiFi => loc(context).faqListDeviceNoWiFi,
    faqListDeviceNoBestNode => loc(context).faqListDeviceNoBestNode,
    faqListMyInternetSlowOrSpecificDeviceSlow => loc(context).faqListMyInternetSlowOrSpecificDeviceSlow,
    faqListLogInByRouterPassword => loc(context).faqListLogInByRouterPassword,
    faqListForgotRouterPassword => loc(context).faqListForgotRouterPassword,
    faqListChangeWiFiNamePassword => loc(context).faqListChangeWiFiNamePassword,
    faqListWhatLightsMean => loc(context).faqListWhatLightsMean,
    faqListHowToFactoryReset => loc(context).faqListHowToFactoryReset,
    faqListLightsNotWorking => loc(context).faqListLightsNotWorking,
    faqListNodeNotTurnOn => loc(context).faqListNodeNotTurnOn,
    faqListEthernetPortNotWorking => loc(context).faqListEthernetPortNotWorking,
    faqListCheckIfFirmwareAutoUpdate => loc(context).faqListCheckIfFirmwareAutoUpdate,
  };
  
  String get url => switch (this) {
    faqVisitLinksysSupport => linkSupport,
    faqListCannotAddChildNode => linkSetupCannotAddChildNode,
    noInternetConnectionTitle => linkSetupNoInternetConnection,
    faqListLoseChildNode => linkConnectivityLoseChildNode,
    faqListLoseDevices => linkConnectivityLoseDevices,
    faqListDeviceNoWiFi => linkConnectivityDeviceNoWiFi,
    faqListDeviceNoBestNode => linkConnectivityDeviceNoBestNode,
    faqListMyInternetSlowOrSpecificDeviceSlow => linkSpeedMyInternetSlow,
    faqListLogInByRouterPassword => linkPasswordLoginByRouterPassword,
    faqListForgotRouterPassword => linkPasswordForgotRouterPassword,
    faqListChangeWiFiNamePassword => linkPasswordChangeWiFiNamePassword,
    faqListWhatLightsMean => linkHardwareWhatLightMean,
    faqListHowToFactoryReset => linkHardwareHowToFactoryReset,
    faqListLightsNotWorking => linkHardwareLightsNotWorking,
    faqListNodeNotTurnOn => linkHardwareNodeNotTureOn,
    faqListEthernetPortNotWorking => linkHardwareEthernetPortNotWorking,
    faqListCheckIfFirmwareAutoUpdate => linkCheckIfAutoFirmwareOn,
  };
}

sealed class FaqCategory {
  String get titleKey;
  List<FaqItem> get items;

  String displayString(BuildContext context) => switch (this) {
    FaqSetupCategory() => loc(context).setup,
    FaqConnectivityCategory() => loc(context).connectivity,
    FaqSpeedCategory() => loc(context).speed,
    FaqPasswordCategory() => loc(context).passwordAndAccess,
    FaqHardwareCategory() => loc(context).hardware,
  };
}

class FaqSetupCategory extends FaqCategory {
  @override
  final String titleKey = 'setup';
  @override
  final List<FaqItem> items = [
    FaqItem.faqListCannotAddChildNode,
    FaqItem.noInternetConnectionTitle,
  ];
}

class FaqConnectivityCategory extends FaqCategory {
  @override
  final String titleKey = 'connectivity';
  @override
  final List<FaqItem> items = [
    FaqItem.faqListLoseChildNode,
    FaqItem.faqListLoseDevices,
    FaqItem.faqListDeviceNoWiFi,
    FaqItem.faqListDeviceNoBestNode,
  ];
}

class FaqSpeedCategory extends FaqCategory {
  @override
  final String titleKey = 'speed';
  @override
  final List<FaqItem> items = [
    FaqItem.faqListMyInternetSlowOrSpecificDeviceSlow,
  ];
}

class FaqPasswordCategory extends FaqCategory {
  @override
  final String titleKey = 'passwordAndAccess';
  @override
  final List<FaqItem> items = [
    FaqItem.faqListLogInByRouterPassword,
    FaqItem.faqListForgotRouterPassword,
    FaqItem.faqListChangeWiFiNamePassword,
  ];
}

class FaqHardwareCategory extends FaqCategory {
  @override
  final String titleKey = 'hardware';
  @override
  final List<FaqItem> items = [
    FaqItem.faqListWhatLightsMean,
    FaqItem.faqListHowToFactoryReset,
    FaqItem.faqListLightsNotWorking,
    FaqItem.faqListNodeNotTurnOn,
    FaqItem.faqListEthernetPortNotWorking,
    FaqItem.faqListCheckIfFirmwareAutoUpdate,
  ];
}