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
  static const bool caLogin = bool.fromEnvironment('ca', defaultValue: false);

  static const int refreshTimeInterval =
      int.fromEnvironment('refresh_time', defaultValue: 60);
  static const copyRightYear = int.fromEnvironment('year', defaultValue: 2025);

  static const String unknownSourceRevision = 'unknown';

  // Identifies the source a build came from, independently of its version
  // number: local and remote are built from the same commit but numbered by
  // separate pipelines, so the version alone cannot tell "same source,
  // different build" from "different source". Set by build_web.sh; stays
  // [unknownSourceRevision] for a build that did not go through it.
  static const String sourceRevision = String.fromEnvironment('source_revision',
      defaultValue: unknownSourceRevision);

  /// How a revision is rendered beside a version string.
  ///
  /// Pure and takes the revision so both branches are testable; `const` inputs
  /// mean the call folds away.
  static String revisionSuffix(String revision) => ' ($revision)';

  /// Always rendered, `unknown` included: a build that did not come through the
  /// pipeline showing nothing is indistinguishable from a build made before any
  /// of this existed, which is the ambiguity the stamp exists to remove.
  static String get sourceRevisionSuffix => revisionSuffix(sourceRevision);

  // Gates the three client-side remote assistance entry points: the support
  // button in the top bar, the active-session poll in the polling provider, and
  // the dashboard shell's passive dialog. Kept `const` so dart2js drops the
  // guarded code from a default build - measured absent from the bundle - which
  // is what commenting those sites out used to achieve.
  //
  // It does not gate the Guardian path (`initiateRemoteAssistanceCA`, reached on
  // a remote login), which ships either way, so remote assistance code remains
  // reachable in a default build even though none of these entry points do.
  static const bool enableRemoteAssistance =
      bool.fromEnvironment('enable_remote_assistance', defaultValue: false);

  @pragma('vm:entry-point')
  static load() async {
    logger.d('load build configuration');
    final prefs = await SharedPreferences.getInstance();
    final envStr = prefs.getString(pCloudEnv);
    cloudEnvTarget = CloudEnvironment.get(envStr ?? '') ?? cloudEnvTarget;
    logger.d('Cloud Env: $cloudEnvTarget');
  }

  static bool isRemote() {
    return forceCommandType == ForceCommand.remote;
  }

  static bool isLocal() {
    return forceCommandType == ForceCommand.local;
  }
}

bool showDebugPanel = !kReleaseMode && !kIsWeb;

CloudEnvironment cloudEnvTarget = CloudEnvironment.values
    .firstWhere((element) => element.name == BuildConfig.cloudEnv);
Map<String, dynamic> get cloudEnvironmentConfig =>
    kCloudEnvironmentMap[cloudEnvTarget];

Future<String> getVersion() async {
  final version = await getBuildNumber();
  return version ??
      await PackageInfo.fromPlatform().then((value) => value.version);
}

Future<String?> getBuildNumber() async {
  String? buildNumber;
  final json = await rootBundle
      .loadString('assets/resources/versions.json', cache: false)
      .then((value) => jsonDecode(value))
      .onError((error, stackTrace) => null);
  if (json != null) {
    buildNumber = json['version'] as String?;
  }
  return buildNumber;
}
