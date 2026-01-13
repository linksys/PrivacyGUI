/// URL Helper - Cross-platform URL opening functionality.
///
/// This library provides platform-aware URL opening.
/// Consumers only need to import this file:
///
/// ```dart
/// import 'package:privacy_gui/util/url_helper/url_helper.dart';
///
/// openUrl('https://example.com');
/// ```
///
/// The correct platform implementation is automatically selected at compile time.
/// - Native (iOS/Android): Opens URL using in-app browser
/// - Web: Opens URL in new browser tab
library;

export 'url_helper_stub.dart'
    if (dart.library.io) 'url_helper_mobile.dart'
    if (dart.library.html) 'url_helper_web.dart';
