// The source-scan half of #1492 (phase 2 of epic #1474).
//
// The decision guarded: `UspDashboardPreset.remote` is the layout Remote
// Assistance *forces*, never one a user picks, so no picker may enumerate the
// raw enum. `preset_selection_dialog_test.dart` proves that for the one picker
// that exists today by pumping it; this file proves it for the ones that do not
// exist yet.
//
// How it could silently revert: two ways, and a widget test sees neither.
//
//   1. A SECOND picker. `showPresetSelectionDialog` already has two call sites
//      (`usp_sliver_dashboard_view.dart`, `usp_layout_settings_panel.dart`), so
//      a third surface offering presets is an ordinary thing to add — and it
//      would reach for `UspDashboardPreset.values` because that is the obvious
//      spelling. The existing dialog's own test stays green throughout.
//   2. A "tidy-up" of the one call site. `.selectable` reads like a redundant
//      alias for `.values` to anyone who has not read #1492, and swapping it
//      back is a one-word edit that no compiler objects to. That single edit
//      *is* caught by the widget test — this file names the invariant so the
//      failure explains itself instead of reading as a missing card.
//
// Why a source scan rather than a wider widget test: the target is code that has
// not been written. There is nothing to pump.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';

/// The one legitimate `UspDashboardPreset.values` read in `lib/`: resolving a
/// persisted preset name back to its value. It enumerates for *lookup*, not for
/// display, so it is exempt — and pinned here by path, so a new exemption has to
/// be argued for in a diff rather than added silently.
const _valuesExemptions = <String>{
  'lib/page/dashboard/models/usp_layout_preferences.dart',
};

void main() {
  final libDir = Directory('lib');

  List<File> dartFiles(Directory dir) => dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  group('the remote preset stays out of every picker', () {
    test('lib/ reads UspDashboardPreset.values only to resolve a stored name',
        () {
      final offenders = <String>[];
      for (final file in dartFiles(libDir)) {
        final relative = file.path;
        if (_valuesExemptions.contains(relative)) continue;
        if (file.readAsStringSync().contains('UspDashboardPreset.values')) {
          offenders.add(relative);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'These files enumerate every preset, including `remote`, which '
            'Remote Assistance forces and no user may choose (#1492). Offer '
            '`UspDashboardPreset.selectable` instead — or, if the read really is '
            'a lookup rather than a list to render, add the path to '
            '_valuesExemptions with a reason.',
      );
    });

    test('the picker offers .selectable', () {
      final dialog = File(
        'lib/page/dashboard/views/dialogs/preset_selection_dialog.dart',
      );
      expect(dialog.existsSync(), isTrue,
          reason: 'the picker moved; re-point this scan at its new home');

      // Asserts the identifier only, not the call chain. `dart format` breaks a
      // long cascade onto the next line (`...UspDashboardPreset.selectable\n
      // .map((preset) {`), and matching `.selectable.map` would then fail with a
      // message claiming a filter regression when the diff was pure formatting.
      expect(
        dialog.readAsStringSync(),
        contains('UspDashboardPreset.selectable'),
        reason: 'the picker must render the filtered list, not the raw enum',
      );
    });

    // `selectable` is a filter, not a deletion. Phase 8 of #1474 deletes dead
    // config, and this states that `remote` is not part of it: RA still needs
    // the value, its layout and its display metadata.
    test('remote is still a value RA can force', () {
      expect(UspDashboardPreset.values, contains(UspDashboardPreset.remote));
      expect(
        UspDashboardPreset.selectable,
        isNot(contains(UspDashboardPreset.remote)),
      );
    });
  });
}
