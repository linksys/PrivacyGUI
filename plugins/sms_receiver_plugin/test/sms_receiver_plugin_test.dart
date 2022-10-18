import 'package:flutter_test/flutter_test.dart';
import 'package:sms_receiver_plugin/sms_receiver_plugin.dart';
import 'package:sms_receiver_plugin/sms_receiver_plugin_platform_interface.dart';
import 'package:sms_receiver_plugin/sms_receiver_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSmsReceiverPluginPlatform
    with MockPlatformInterfaceMixin
    implements SmsReceiverPluginPlatform {


  @override
  Stream get smsReceiverStream => throw UnimplementedError();
}

void main() {
  final SmsReceiverPluginPlatform initialPlatform = SmsReceiverPluginPlatform.instance;

  test('$EventChannelSmsReceiverPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<EventChannelSmsReceiverPlugin>());
  });

  test('getPlatformVersion', () async {
    SmsReceiverPlugin smsReceiverPlugin = SmsReceiverPlugin();
    MockSmsReceiverPluginPlatform fakePlatform = MockSmsReceiverPluginPlatform();
    SmsReceiverPluginPlatform.instance = fakePlatform;

  });
}
