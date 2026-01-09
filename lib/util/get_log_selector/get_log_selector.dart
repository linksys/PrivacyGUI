/// Get Log Selector - Cross-platform log retrieval functionality.
///
/// This library provides platform-aware log retrieval.
/// Consumers only need to import this file:
///
/// ```dart
/// import 'package:privacy_gui/util/get_log_selector/get_log_selector.dart';
///
/// final logContent = await getLog(context);
/// ```
///
/// The correct platform implementation is automatically selected at compile time.
library;

export 'get_log_base.dart'
    if (dart.library.io) 'get_log_mobile.dart'
    if (dart.library.html) 'get_log_web.dart';
