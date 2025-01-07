import 'dart:ui';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:privacy_gui/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/url_helper/url_helper_web.dart';

const officialWebHost = 'https://store.linksys.com';
const officialSupportHost = 'https://support.linksys.com';

const linkEULA = 'https://www.linksys.com/pages/end-user-license-agreement';
const linkTerms = 'https://www.linksys.com/pages/linksys-smart-wifi-terms-of-service';
const linkPrivacy =
    'https://www.linksys.com/blogs/support-article/linksys-privacy-policy';
const linkThirdParty = '$officialSupportHost/kb/article/943-en';
const linkSupport = '$officialWebHost/linksys-support';
// FAQ Setup
const linkSetupCannotAddChildNode = '$officialSupportHost/kb/article/6793-en';
const linkSetupNoInternetConnection = '$officialSupportHost/kb/article/6794-en';
// FAQ Connectivity
const linkConnectivityLoseChildNode = '$officialSupportHost/kb/article/6873-en';
const linkConnectivityLoseDevices = '$officialSupportHost/kb/article/6796-en';
const linkConnectivityDeviceNoWiFi = '$officialSupportHost/kb/article/6797-en';
const linkConnectivityDeviceNoBestNode =
    '$officialSupportHost/kb/article/6798-en';
// FAQ Speed
const linkSpeedMyInternetSlow = '$officialSupportHost/kb/article/6873-en';
const linkSpeedSpecificDeviceSlow = '$officialSupportHost/kb/article/6873-en';
const linkSpeedSlowAfterAddNode = '$officialSupportHost/kb/article/6873-en';
// FAQ Password And Access
const linkPasswordLoginByRouterPassword =
    '$officialSupportHost/kb/article/6802-en';
const linkPasswordForgotRouterPassword =
    '$officialSupportHost/kb/article/6803-en';
const linkPasswordChangeWiFiNamePassword =
    '$officialSupportHost/kb/article/6804-en';
// FAQ Hardware
const linkHardwareWhatLightMean = '$officialSupportHost/kb/article/97-en';
const linkHardwareHowToFactoryReset = '$officialSupportHost/kb/article/201-en';
const linkHardwareLightsNotWorking = '$officialSupportHost/kb/article/6807-en';
const linkHardwareNodeNotTureOn = '$officialSupportHost/kb/article/6807-en';
const linkHardwareEthernetPortNotWorking =
    '$officialSupportHost/kb/article/6807-en';
const linkCheckIfAutoFirmwareOn = '$officialSupportHost/kb/article/6810-en';
// Explanation
const linksysCertExplanation =
    '$officialWebHost/support-article?articleNum=318835';

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
        '$officialWebHost/${locale.countryCode?.toLowerCase() ?? officialWebConutryMapping[locale.languageCode]?.toLowerCase()}$path';
  } else {
    websiteUrl = url;
  }
  logger.i('open web url: $websiteUrl');
  openUrl(websiteUrl);
}
