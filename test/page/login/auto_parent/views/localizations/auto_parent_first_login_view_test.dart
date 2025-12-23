import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/login/auto_parent/providers/auto_parent_first_login_provider.dart';
import 'package:privacy_gui/page/login/auto_parent/views/auto_parent_first_login_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../mocks/auto_parent_first_login_notifier_mocks.dart';

// Corresponding implementation file: lib/page/login/auto_parent/views/auto_parent_first_login_view.dart

// View ID: APFLV

/// | Test ID      | Description                                               |
/// | :----------- | :-------------------------------------------------------- |
/// | `APFLV-INIT` | Verifies the initial view when firmware update is checking. |

void main() {
  final testHelper = TestHelper();
  late MockAutoParentFirstLoginNotifier mockAutoParentFirstLoginNotifier;

  setUp(() {
    testHelper.setup();
    mockAutoParentFirstLoginNotifier = MockAutoParentFirstLoginNotifier();
  });

  testLocalizations(
    'Verify initial view for auto parent first login',
    (tester, screen) async {
      // Test ID: APFLV-INIT
      const goldenFilename = 'APFLV-INIT-01-initial_state';

      // To keep the view in the loading state, we make the future never complete.
      final completer = Completer<bool>();
      when(mockAutoParentFirstLoginNotifier.checkAndAutoInstallFirmware())
          .thenAnswer((_) => completer.future);

      final context = await testHelper.pumpView(
        tester,
        child: const AutoParentFirstLoginView(),
        overrides: [
          autoParentFirstLoginProvider
              .overrideWith(() => mockAutoParentFirstLoginNotifier),
        ],
      );

      await tester.pump(); // pump for initState to call _doFirmwareUpdateCheck

      expect(find.byType(AppLoader), findsOneWidget);
      expect(
          find.text(testHelper.loc(context).pnpFwUpdateTitle), findsOneWidget);
      expect(
          find.text(testHelper.loc(context).pnpFwUpdateDesc), findsOneWidget);

      await testHelper.takeScreenshot(tester, goldenFilename);
    },
    helper: testHelper,
  );
}
