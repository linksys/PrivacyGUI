import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'universal_link_plugin_platform_interface.dart';

/// An implementation of [UniversalLinkPluginPlatform] that uses method channels.
class MethodChannelUniversalLinkPlugin extends UniversalLinkPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('universal_link_plugin');

  final eventChannel = const EventChannel('com.linksys.moab/universal_link');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Stream<dynamic> get universalLinkStream => eventChannel.receiveBroadcastStream();
}
