
import 'sms_receiver_plugin_platform_interface.dart';

class SmsReceiverPlugin {
  Stream<dynamic> get smsReceiverStream => SmsReceiverPluginPlatform.instance.smsReceiverStream;

}
