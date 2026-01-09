/// Assign IP - Cross-platform web location manipulation.
///
/// This library provides platform-aware web location functions.
/// Consumers only need to import this file:
///
/// ```dart
/// import 'package:privacy_gui/core/utils/assign_ip/assign_ip.dart';
///
/// assignWebLocation('https://new-host.local');
/// ```
///
/// The correct platform implementation is automatically selected at compile time.
/// - Web: Uses `window.location` APIs
/// - Native: No-op (these operations are web-specific)
library;

export 'base_assign_ip.dart'
    if (dart.library.io) 'mobile_assign_ip.dart'
    if (dart.library.html) 'web_assign_ip.dart';
