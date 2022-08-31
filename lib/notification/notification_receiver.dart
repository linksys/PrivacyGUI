import 'dart:async';
import 'dart:convert';

import '../config/cloud_environment_manager.dart';

void pushNotificationHandler(Map<String, dynamic> data) {
  // Smart device token
  if (data.containsKey('token')) {
    final token = data['token'];
    CloudEnvironmentManager().acceptSmartDevice(token);
  } else {

  }
}