import 'package:firebase_analytics/firebase_analytics.dart';

import '../core/utils/logger.dart';

void logEvent({required String eventName, Map<String, Object?>? parameters}) async {
  logger.d('Firebase Log Event:: name: $eventName, parameters: $parameters');
  await FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
}