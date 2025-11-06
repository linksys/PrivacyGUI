import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/health_check/views/speed_test_external.dart';

import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  testLocalizations('SpeedtestExternal - init', (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const SpeedTestExternalView(),
      locale: locale,
    );
  });
}