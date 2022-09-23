import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sms_receiver_plugin_method_channel.dart';

abstract class SmsReceiverPluginPlatform extends PlatformInterface {
  /// Constructs a SmsReceiverPluginPlatform.
  SmsReceiverPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static SmsReceiverPluginPlatform _instance = EventChannelSmsReceiverPlugin();

  /// The default instance of [SmsReceiverPluginPlatform] to use.
  ///
  /// Defaults to [EventChannelSmsReceiverPlugin].
  static SmsReceiverPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SmsReceiverPluginPlatform] when
  /// they register themselves.
  static set instance(SmsReceiverPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<dynamic> get smsReceiverStream =>
      throw UnimplementedError('smsReceiverStream has not been implemented.');
}
