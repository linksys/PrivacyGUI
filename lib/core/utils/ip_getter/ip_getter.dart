/// IP Getter - Cross-platform local IP address retrieval.
///
/// This library provides platform-aware IP address retrieval functions.
/// Consumers only need to import this file:
///
/// ```dart
/// import 'package:privacy_gui/core/utils/ip_getter/ip_getter.dart';
///
/// final ip = getLocalIp(ref);
/// ```
///
/// The correct platform implementation is automatically selected at compile time.
library;

export 'get_local_ip.dart'
    if (dart.library.io) 'mobile_get_local_ip.dart'
    if (dart.library.html) 'web_get_local_ip.dart';
