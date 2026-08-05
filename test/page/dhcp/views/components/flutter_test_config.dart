import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/load_app_test_fonts.dart';

/// Loads the shipped fonts for the card layout tests in this directory.
///
/// These tests assert measured geometry (single-line heights, right edges,
/// whether text ellipsises), so they must measure the font users actually see.
/// Without this, Flutter's built-in test font applies and is 1.8-2.7x wider,
/// which makes text look truncated when it is not.
///
/// `flutter_test_config.dart` is directory-scoped: it covers this directory and
/// its subdirectories only.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadAppTestFonts();
  await testMain();
}
