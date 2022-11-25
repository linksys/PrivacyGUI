import 'cloud_const.dart';

enum CloudEnvironment { dev, qa, prod }

class BuildConfig {
  static const String cloudEnv =
      String.fromEnvironment('cloud_env', defaultValue: 'qa');
  static const bool isEnableEnvPicker =
      bool.fromEnvironment('enable_env_picker', defaultValue: true);
}

CloudEnvironment cloudEnvTarget = CloudEnvironment.values
    .firstWhere((element) => element.name == BuildConfig.cloudEnv);
Map<String, dynamic> cloudEnvironmentConfig =
    kCloudEnvironmentMap[cloudEnvTarget];
