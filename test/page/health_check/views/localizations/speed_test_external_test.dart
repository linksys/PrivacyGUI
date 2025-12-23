import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/health_check/views/speed_test_external.dart';

import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';

// Reference: lib/page/health_check/views/speed_test_external.dart
// View ID: STEXT
//
// ## Test Cases
//
// | Test ID    | Description                                                 |
// |------------|-------------------------------------------------------------|
// | STEXT-INIT | Verify the initial state of the external speed test view. |

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  // Test ID: STEXT-INIT
  testLocalizationsV2(
    'Verify the initial state of the external speed test view',
    (tester, screen) async {
      await testHelper.pumpView(
        tester,
        child: const SpeedTestExternalView(),
        locale: screen.locale,
      );
    },
    goldenFilename: 'STEXT-INIT-01-initial_state',
  );
}