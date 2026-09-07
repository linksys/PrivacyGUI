import 'dart:ui';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart';

const officialWebHost = 'https://store.linksys.com';
const officialSupportHost = 'https://support.linksys.com';

const linkEULA = 'https://www.linksys.com/pages/end-user-license-agreement';
const linkTerms =
    'https://www.linksys.com/pages/linksys-smart-wifi-terms-of-service';
const linkPrivacy =
    'https://www.linksys.com/blogs/support-article/linksys-privacy-policy';
const linkThirdParty = '$officialSupportHost/kb/article/943-en';
const linkSupport = '$officialWebHost/linksys-support';
// FAQ Setup
const linkSetupCannotAddChildNode = '$officialSupportHost/kb/article/6793-en';
const linkSetupNoInternetConnection = '$officialSupportHost/kb/article/6794-en';
// FAQ Connectivity
const linkConnectivityLoseChildNode = '$officialSupportHost/kb/article/8184-en';
const linkConnectivityLoseDevices = '$officialSupportHost/kb/article/6796-en';
const linkConnectivityDeviceNoWiFi = '$officialSupportHost/kb/article/6797-en';
const linkConnectivityDeviceNoBestNode =
    '$officialSupportHost/kb/article/6798-en';
// FAQ Speed
const linkSpeedMyInternetSlow = '$officialSupportHost/kb/article/79-en';
const linkSpeedSpecificDeviceSlow = '$officialSupportHost/kb/article/79-en';
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
    '$officialSupportHost/kb/article/8185-en';
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

/// The URL [gotoOfficialWebUrl] would open for [url] under [locale].
///
/// Split out from [gotoOfficialWebUrl] so this hop can be tested: `openUrl` is
/// chosen at compile time by conditional export, so it cannot be injected and
/// the side-effecting version cannot be asserted on.
///
/// Only `store.linksys.com` links get a country segment. Every other host —
/// `www.linksys.com` for the legal pages, `support.linksys.com` for FAQ
/// articles — is returned untouched, which is why the locale a caller passes
/// reaches the network for two links only ([linkSupport] and
/// [linksysCertExplanation]).
///
/// A [locale] of null leaves the URL bare. Nothing in the app passes null any
/// more — every caller reads `activeLocaleProvider`, which cannot return it —
/// but the parameter stays nullable because the un-prefixed URL is still a
/// valid destination and callers outside the locale-aware paths use it.
String officialWebUrlFor(String url, {Locale? locale}) {
  if (!url.startsWith(officialWebHost) || locale == null) {
    return url;
  }
  final path = url.substring(officialWebHost.length);
  final country = locale.countryCode?.toLowerCase() ??
      officialWebConutryMapping[locale.languageCode]?.toLowerCase();
  return '$officialWebHost/$country$path';
}

void gotoOfficialWebUrl(String url, {Locale? locale}) {
  final websiteUrl = officialWebUrlFor(url, locale: locale);
  logger.i('[App]: open web url: $websiteUrl');
  openUrl(websiteUrl);
}
