import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/utils/logger.dart';

Future<void> initAnalyticsDefault() async {
  if (!kIsWeb) {
    final platformConst = await PackageInfo.fromPlatform();
    await FirebaseAnalytics.instance.setDefaultEventParameters({
      'version': platformConst.version,
      'appId': platformConst.packageName,
      'buildNumber': platformConst.buildNumber,
      'cloud': BuildConfig.cloudEnv,
    });
  }
}

void logEvent(
    {required String eventName, Map<String, Object?>? parameters}) async {
  logger.d('Firebase Log Event:: name: $eventName, parameters: $parameters');
  await FirebaseAnalytics.instance
      .logEvent(name: eventName, parameters: parameters);
}
