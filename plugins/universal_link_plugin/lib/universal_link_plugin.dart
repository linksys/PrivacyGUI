
import 'universal_link_plugin_platform_interface.dart';

class UniversalLinkPlugin {
  Future<String?> getPlatformVersion() {
    return UniversalLinkPluginPlatform.instance.getPlatformVersion();
  }

  Stream<dynamic> get universalLinkStream => UniversalLinkPluginPlatform.instance.universalLinkStream;
}
