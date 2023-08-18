import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CloudEnvironment {
  dev,
  qa,
  prod;

  static CloudEnvironment? get(String name) {
    return values.firstWhereOrNull((element) => element.name == name);
  }
}

class BuildConfig {
  static const String cloudEnv =
      String.fromEnvironment('cloud_env', defaultValue: 'qa');
  static const bool isEnableEnvPicker =
      bool.fromEnvironment('enable_env_picker', defaultValue: true);

  static load() async {
    final prefs = await SharedPreferences.getInstance();
    final envStr = prefs.getString(pCloudEnv);
    cloudEnvTarget = CloudEnvironment.get(envStr ?? '') ?? cloudEnvTarget;
  }
}

bool showDebugPanel = !kReleaseMode;

CloudEnvironment cloudEnvTarget = CloudEnvironment.values
    .firstWhere((element) => element.name == BuildConfig.cloudEnv);
Map<String, dynamic> get cloudEnvironmentConfig =>
    kCloudEnvironmentMap[cloudEnvTarget];
