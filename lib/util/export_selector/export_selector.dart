/// Export Selector - Cross-platform file export functionality.
///
/// This library provides platform-aware file export/share.
/// Consumers only need to import this file:
///
/// ```dart
/// import 'package:privacy_gui/util/export_selector/export_selector.dart';
///
/// await exportFile(content: '...', fileName: 'log.txt');
/// ```
///
/// The correct platform implementation is automatically selected at compile time.
library;

export 'export_base.dart'
    if (dart.library.io) 'export_mobile.dart'
    if (dart.library.html) 'export_web.dart';
