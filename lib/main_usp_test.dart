import 'package:flutter/material.dart';
import 'package:privacy_gui/page/usp_test/usp_test_page.dart';

/// Standalone entry point for USP client testing.
///
/// Run with: flutter run -d chrome -t lib/main_usp_test.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    title: 'USP Client Test',
    home: UspTestPage(),
  ));
}
