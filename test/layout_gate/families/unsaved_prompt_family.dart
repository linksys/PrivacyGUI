/// The sweep family for `showUnsavedBeforeOpeningAlert` — the prompt one
/// editable page raises before it opens another (linksys/PrivacyGUI#1433).
///
/// A dialog, not a card or a page, so neither of the existing families renders
/// it. Its axes are the two things its layout turns on: the screen it is shown
/// on, which bounds the dialog's width, and the locale, which sets the length of
/// the three action labels. `AppDialog` lays the actions in an `OverflowBar`, so
/// they share one row while they fit and stack when they do not — and the suite
/// checks that both shapes are among the measured cells, or one of them would be
/// a layout this sweep never saw.
///
/// The prompt is opened from a button inside [pageSurfaceHost], the same
/// theme/locale/router tree a real page is measured in, so the dialog is laid
/// out exactly as it would be over the page that raises it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../util/dashboard/text_readability_probe.dart';
import '../collector.dart';
import '../locale_tag.dart';
import '../sweep.dart';
import 'page_surface_family.dart';

/// The screens the prompt is measured on: the product's narrowest supported
/// screen, where the dialog is at its narrowest, and a desktop one, where it is
/// at its widest.
const kUnsavedPromptScreenWidths = <double>[320, 1280];

const _screenHeight = 900.0;

/// The three action identifiers, in the order the dialog lays them out.
const kUnsavedPromptActions = <String>[
  'unsaved-open-go-back',
  'unsaved-open-discard',
  'unsaved-open-save',
];

Finder unsavedPromptAction(String identifier) => find.byWidgetPredicate(
      (w) => w is AppButton && w.identifier == identifier,
      description: "AppButton(identifier: '$identifier')",
    );

/// The host: an empty page with one button that raises the prompt.
Widget unsavedPromptHost(Locale locale) => pageSurfaceHost(
      view: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: kOpenUnsavedPromptKey,
              onPressed: () =>
                  showUnsavedBeforeOpeningAlert(context, canSave: true),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      locale: locale,
    );

const kOpenUnsavedPromptKey = Key('open_unsaved_prompt');

/// Opens the prompt and checks it is there to be measured.
Future<void> openUnsavedPrompt(WidgetTester tester) async {
  await tester.tap(find.byKey(kOpenUnsavedPromptKey));
  await settleIgnoringAnimations(tester);
  expect(find.byType(AppDialog), findsOneWidget,
      reason: 'the button must open the prompt, or nothing below measures it');
}

/// Whether the three actions share one row (true) or are stacked (false).
bool unsavedPromptActionsOnOneRow(WidgetTester tester) {
  final tops = {
    for (final id in kUnsavedPromptActions)
      tester.getTopLeft(unsavedPromptAction(id)).dy.round(),
  };
  return tops.length == 1;
}

class UnsavedPromptFamily extends OverflowSurfaceFamily {
  const UnsavedPromptFamily();

  @override
  String get name => 'dialog.unsaved_before_opening';

  @override
  List<String> get axisNames => const ['screen_px'];

  @override
  Iterable<OverflowSweepCell> enumerateCells() => [
        for (final width in kUnsavedPromptScreenWidths)
          for (final locale in AppLocalizations.supportedLocales)
            OverflowSweepCell(
              axes: {'screen_px': width.toStringAsFixed(0)},
              locale: locale,
              surfaceSize: Size(width, _screenHeight),
              build: () => unsavedPromptHost(locale),
            ),
      ];

  /// Opens the prompt — inside the collector, so its overflow is this cell's —
  /// and asks the two questions an overflow cannot answer: was any text cut
  /// (an `AppButton` ellipsises its own label, so a too-long label *fits*), and
  /// was a word broken in two.
  @override
  Future<void> onCellSettled(
      WidgetTester tester, OverflowSweepCell cell) async {
    await openUnsavedPrompt(tester);
    final tag = localeTag(cell.locale);
    final l = lookupAppLocalizations(cell.locale);

    final texts = <String, Finder>{
      'title': find.text(l.unsavedChangesTitle),
      'message': find.text(l.unsavedChangesBeforeOpeningDesc),
      for (final id in kUnsavedPromptActions)
        id: find.descendant(
            of: unsavedPromptAction(id), matching: find.byType(RichText)),
    };
    for (final MapEntry(key: what, value: finder) in texts.entries) {
      expect(finder, findsOneWidget, reason: '$tag: $what not found');
      final paragraph = tester.paragraphOf(finder);
      final numbers = 'granted ${paragraph.size.width.toStringAsFixed(1)}px, '
          'widest token ${tester.widestTokenWidth(finder).toStringAsFixed(1)}px, '
          'whole string ${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px';
      expect(tester.isTextClipped(finder), isFalse,
          reason: '$tag ${cell.axes}: $what is cut off — $numbers');
      if (!kLocalesWithoutWordSpaces.contains(tag)) {
        expect(tester.hasSplitToken(finder), isFalse,
            reason: '$tag ${cell.axes}: $what broken mid-word — $numbers');
      }
    }
  }
}
