import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/components/styled/menus/widgets/top_navigation_menu.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Regression coverage for PrivacyGUI#1158.
///
/// When a top-navigation chip tap is rejected downstream (e.g. the unsaved
/// changes dialog "Go back" cancels the navigation), `widget.selected` never
/// changes. AppChipGroup owns its selection state internally and optimistically
/// moves the highlight on tap, so without a re-sync the highlight would stay
/// stuck on the tapped-but-rejected destination. TopNavigationMenu must force
/// the highlight back to the still-current option after every tap.
void main() {
  // A dark ThemeData carrying AppDesignTheme so TopNavigationMenu does not fall
  // back to getIt (which is unregistered in the test host) and AppChipGroup's
  // DesignSystem assertion is satisfied.
  final darkTheme = AppTheme.create(
    brightness: Brightness.dark,
    seedColor: Colors.blue,
    designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
  );

  const items = [NaviType.home, NaviType.menu, NaviType.support];

  Widget buildHost({
    required NaviType selected,
    required void Function(int) onItemClick,
  }) {
    return MaterialApp(
      theme: darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TopNavigationMenu(
          items: items,
          selected: selected,
          onItemClick: onItemClick,
        ),
      ),
    );
  }

  /// Returns true when the chip carrying [label] is rendered as selected.
  /// AppChipGroup renders the selected chip's label in bold (see
  /// app_chip_group.dart: `fontWeight: isSelected ? FontWeight.bold : normal`).
  bool isChipSelected(WidgetTester tester, String label) {
    final appText = tester.widget<AppText>(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(AppText),
          )
          .first,
    );
    return appText.fontWeight == FontWeight.bold;
  }

  testWidgets(
      'reverts highlight to the original option when navigation is cancelled '
      '(PrivacyGUI#1158)', (tester) async {
    // Home is the current page. A tap on another chip is REJECTED downstream:
    // onItemClick does not change `selected` (mimics "Go back" in the unsaved
    // changes dialog blocking the navigation).
    await tester.pumpWidget(buildHost(
      selected: NaviType.home,
      onItemClick: (_) {
        /* navigation blocked — selected stays on Home */
      },
    ));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TopNavigationMenu));
    final homeLabel = NaviType.home.resloveLabel(context);
    final menuLabel = NaviType.menu.resloveLabel(context);

    // Baseline: Home highlighted, Menu not.
    expect(isChipSelected(tester, homeLabel), isTrue,
        reason: 'Home should be the initially selected option');
    expect(isChipSelected(tester, menuLabel), isFalse);

    // Act: tap Menu. AppChipGroup optimistically moves the highlight, then the
    // navigation is cancelled (selected unchanged).
    await tester.tap(find.text(menuLabel));
    await tester.pumpAndSettle();

    // Assert (the bug): highlight must be back on Home, NOT stuck on Menu.
    expect(isChipSelected(tester, homeLabel), isTrue,
        reason:
            'After a cancelled navigation the highlight must revert to Home');
    expect(isChipSelected(tester, menuLabel), isFalse,
        reason: 'The rejected destination must not stay highlighted (#1158)');
  });

  testWidgets(
      'follows the highlight when navigation is confirmed (selected updates)',
      (tester) async {
    // A parent that DOES accept the navigation: it rebuilds with the new
    // selected value, mimicking a confirmed route change.
    await tester.pumpWidget(
      _ConfirmingHost(items: items, theme: darkTheme),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TopNavigationMenu));
    final homeLabel = NaviType.home.resloveLabel(context);
    final menuLabel = NaviType.menu.resloveLabel(context);

    expect(isChipSelected(tester, homeLabel), isTrue);

    await tester.tap(find.text(menuLabel));
    await tester.pumpAndSettle();

    // Confirmed navigation: highlight follows to Menu.
    expect(isChipSelected(tester, menuLabel), isTrue,
        reason: 'A confirmed navigation must move the highlight to the target');
    expect(isChipSelected(tester, homeLabel), isFalse);
  });
}

/// Host that accepts navigation by updating `selected` on tap.
class _ConfirmingHost extends StatefulWidget {
  final List<NaviType> items;
  final ThemeData theme;
  const _ConfirmingHost({required this.items, required this.theme});

  @override
  State<_ConfirmingHost> createState() => _ConfirmingHostState();
}

class _ConfirmingHostState extends State<_ConfirmingHost> {
  NaviType _selected = NaviType.home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: widget.theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TopNavigationMenu(
          items: widget.items,
          selected: _selected,
          onItemClick: (index) =>
              setState(() => _selected = widget.items[index]),
        ),
      ),
    );
  }
}
