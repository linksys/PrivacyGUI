import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_receiver_plugin/sms_receiver_plugin_method_channel.dart';

void main() {
  EventChannelSmsReceiverPlugin platform = EventChannelSmsReceiverPlugin();
  const MethodChannel channel = MethodChannel('sms_receiver_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });
}
