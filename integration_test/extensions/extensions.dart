import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterExt on WidgetTester {
  String getText(Finder finder) {
    return (widget(finder) as dynamic).controller?.text ?? '';
  }
}