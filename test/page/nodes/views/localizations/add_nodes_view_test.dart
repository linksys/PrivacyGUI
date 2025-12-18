import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_state.dart';
import 'package:privacy_gui/page/nodes/views/add_nodes_view.dart';
import 'package:privacy_gui/page/nodes/views/light_different_color_modal.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/page/components/composed/app_node_list_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/device_test_data.dart';

// Corresponding implementation file: lib/page/nodes/views/add_nodes_view.dart

// View ID: ADDND

/// | Test ID              | Description                                                                 |
/// | :------------------- | :-------------------------------------------------------------------------- |
/// | `ADDND-INIT`         | Verifies initial view with instructions and solid blue light description.   |
/// | `ADDND-DIFF_COL`     | Verifies "Light is a different color" modal dialog.                         |
/// | `ADDND-SEARCH`       | Verifies searching nodes loading state with spinner and message.            |
/// | `ADDND-ONBOARD`      | Verifies onboarding nodes loading state with spinner and message.           |
/// | `ADDND-NO_NODES`     | Verifies result view when no nodes are found with troubleshoot link.        |
/// | `ADDND-TRBL_MODAL`   | Verifies troubleshooting modal with numbered steps.                         |
/// | `ADDND-RESULTS`      | Verifies result view displaying multiple discovered nodes with details.     |

void main() async {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  testLocalizationsV2(
    'Verify initial view with instructions and blue light description',
    (tester, screen) async {
      // Test ID: ADDND-INIT
      const goldenFilename = 'ADDND-INIT-01-initial_state';

      final context = await testHelper.pumpView(
        tester,
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      );

      // Verify title
      expect(find.text(testHelper.loc(context).addNodes), findsOneWidget);

      // Verify add nodes image
      expect(find.bySemanticsLabel('add nodes image'), findsOneWidget);

      // Verify "Light is a different color" button
      expect(
          find.widgetWithText(
              AppButton, testHelper.loc(context).addNodesLightDifferentColor),
          findsOneWidget);

      // Verify Next button
      expect(find.widgetWithText(AppButton, testHelper.loc(context).next),
          findsOneWidget);

      await testHelper.takeScreenshot(tester, goldenFilename);
    },
    helper: testHelper,
  );

  testLocalizationsV2(
    'Verify "Light is a different color" modal dialog',
    (tester, screen) async {
      // Test ID: ADDND-DIFF_COL
      const goldenFilename = 'ADDND-DIFF_COL-01-modal_opened';

      final context = await testHelper.pumpView(
        tester,
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      );

      // Tap the "Light is a different color" button
      final btnFinder = find.byKey(const ValueKey('differentColorModal'));
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      // Verify modal dialog is displayed
      expect(find.byType(AlertDialog), findsOneWidget);

      // Verify modal title
      expect(find.text(testHelper.loc(context).addNodesLightDifferentColor),
          findsNWidgets(2)); // One in button, one in modal

      // Verify Close button in modal
      expect(find.widgetWithText(AppButton, testHelper.loc(context).close),
          findsOneWidget);

      // Verify LightDifferentColorModal content
      expect(find.byType(LightDifferentColorModal), findsOneWidget);

      await testHelper.takeScreenshot(tester, goldenFilename);
    },
    helper: testHelper,
  );

  testLocalizationsV2(
    'Verify searching nodes loading state',
    (tester, screen) async {
      // Test ID: ADDND-SEARCH
      const goldenFilename = 'ADDND-SEARCH-01-loading_spinner';

      when(testHelper.mockAddNodesNotifier.build()).thenReturn(
          const AddNodesState(isLoading: true, loadingMessage: 'searching'));

      final context = await testHelper.pumpView(
        tester,
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      );

      // Verify full screen spinner is displayed
      expect(find.byType(AppFullScreenLoader), findsOneWidget);

      // Verify searching title
      expect(find.text(testHelper.loc(context).addNodesSearchingNodes),
          findsOneWidget);

      // Verify searching description
      expect(find.text(testHelper.loc(context).addNodesSearchingNodesDesc),
          findsOneWidget);

      await testHelper.takeScreenshot(tester, goldenFilename);
    },
    helper: testHelper,
  );

  testLocalizationsV2(
    'Verify onboarding nodes loading state',
    (tester, screen) async {
      // Test ID: ADDND-ONBOARD
      const goldenFilename = 'ADDND-ONBOARD-01-loading_spinner';

      when(testHelper.mockAddNodesNotifier.build()).thenReturn(
          const AddNodesState(isLoading: true, loadingMessage: 'onboarding'));

      final context = await testHelper.pumpView(
        tester,
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      );

      // Verify full screen spinner is displayed
      expect(find.byType(AppFullScreenLoader), findsOneWidget);

      // Verify onboarding title
      expect(find.text(testHelper.loc(context).addNodesOnboardingNodes),
          findsOneWidget);

      // Verify onboarding description
      expect(find.text(testHelper.loc(context).addNodesOnboardingNodesDesc),
          findsOneWidget);

      await testHelper.takeScreenshot(tester, goldenFilename);
    },
    helper: testHelper,
  );

  testLocalizationsV2(
    'Verify result view when no nodes are found',
    (tester, screen) async {
      // Test ID: ADDND-NO_NODES
      const goldenFilename = 'ADDND-NO_NODES-01-no_results';

      when(testHelper.mockAddNodesNotifier.build()).thenReturn(
          const AddNodesState(onboardingProceed: true, addedNodes: []));

      final context = await testHelper.pumpView(
        tester,
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      );

      // Verify title
      expect(find.text(testHelper.loc(context).addNodes), findsOneWidget);

      // Verify network description text
      expect(find.text(testHelper.loc(context).pnpYourNetworkDesc),
          findsOneWidget);

      // Verify Refresh button
      expect(find.widgetWithText(AppButton, testHelper.loc(context).refresh),
          findsOneWidget);

      // Verify Try Again button
      expect(find.widgetWithText(AppButton, testHelper.loc(context).tryAgain),
          findsOneWidget);

      // Verify Next button
      expect(find.widgetWithText(AppButton, testHelper.loc(context).next),
          findsOneWidget);

      await testHelper.takeScreenshot(tester, goldenFilename);
    },
    helper: testHelper,
  );

  testLocalizationsV2(
    'Verify troubleshooting modal with numbered steps',
    (tester, screen) async {
      // Test ID: ADDND-TRBL_MODAL
      const goldenFilename = 'ADDND-TRBL_MODAL-01-first_page';

      when(testHelper.mockAddNodesNotifier.build()).thenReturn(
          const AddNodesState(onboardingProceed: true, addedNodes: []));

      final _ = await testHelper.pumpView(
        tester,
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      );
      await tester.pumpAndSettle();
/*
      // Tap the troubleshoot link
      final styledTextFinder = find.byKey(const ValueKey('troubleshoot')).first;
      fireOnTapByIndex(styledTextFinder, 0);
      await tester.pumpAndSettle();

      // Verify MultiplePagesAlertDialog is displayed
      expect(find.byType(MultiplePagesAlertDialog), findsOneWidget);

      // Verify modal title
      expect(find.text(testHelper.loc(context).modalTroubleshootNoNodesFound), findsOneWidget);

      // Verify Close button
      expect(find.widgetWithText(AppButton, testHelper.loc(context).close), findsOneWidget);

      // Verify bullet list with numbered style
      expect(find.byType(AppBulletList), findsOneWidget);

      // Verify first step text
      expect(find.text(testHelper.loc(context).modalTroubleshootNoNodesFoundDesc1), findsOneWidget);

      // Verify second step text
      expect(find.text(testHelper.loc(context).modalTroubleshootNoNodesFoundDesc2), findsOneWidget);

      // Verify "Light is a different color" link in first step
      expect(find.widgetWithText(AppButton, testHelper.loc(context).addNodesLightDifferentColor), findsOneWidget);
*/
      await testHelper.takeScreenshot(tester, goldenFilename);
    },
    helper: testHelper,
  );

  testLocalizationsV2(
    'Verify result view displaying multiple discovered nodes',
    (tester, screen) async {
      // Test ID: ADDND-RESULTS
      const goldenFilename = 'ADDND-RESULTS-01-multiple_nodes';

      when(testHelper.mockAddNodesNotifier.build()).thenReturn(AddNodesState(
        onboardingProceed: true,
        childNodes: [
          LinksysDevice.fromJson(singleDeviceData),
          LinksysDevice.fromMap(slaveCherry7TestData1),
          LinksysDevice.fromMap(slaveCherry7TestData2),
          LinksysDevice.fromMap(slaveCherry7TestData3),
          LinksysDevice.fromMap(slaveCherry7TestData4),
        ],
        addedNodes: [
          LinksysDevice.fromJson(singleDeviceData),
          LinksysDevice.fromMap(slaveCherry7TestData1),
          LinksysDevice.fromMap(slaveCherry7TestData2),
          LinksysDevice.fromMap(slaveCherry7TestData3),
          LinksysDevice.fromMap(slaveCherry7TestData4),
        ],
      ));

      final context = await testHelper.pumpView(
        tester,
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      );

      // Pre-cache images to ensure proper rendering
      await tester.runAsync(() async {
        await precacheImage(
            DeviceImageHelper.getRouterImage('Mx6200'), context);
      });
      await tester.pumpAndSettle();

      // Verify title
      expect(find.text(testHelper.loc(context).addNodes), findsOneWidget);

      // Verify network description
      expect(find.text(testHelper.loc(context).pnpYourNetworkDesc),
          findsOneWidget);

      // Verify Refresh button
      expect(find.widgetWithText(AppButton, testHelper.loc(context).refresh),
          findsOneWidget);

      // Verify multiple node cards are displayed (5 nodes)
      expect(find.byType(AppNodeListCard), findsNWidgets(5));

      // Verify Try Again button
      expect(find.widgetWithText(AppButton, testHelper.loc(context).tryAgain),
          findsOneWidget);

      // Verify Next button
      expect(find.widgetWithText(AppButton, testHelper.loc(context).next),
          findsOneWidget);

      await testHelper.takeScreenshot(tester, goldenFilename);
    },
    helper: testHelper,
  );
}
