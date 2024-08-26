import 'dart:ui';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:privacy_gui/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/url_helper/url_helper_web.dart';

const officialWebHost = 'https://store.linksys.com';
const linkEULA = '$officialWebHost/support-article?articleNum=59241';
const linkTerms = '$officialWebHost/terms.html';
const linkPrivacy = '$officialWebHost/privacy-and-security.html';
const linkThirdParty = '$officialWebHost/support-article?articleNum=47763';
const linkSupport = '$officialWebHost/linksys-support';
// FAQ Setup
const linkSetupCannotAddChildNode =
    '$officialWebHost/support-article?articleNum=49041#Q1PlaceNodes';
const linkSetupNoInternetConnection =
    '$officialWebHost/support-article?articleNum=48464';
// FAQ Connectivity
const linkConnectivityLoseChildNode =
    '$officialWebHost/support-article?articleNum=49041#Q2NodeConnection';
const linkConnectivityLoseDevices =
    '$officialWebHost/support-article?articleNum=49041#Q3DeviceConnection';
const linkConnectivityDeviceNoWiFi =
    '$officialWebHost/support-article?articleNum=49782';
const linkConnectivityDeviceNoBestNode =
    '$officialWebHost/support-article?articleNum=49041#Q4DeviceNode';
// FAQ Speed
const linkSpeedMyInternetSlow =
    '$officialWebHost/support-article?articleNum=47970#q2';
const linkSpeedSpecificDeviceSlow =
    '$officialWebHost/support-article?articleNum=47970#q3';
const linkSpeedSlowAfterAddNode =
    '$officialWebHost/support-article?articleNum=47970#q4';
// FAQ Password And Access
const linkPasswordLoginByRouterPassword =
    '$officialWebHost/support-article?articleNum=50112#q2';
const linkPasswordForgotRouterPassword =
    '$officialWebHost/support-article?articleNum=50112#q4';
const linkPasswordChangeWiFiNamePassword =
    '$officialWebHost/support-article?articleNum=48369';
const linkPasswordAccessByWebBrowser =
    '$officialWebHost/support-article?articleNum=50112#q3';
// FAQ Hardware
const linkHardwareWhatLightMean =
    '$officialWebHost/support-article?articleNum=48301';
const linkHardwareHowToFactoryReset =
    '$officialWebHost/support-article?articleNum=50124';
const linkHardwareNodeKeepRestarting =
    '$officialWebHost/support-article?articleNum=48905#Restarting';
const linkHardwareLightsNotWorking =
    '$officialWebHost/support-article?articleNum=48905#LightNotWorking';
const linkHardwareNodeNotTureOn =
    '$officialWebHost/support-article?articleNum=48905#NotTurningOn';
const linkHardwareEthernetPortNotWorking =
    '$officialWebHost/support-article?articleNum=48905#PortsNotWorking';

const officialWebConutryMapping = {
  'ar': 'sa',
  'da': 'dk',
  'de': 'de',
  'el': 'gr',
  'en': 'us',
  'es': 'es',
  'fi': 'fi',
  'fr': 'fr',
  'id': 'id',
  'it': 'it',
  'ja': 'jp',
  'ko': 'kr',
  'nb': 'no',
  'nl': 'nl',
  'pl': 'pl',
  'pt': 'br',
  'ru': 'ru',
  'sv': 'se',
  'th': 'th',
  'tr': 'tr',
  'vi': 'vn',
  'zh': 'cn',
};

void gotoOfficialWebUrl(String url, {Locale? locale}) {
  late final String websiteUrl;
  if (url.startsWith(officialWebHost) && locale != null) {
    final path = url.substring(officialWebHost.length);
    websiteUrl =
        '$officialWebHost/${locale.countryCode ?? officialWebConutryMapping[locale.languageCode]}$path';
  } else {
    websiteUrl = url;
  }
  logger.i('open web url: $websiteUrl');
  openUrl(websiteUrl);
}
