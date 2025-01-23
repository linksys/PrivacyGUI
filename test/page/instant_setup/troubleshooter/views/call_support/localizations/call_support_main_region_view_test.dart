import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/call_support/call_support_main_region_view.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../common/testable_router.dart';

void main() async {
  setUp(() {});

  testLocalizations('Troubleshooter - call support main',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMainRegionView(),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
  });
  testLocalizations('Troubleshooter - call support main: America detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMainRegionView(),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).first;
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - call support main: Canada detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMainRegionView(),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(1);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });
}
