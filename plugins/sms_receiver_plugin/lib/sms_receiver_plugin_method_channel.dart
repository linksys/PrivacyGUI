import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sms_receiver_plugin_platform_interface.dart';

/// An implementation of [SmsReceiverPluginPlatform] that uses method channels.
class EventChannelSmsReceiverPlugin extends SmsReceiverPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel('sms_receiver_plugin');

  @override
  Stream<dynamic> get smsReceiverStream => eventChannel.receiveBroadcastStream();

}
