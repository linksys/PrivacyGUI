import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/call_support/call_support_main_region_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/call_support/call_support_more_region_view.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../common/testable_router.dart';

void main() async {
  setUp(() {});

  testLocalizations('Troubleshooter - call support more: Latin America',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.latinAmerica},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Mexico detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.latinAmerica},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).first;
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Europe',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Belgium detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(0);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Denmark detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(1);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Netherlands detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(2);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Norway detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(3);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Sweden detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(4);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: UK detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(5);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations(
      'Troubleshooter - call support more: Middle Ease And Africa',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.middleEastAndAfrica},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Saudi Arabia detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.middleEastAndAfrica},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(0);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations(
      'Troubleshooter - call support more: United Arab Emirates detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.middleEastAndAfrica},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(1);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Asia Pacific',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Taiwan detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(0);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Hong Kong detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(1);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: China detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(2);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Japan detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(3);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Singapore detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(4);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: Australia detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(5);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support more: New Zealand detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(6);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });
}
