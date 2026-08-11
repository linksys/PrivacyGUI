@Tags(['ui'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:ui_kit_library/ui_kit.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// White-box tests for [UspInfoRow] label sizing (#1231, T13).
///
/// The label column must be sized from the width the ROW is actually given,
/// not from the screen width. Inside a shrunken dashboard card the two are
/// unrelated: a screen-derived label over-claims the column and the value is
/// silently clipped by the card surface with no RenderFlex overflow raised.
/// These tests pin the fix by pumping the row inside a narrow box on a WIDE
/// surface — the exact case where the old `context.colWidth()` misbehaved.
void main() {
  /// Pumps a single [UspInfoRow] constrained to [rowWidth] on a wide surface,
  /// so the label sizing can only be correct if it reads the row's own width.
  Future<void> pumpRow(
    WidgetTester tester, {
    required double rowWidth,
    String label = 'IP Address',
    String value = '192.168.1.100',
  }) async {
    await tester.binding.setSurfaceSize(const Size(1400, 800));
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: _testTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: rowWidth,
              child: UspInfoRow(label: label, value: value),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The label lives in the first [SizedBox] inside the [UspInfoRow]'s Row.
  double labelBoxWidth(WidgetTester tester) {
    final sizedBox = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(UspInfoRow),
        matching: find.byType(SizedBox),
      ),
    );
    return sizedBox.width!;
  }

  testWidgets('label column is 2/12 of the ROW width, not the screen width',
      (tester) async {
    // On a 1400px screen, the old screen-derived colWidth(2) would produce a
    // label far wider than 2/12 of a 191px card. The fix ties it to the row.
    const rowWidth = 191.0;
    await pumpRow(tester, rowWidth: rowWidth);

    final labelWidth = labelBoxWidth(tester);
    expect(labelWidth, closeTo(rowWidth * 2 / 12, 0.5),
        reason: 'label column must be derived from the 191px row, not 1400px');
  });

  testWidgets('label column shrinks proportionally with the given row width',
      (tester) async {
    await pumpRow(tester, rowWidth: 191.0);
    final narrow = labelBoxWidth(tester);

    await pumpRow(tester, rowWidth: 600.0);
    final wide = labelBoxWidth(tester);

    // Screen never changed (1400px). If sizing were screen-derived, narrow and
    // wide would be identical. They must differ, and scale ~4:1 with the width.
    expect(wide, greaterThan(narrow));
    expect(wide / narrow, closeTo(600.0 / 191.0, 0.05));
  });

  testWidgets('value keeps the remaining width so it is legible, not clipped',
      (tester) async {
    const rowWidth = 191.0;
    await pumpRow(tester, rowWidth: rowWidth, value: '255.255.255.255');

    final labelWidth = labelBoxWidth(tester);
    // The Expanded value gets everything the label leaves — the majority of the
    // card at the narrowest realization (~5/6 of the row), rather than being
    // squeezed to a few pixels the way a screen-sized label would have left it.
    final valueRegion = rowWidth - labelWidth;
    expect(valueRegion, greaterThan(rowWidth * 0.5),
        reason: 'value must retain more than half the row to stay legible');
  });
}
