
import 'package:flutter/services.dart';

class UniversalLinkChannel {
  // Singleton
  static final UniversalLinkChannel _singleton =
  UniversalLinkChannel._internal();

  factory UniversalLinkChannel() {
    return _singleton;
  }

  UniversalLinkChannel._internal();

  static const _platform = EventChannel('com.linksys.moab/universal_link');

  Stream get stream => _platform.receiveBroadcastStream();
}