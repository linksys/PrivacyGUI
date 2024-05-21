import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/menu_card.dart';

import '../../../common/config.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_widget.dart';
import '../../../mock_notifiers/mock_auth_notifier.dart';

void main() {
  late AuthNotifier mockAuthNotifier;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
  });

  testWidgets('Test Dashboard Menu', (tester) async {
    final provider = ProviderContainer();
    await tester.pumpWidget(
      testableWidget(
        overrides: [authProvider.overrideWith(() => mockAuthNotifier)],
        parent: provider,
        child: const DashboardMenuView(),
      ),
    );
    mockAuthNotifier.state =
        const AsyncData(AuthState(loginType: LoginType.remote));

    await tester.pumpAndSettle();

    final titleFinder = find.text('Menu');
    expect(titleFinder, findsOneWidget);
    final menuCardFinder = find.byType(AppMenuCard);
    expect(menuCardFinder, findsNWidgets(8));
  });

  testResponsiveWidgets(
    'Test menu responsive layout with mobile size variants',
    variants: responsiveMobileVariants,
    (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const DashboardMenuView(),
        ),
      );

      final moreFinder = find.byIcon(LinksysIcons.moreHoriz);
      expect(moreFinder, findsOneWidget);
    },
  );

  testResponsiveWidgets(
    'Test menu responsive layout with desktop size variants',
    variants: responsiveDesktopVariants,
    (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const DashboardMenuView(),
        ),
      );

      final moreFinder = find.byIcon(LinksysIcons.moreHoriz);
      expect(moreFinder, findsNothing);

      final subMenuTitleFinder = find.text('My Network');
      expect(subMenuTitleFinder, findsOneWidget);
      final restartNetworkMenuIconFinder = find.byIcon(LinksysIcons.restartAlt);
      final restartNetworkMenuLabelFinder = find.text('Restart Network');
      expect(restartNetworkMenuIconFinder, findsOneWidget);
      expect(restartNetworkMenuLabelFinder, findsOneWidget);
    },
  );

  testResponsiveWidgets(
    'Test menu responsive layout with mobile size variants has one column',
    variants: ValueVariant({device320w}),
    (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const DashboardMenuView(),
        ),
      );

      final gridViewFinder = find.byType(GridView);
      final gridView = tester.widget<GridView>(gridViewFinder);
      final gridDelegte =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(gridDelegte.crossAxisCount, 1);
    },
  );

  testResponsiveWidgets(
    'Test menu responsive layout with mobile size variants has two column',
    variants: ValueVariant({device480w, device744w}),
    (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const DashboardMenuView(),
        ),
      );

      final gridViewFinder = find.byType(GridView);
      final gridView = tester.widget<GridView>(gridViewFinder);
      final gridDelegte =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(gridDelegte.crossAxisCount, 2);
    },
  );

  testResponsiveWidgets(
    'Test menu responsive layout with mobile size variants has three column',
    variants: ValueVariant({device1280w, device1440w}),
    (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const DashboardMenuView(),
        ),
      );

      final gridViewFinder = find.byType(GridView);
      final gridView = tester.widget<GridView>(gridViewFinder);
      final gridDelegte =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(gridDelegte.crossAxisCount, 3);
    },
  );

  testResponsiveWidgets(
    'Test tapping more button on mobile variants',
    variants: responsiveMobileVariants,
    (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const DashboardMenuView(),
        ),
      );

      final moreFinder = find.byIcon(LinksysIcons.moreHoriz);
      expect(moreFinder, findsOneWidget);
      await tester.tap(moreFinder);
      await tester.pumpAndSettle();

      // check bottom sheet displayed
      final bottomSheetFinder = find.byType(BottomSheet);
      expect(bottomSheetFinder, findsOneWidget);

      // check contents on the bottom sheet
      final subMenuTitleFinder = find.text('My Network');
      expect(subMenuTitleFinder, findsOneWidget);
      final restartNetworkMenuIconFinder = find.byIcon(LinksysIcons.restartAlt);
      final restartNetworkMenuLabelFinder = find.text('Restart Network');
      expect(restartNetworkMenuIconFinder, findsOneWidget);
      expect(restartNetworkMenuLabelFinder, findsOneWidget);
    },
  );

  testResponsiveWidgets(
    'Test tapping restart network button on mobile variants',
    variants: responsiveMobileVariants,
    (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const DashboardMenuView(),
        ),
      );

      final moreFinder = find.byIcon(LinksysIcons.moreHoriz);
      expect(moreFinder, findsOneWidget);
      await tester.tap(moreFinder);
      await tester.pumpAndSettle();

      // check bottom sheet displayed
      final bottomSheetFinder = find.byType(BottomSheet);
      expect(bottomSheetFinder, findsOneWidget);

      // check contents on the bottom sheet
      final subMenuTitleFinder = find.text('My Network');
      expect(subMenuTitleFinder, findsOneWidget);
      final restartNetworkMenuLabelFinder = find.text('Restart Network');
      await tester.tap(restartNetworkMenuLabelFinder);
      await tester.pumpAndSettle();

      // check dialog displayed
      final dialogFinder = find.byType(Dialog);
      expect(dialogFinder, findsOneWidget);

      // check contents on the dialog
      final dialogTitleFinder = find.text('Alert!');
      final dialogMessageFinder =
          find.text('Restart router will take some time');
      final dialogOkFinder = find.text('Ok');
      final dialogCancelFinder = find.text('Cancel');
      expect(dialogTitleFinder, findsOneWidget);
      expect(dialogMessageFinder, findsOneWidget);
      expect(dialogOkFinder, findsOneWidget);
      expect(dialogCancelFinder, findsOneWidget);
    },
  );

  testResponsiveWidgets(
    'Test tapping restart network button on desktop variants',
    variants: responsiveDesktopVariants,
    (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const DashboardMenuView(),
        ),
      );

      // check contents on the bottom sheet
      final subMenuTitleFinder = find.text('My Network');
      expect(subMenuTitleFinder, findsOneWidget);
      final restartNetworkMenuLabelFinder = find.text('Restart Network');
      await tester.tap(restartNetworkMenuLabelFinder);
      await tester.pumpAndSettle();

      // check dialog displayed
      final dialogFinder = find.byType(Dialog);
      expect(dialogFinder, findsOneWidget);

      // check contents on the dialog
      final dialogTitleFinder = find.text('Alert!');
      final dialogMessageFinder =
          find.text('Restart router will take some time');
      final dialogOkFinder = find.text('Ok');
      final dialogCancelFinder = find.text('Cancel');
      expect(dialogTitleFinder, findsOneWidget);
      expect(dialogMessageFinder, findsOneWidget);
      expect(dialogOkFinder, findsOneWidget);
      expect(dialogCancelFinder, findsOneWidget);
    },
  );
}
