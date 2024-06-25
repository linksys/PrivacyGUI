import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CloudEnvironment {
  // dev,
  qa,
  prod;

  static CloudEnvironment? get(String name) {
    return values.firstWhereOrNull((element) => element.name == name);
  }
}

enum ForceCommand {
  local,
  remote,
  none;

  static ForceCommand reslove(String type) {
    logger.d('Force - $type');
    if (type == 'local') {
      return ForceCommand.local;
    } else if (type == 'remote') {
      return ForceCommand.remote;
    } else {
      return ForceCommand.none;
    }
  }
}

class BuildConfig {
  static const String cloudEnv =
      String.fromEnvironment('cloud_env', defaultValue: 'qa');
  static const bool isEnableEnvPicker =
      bool.fromEnvironment('enable_env_picker', defaultValue: true);

  static ForceCommand forceCommandType = ForceCommand.reslove(
      const String.fromEnvironment('force', defaultValue: 'none'));
  static bool showColumnOverlay =
      const bool.fromEnvironment('overlay', defaultValue: false);

  static load() async {
    logger.d('load build configuration');
    final prefs = await SharedPreferences.getInstance();
    final envStr = prefs.getString(pCloudEnv);
    cloudEnvTarget = CloudEnvironment.get(envStr ?? '') ?? cloudEnvTarget;
    logger.d('Cloud Env: $cloudEnvTarget');
  }
}

bool showDebugPanel = !kReleaseMode && !kIsWeb;

CloudEnvironment cloudEnvTarget = CloudEnvironment.values
    .firstWhere((element) => element.name == BuildConfig.cloudEnv);
Map<String, dynamic> get cloudEnvironmentConfig =>
    kCloudEnvironmentMap[cloudEnvTarget];

Future<String> getVersion({bool full = false}) async {
  final version =
      await PackageInfo.fromPlatform().then((value) => value.version);
  if (!full) {
    return version;
  }
  final build = await getBuildNumber().then((value) => '.$value');
  return '$version$build';
}

Future<int> getBuildNumber() async {
  int buildNumber = 0;
  final json = await rootBundle
      .loadString('assets/resources/versions.json')
      .then((value) => jsonDecode(value))
      .onError((error, stackTrace) => null);
  if (json != null) {
    buildNumber = json['build_number'] as int? ?? 0;
  }
  return buildNumber;
}
