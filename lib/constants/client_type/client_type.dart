/// Client Type - Cross-platform client type constants.
///
/// This library provides platform-aware client type identification.
/// Consumers only need to import this file:
///
/// ```dart
/// import 'package:privacy_gui/constants/client_type/client_type.dart';
///
/// final type = clientType; // automatically returns correct platform value
/// ```
///
/// The correct platform implementation is automatically selected at compile time.
library;

export 'get_client_type.dart'
    if (dart.library.io) 'mobile_client_type.dart'
    if (dart.library.html) 'web_client_type.dart';
