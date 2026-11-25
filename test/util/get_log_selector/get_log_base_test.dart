// The fallback of the conditional import in utils.dart, for a platform with
// neither dart:io nor dart:html. Every real build picks get_log_mobile.dart or
// get_log_web.dart instead.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/util/get_log_selector/get_log_base.dart';

void main() {
  testWidgets('a platform without io or html has no log to export',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));

    await expectLater(getLog(context), throwsUnimplementedError);
  });
}
