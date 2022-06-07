import 'package:firebase_analytics/firebase_analytics.dart';

void logEvent({required String eventName, Map<String, Object?>? parameters}) async {
  print('Log Event:: name: $eventName, parameters: $parameters');
  await FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
}