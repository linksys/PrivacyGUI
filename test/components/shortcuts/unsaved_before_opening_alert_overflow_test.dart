@Tags(['layout-gate', 'overflow'])
library;

// The prompt raised before one editable page opens another (#1433), swept at
// the narrowest supported screen and a desktop one × all 26 locales. The cells
// are declared through `runOverflowSweep`; what the family measures in each,
// and why, is in `test/layout_gate/families/unsaved_prompt_family.dart`.
//
// The two tests after the sweep are its premise. `AppDialog` lays the three
// actions in an `OverflowBar`, which is one row while they fit and a stack when
// they do not. The dialog's width does not follow the screen past a phone, so
// which of the two a cell gets is decided by the locale's label lengths, and
// the sweep only means "both layouts are clean" if both are among its cells.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../layout_gate/families/unsaved_prompt_family.dart';
import '../../layout_gate/surface.dart';
import '../../layout_gate/sweep.dart';
import '../../util/app_test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  runOverflowSweep(
    family: const UnsavedPromptFamily(),
    expectedCellCount: 52, // 2 screen widths × 26 locales
  );

  // Measured 2026-11-10: on the desktop screen the six locales with the
  // shortest labels (ar, ja, ko, vi, zh, zh_TW) fit the three actions on one row
  // and the other twenty stack them; on the narrowest screen all 26 stack.
  group('showUnsavedBeforeOpeningAlert - both action layouts are swept', () {
    Future<bool> onOneRow(WidgetTester tester, Locale locale) async {
      await setLayoutSurface(
          tester, Size(kUnsavedPromptScreenWidths.last, 900));
      await tester.pumpWidget(unsavedPromptHost(locale));
      await tester.pumpAndSettle();
      await openUnsavedPrompt(tester);
      return unsavedPromptActionsOnOneRow(tester);
    }

    testWidgets('one row: ja on the desktop screen', (tester) async {
      expect(await onOneRow(tester, const Locale('ja')), isTrue);
    });

    testWidgets('stacked: en on the desktop screen', (tester) async {
      expect(await onOneRow(tester, const Locale('en')), isFalse);
    });
  });
}
