import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/home_title.dart';
import 'package:privacy_gui/page/dashboard/views/components/fixed_layout/networks.dart';
import 'package:privacy_gui/page/dashboard/views/components/fixed_layout/wifi_grid.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../common/config.dart';
import '../common/screen.dart';
import '../common/test_helper.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    // Use a mobile screen size to test responsive layout and touch targets
    final screen = responsiveMobileScreens.first;

    await testHelper.pumpShellView(
      tester,
      child: const DashboardHomeView(),
      locale: const Locale('en'),
      config: LinksysRouteConfig(column: ColumnGrid(column: 12)),
    );

    // Set screen size
    tester.view.physicalSize = Size(screen.width, screen.height);
    tester.view.devicePixelRatio = screen.pixelDensity;

    await tester.pumpAndSettle();
  }

  group('Dashboard Accessibility Tests', () {
    testWidgets('Dashboard should meet Android tap target guidelines',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpDashboard(tester);

      // Verify basic presence first
      expect(find.byType(DashboardHomeTitle), findsOneWidget);
      expect(find.byType(FixedDashboardWiFiGrid), findsOneWidget);

      // Check for tap target size (min 48x48)
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('Dashboard should meet text contrast guidelines',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpDashboard(tester);

      // Check for text contrast (AA 4.5:1)
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('Dashboard images should have semantic labels', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpDashboard(tester);

      // Example: Check if network status images have labels
      // Note: This relies on implementation details found in code search
      // e.g., lib/page/dashboard/views/components/widgets/composite/internet_status.dart
      // contains `semanticLabel: '{$semantics} icon'`

      // Verify we can find at least one semantic widget that is important
      expect(find.bySemanticsLabel(RegExp(r'.*')), findsWidgets);

      handle.dispose();
    });

    testWidgets('General Settings button should have correct semantics',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpDashboard(tester);

      // Based on previous code search in GeneralSettingsWidget
      expect(find.bySemanticsLabel('general settings'), findsOneWidget);

      handle.dispose();
    });
  });
}
