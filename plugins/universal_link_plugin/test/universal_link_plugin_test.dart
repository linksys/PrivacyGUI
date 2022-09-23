import 'package:flutter_test/flutter_test.dart';
import 'package:universal_link_plugin/universal_link_plugin.dart';
import 'package:universal_link_plugin/universal_link_plugin_platform_interface.dart';
import 'package:universal_link_plugin/universal_link_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockUniversalLinkPluginPlatform 
    with MockPlatformInterfaceMixin
    implements UniversalLinkPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  // TODO: implement universalLinkStream
  Stream get universalLinkStream => throw UnimplementedError();
}

void main() {
  final UniversalLinkPluginPlatform initialPlatform = UniversalLinkPluginPlatform.instance;

  test('$MethodChannelUniversalLinkPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelUniversalLinkPlugin>());
  });

  test('getPlatformVersion', () async {
    UniversalLinkPlugin universalLinkPlugin = UniversalLinkPlugin();
    MockUniversalLinkPluginPlatform fakePlatform = MockUniversalLinkPluginPlatform();
    UniversalLinkPluginPlatform.instance = fakePlatform;
  
    expect(await universalLinkPlugin.getPlatformVersion(), '42');
  });
}
