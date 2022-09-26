import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ios_push_notification_plugin_method_channel.dart';

abstract class IosPushNotificationPluginPlatform extends PlatformInterface {
  /// Constructs a IosPushNotificationPluginPlatform.
  IosPushNotificationPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static IosPushNotificationPluginPlatform _instance = MethodChannelIosPushNotificationPlugin();

  /// The default instance of [IosPushNotificationPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelIosPushNotificationPlugin].
  static IosPushNotificationPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IosPushNotificationPluginPlatform] when
  /// they register themselves.
  static set instance(IosPushNotificationPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> readApnsToken() {
    throw UnimplementedError('getDeviceToken() has not been implemented.');
  }
  Future<bool> requestAuthorization() {
    throw UnimplementedError('requestAuthorization() has not been implemented.');
  }
  Stream<dynamic> get pushNotificationStream => throw UnimplementedError('pushNotificationStream has not been implemented.');

}
