import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'universal_link_plugin_method_channel.dart';

abstract class UniversalLinkPluginPlatform extends PlatformInterface {
  /// Constructs a UniversalLinkPluginPlatform.
  UniversalLinkPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static UniversalLinkPluginPlatform _instance = MethodChannelUniversalLinkPlugin();

  /// The default instance of [UniversalLinkPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelUniversalLinkPlugin].
  static UniversalLinkPluginPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [UniversalLinkPluginPlatform] when
  /// they register themselves.
  static set instance(UniversalLinkPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Stream<dynamic> get universalLinkStream => throw UnimplementedError('universalLinkStream has not been implemented.');
}
