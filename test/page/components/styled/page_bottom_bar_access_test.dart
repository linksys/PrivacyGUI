import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

import '../../../common/theme_data.dart';

void main() {
  Future<int> tapSave(
    WidgetTester tester, {
    required AccessPolicy policy,
    required bool isWrite,
  }) async {
    var taps = 0;
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [accessPolicyProvider.overrideWithValue(policy)],
      child: MaterialApp(
        theme: mockLightThemeData,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            CustomResponsive(child: child ?? const SizedBox.shrink()),
        home: StyledAppPageView(
          hideTopbar: true,
          bottomBar: PageBottomBar(
            isPositiveEnabled: true,
            isWrite: isWrite,
            onPositiveTap: () => taps++,
          ),
          child: (context, constraints) => const SizedBox.shrink(),
        ),
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    return taps;
  }

  const readOnly = AccessPolicy(canWrite: false);

  // #1637: the save that would be refused is disabled up front, so the user is
  // not left filling in a form only to be turned away on submit.
  testWidgets('a save that writes is disabled in read-only mode',
      (tester) async {
    expect(await tapSave(tester, policy: readOnly, isWrite: true), 0);
    expect(find.byTooltip('This feature is unavailable in remote mode'),
        findsOneWidget,
        reason: 'a disabled button should say why');
  });

  // Rule editors and pickers use the same bar only to hand a value back to the
  // page that opened them; nothing reaches the router, so they stay usable.
  testWidgets('a bar that does not write stays enabled in read-only mode',
      (tester) async {
    expect(await tapSave(tester, policy: readOnly, isWrite: false), 1);
  });

  testWidgets('a save that writes works with full access', (tester) async {
    expect(await tapSave(tester, policy: AccessPolicy.full, isWrite: true), 1);
  });

  // #1637: a menu row that changes the router (Restart network) is blocked the
  // same way; one that only navigates is not.
  group('page menu', () {
    Future<(int, int)> tapMenu(WidgetTester tester, AccessPolicy policy) async {
      var writes = 0, navigations = 0;
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [accessPolicyProvider.overrideWithValue(policy)],
        child: MaterialApp(
          theme: mockLightThemeData,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              CustomResponsive(child: child ?? const SizedBox.shrink()),
          home: StyledAppPageView(
            hideTopbar: true,
            menu: PageMenu(items: [
              PageMenuItem(
                  label: 'Restart',
                  icon: null,
                  isWrite: true,
                  onTap: () => writes++),
              PageMenuItem(
                  label: 'Open page', icon: null, onTap: () => navigations++),
            ]),
            child: (context, constraints) => const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Restart'), warnIfMissed: false);
      await tester.tap(find.text('Open page'));
      await tester.pump();
      return (writes, navigations);
    }

    testWidgets('a writing row is blocked in read-only mode', (tester) async {
      expect(await tapMenu(tester, readOnly), (0, 1));
    });

    testWidgets('both rows work with full access', (tester) async {
      expect(await tapMenu(tester, AccessPolicy.full), (1, 1));
    });
  });
}
