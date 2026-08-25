/// The layout gate's cell screenshot dump — one PNG per measured coordinate, for
/// any family.
///
/// ## Why the spine owns this and the card family does not
///
/// The card sweep has written PNGs since #1183, and they are card-shaped by
/// construction: `dashboard_card_gate.dart` writes a *pair* (as-is plus a
/// re-pumped "recommended geometry"), names them after a column span and a tab,
/// and does it from inside the report row — which is downstream of
/// `if (significant.isEmpty) return null`. So it only ever photographs a cell that
/// **already failed**, and with the allowlist empty and all five sweeps green,
/// `build/overflow_testing/` holds zero PNGs today. That is not a bug in it: a
/// failure report is what it is for.
///
/// What no sweep could do is photograph a cell that **passed**, and that is where
/// the images are worth something:
///
/// * Four dashboard cards pass at 191px rendering unreadably (#1240 AC1) — the
///   gate is blind to it by construction, because nothing overflowed.
/// * #1349's fix trades an overflow for a **wrap**, which every cell is blind to;
///   `PageSurfaceFamily` had to decline the per-cell readability assertion in
///   writing and guard the one changed site instead.
///
/// Both are green. So this dump can be selected by a **pattern over cell ids**,
/// which no verdict-driven dump could offer, and it lives here rather than in a
/// family because all five sweeps need it and none of them owns the pump.
///
/// The other selector, [kOverflowScreenshotFailed], is the one a person reaches for
/// when a sweep goes red — the failing ids are precisely what they do not want to
/// retype, and `all` on the page sweep is 416 images to find three in. It costs one
/// thing the pattern modes do not: a boundary has to be in place *before* the pump,
/// when no verdict exists yet, so `failed` wraps every cell and throws most of the
/// wrappers away. A `RepaintBoundary` adds a layer and not a constraint, so this
/// changes no geometry — asserted in `sweep_test.dart` per cell, and provable at
/// dataset scale by running `check` after a shoot.
///
/// What it frames is therefore the **whole surface the family pumped**, not a crop
/// of the widget under test: a card cell photographs the card in its grid slot at
/// its screen width, empty page beside it and all. Cropping is family knowledge —
/// `dashboard_card_gate.dart` has its own boundary around the card for exactly that
/// reason — and a spine that guessed at it would guess differently per family.
///
/// ## It cannot make a sweep fail
///
/// A capture runs after the measurement and before the judge, inside
/// [measureOverflowCell]'s `try` — so anything it raised would be attributed to
/// the cell by invariant 3, and one mistyped directory would turn a green sweep
/// into thousands of cells that "threw". Every entry point here therefore swallows
/// its own failures and reports them by printing, the same way
/// `saveCardScreenshot` has always done. `sweep_test.dart` pins it.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pattern value that shoots every measured cell.
const String kOverflowScreenshotAll = 'all';

/// The pattern value that shoots the cells the sweep judged as failures — an
/// overflow past the tolerance, or a pump that threw.
///
/// A reserved pattern value rather than a flag alongside a pattern, so there is
/// exactly one input to explain and one rule per run. `failed` *within* a subset
/// (`failed:locale=ar`) is a composition this deliberately does not have yet: no
/// one has needed it, and the cost of shooting the failures of a whole sweep is
/// bounded by how many failures there are.
const String kOverflowScreenshotFailed = 'failed';

/// The manifest's name inside the dump directory.
const String kOverflowScreenshotManifest = 'index.tsv';

/// The manifest's first line, after `# `.
///
/// Versioned like the baseline dataset's own header for the same reason: the
/// reader is a different program, shipped in the same commit today and not
/// necessarily tomorrow.
const String kOverflowScreenshotManifestFormat = 'overflow-screenshots 1';

/// Where a cell's PNG goes, and which cells get one.
///
/// Constructed from the environment in the runner and explicitly in tests. `2.0`
/// matches the card sweep's pixel ratio, so an image out of this dump and an image
/// out of `build/overflow_testing/` are the same scale.
class OverflowScreenshotDump {
  OverflowScreenshotDump({
    required this.pattern,
    required this.dir,
    this.pixelRatio = 2.0,
  });

  /// The dump the gate runs with unless something turns it on.
  factory OverflowScreenshotDump.off() =>
      OverflowScreenshotDump(pattern: '', dir: '');

  /// Reads `OVERFLOW_PNG` and `OVERFLOW_PNG_DIR`, as a `--dart-define` or from the
  /// environment.
  ///
  /// Both spellings, in that order, because that is how every other knob in this
  /// family is read (`DUMP`, `LOCALE`, `MIN_SCREEN`) and because
  /// `tool/overflow_baseline.sh` sets the environment rather than passing defines.
  factory OverflowScreenshotDump.fromEnvironment() {
    return OverflowScreenshotDump(
      pattern:
          _read('OVERFLOW_PNG', const String.fromEnvironment('OVERFLOW_PNG')),
      dir: _read(
        'OVERFLOW_PNG_DIR',
        const String.fromEnvironment('OVERFLOW_PNG_DIR'),
      ),
    );
  }

  static String _read(String key, String define) =>
      define.isNotEmpty ? define : (Platform.environment[key] ?? '');

  /// Empty is off; [kOverflowScreenshotAll] is every cell;
  /// [kOverflowScreenshotFailed] is every cell the sweep failed; anything else is a
  /// substring of the cell id.
  ///
  /// A substring rather than a glob because the ids it selects from are already
  /// `axis=value` pairs joined by `|` — `locale=ar`, `px=191`, `card=lan_info` are
  /// the queries anyone actually wants, and each is a literal substring of the ids
  /// it should match. A glob would add syntax without adding a reachable query.
  final String pattern;

  /// The directory PNGs and the manifest are written to.
  final String dir;

  final double pixelRatio;

  /// Cell id → file name, for everything written this run. The manifest on disk is
  /// this map, appended to as it grows.
  final Map<String, String> written = {};

  bool get enabled => pattern.isNotEmpty && dir.isNotEmpty;

  /// Whether the run is selecting by verdict rather than by cell id.
  bool get shootsFailures => enabled && pattern == kOverflowScreenshotFailed;

  /// Whether the **pattern** names [cellId].
  ///
  /// False for the whole of [kOverflowScreenshotFailed] mode, where the pattern is
  /// a reserved word and not a substring to look for. Nothing stops an axis *value*
  /// from carrying the word — axis prose is family knowledge — and a mode that also
  /// matched ids would then shoot cells for two unrelated reasons at once.
  bool wants(String cellId) =>
      enabled &&
      !shootsFailures &&
      (pattern == kOverflowScreenshotAll || cellId.contains(pattern));

  /// Whether [cellId] must be pumped inside a boundary — decided **before** the
  /// pump, so before any verdict exists.
  ///
  /// This is why [kOverflowScreenshotFailed] wraps every cell: the only way to
  /// photograph a failure is to have been ready for one. The wrappers of the cells
  /// that pass are then discarded unphotographed.
  bool needsBoundary(String cellId) => shootsFailures || wants(cellId);

  /// Whether the cell just measured keeps its photograph.
  ///
  /// [failed] is the sweep's own verdict — an overflow past the tolerance, or a
  /// pump that threw — and not "any incident was collected". A sub-tolerance
  /// incident is not a failure, and a gallery that showed one would disagree with
  /// the report rows beside it.
  bool shouldCapture(String cellId, {required bool failed}) =>
      shootsFailures ? failed : wants(cellId);

  String get manifestPath => '$dir/$kOverflowScreenshotManifest';

  /// Photographs whatever [boundaryKey] wraps, recording it under [cellId].
  ///
  /// Never throws — see the library header.
  Future<void> capture(
    WidgetTester tester, {
    required String cellId,
    required GlobalKey boundaryKey,
  }) async {
    final name = overflowScreenshotFileName(
      cellId,
      taken: written.values.toSet(),
    );
    final bytes = await writeBoundaryPng(
      tester,
      boundaryKey: boundaryKey,
      path: '$dir/$name',
      pixelRatio: pixelRatio,
    );
    // Recorded only once the file exists. A manifest row for an image that was
    // never written would make `render` link a 404 — and it reports a manifest it
    // cannot reconcile as a disagreement, so a phantom row would read as the
    // dataset and the images being from different runs.
    if (bytes == null) return;
    written[cellId] = name;
    _appendToManifest(cellId, name);
  }

  /// Truncated on the first row of a run, appended after.
  ///
  /// Appending rather than collecting and flushing at the end, because there is no
  /// end: [runOverflowSweep] declares tests and owns no `tearDownAll`, and a run
  /// killed halfway through should still leave the images it took readable.
  void _appendToManifest(String cellId, String name) {
    try {
      final file = File(manifestPath);
      if (written.length == 1) {
        file.writeAsStringSync('# $kOverflowScreenshotManifestFormat\n');
      }
      file.writeAsStringSync('$cellId\t$name\n', mode: FileMode.append);
    } catch (error) {
      // ignore: avoid_print
      print('[PNG DUMP] could not write $manifestPath: $error');
    }
  }
}

/// The dump [measureOverflowCell] consults.
///
/// A library-level variable, not a getter over the environment, for one reason:
/// `OVERFLOW_PNG` is set by `tool/overflow_baseline.sh` and a test cannot set it
/// for itself, so a getter would make every case below unobservable. Lazy, so the
/// environment is still read on first use rather than at load.
OverflowScreenshotDump overflowScreenshotDump =
    OverflowScreenshotDump.fromEnvironment();

/// `page.dhcp|screen_px=320|locale=ar` → `page.dhcp__screen_px-320__locale-ar.png`.
///
/// Browsable on purpose. The folder is opened by a person comparing two widths, so
/// a name that reads back as the coordinate is worth more than a serial number —
/// and the two characters the id grammar leans on, `|` and `=`, are the two a shell
/// and a URL both dislike.
///
/// [taken] is every name already used, and the reason this is a function rather
/// than a `replaceAll` chain: an axis *value* may carry prose (`chrome.header`'s
/// mode axis read `mode=viewing, local (3 actions)` until #1356), so two distinct
/// ids can sanitise to one name. Two manifest rows pointing at one image would show
/// a reader the wrong screenshot for a cell, which is the exact failure this
/// feature exists to prevent.
///
/// The name returned is **added to [taken]** — reserved, not merely checked, so two
/// calls in a row over one set cannot both be handed the same file.
String overflowScreenshotFileName(String cellId, {required Set<String> taken}) {
  final base = cellId
      .replaceAll('|', '__')
      .replaceAll('=', '-')
      .replaceAll(RegExp(r'[^A-Za-z0-9._\-]'), '_');
  var name = '$base.png';
  var n = 1;
  while (taken.contains(name)) {
    n++;
    name = '$base~$n.png';
  }
  taken.add(name);
  return name;
}

/// Writes the render tree under [boundaryKey] to [path], returning the byte count
/// or `null` if nothing was written.
///
/// Never throws: a dump is diagnostic tooling that runs inside a gate, and a gate
/// that goes red because it could not take a photograph would be worse than one
/// that takes none.
///
/// [skipIfExists] keeps an existing file, which is the card sweep's long-standing
/// behaviour (`saveCardScreenshot`) and deliberately not this dump's — a re-shoot
/// after a layout change must overwrite, or the folder silently mixes two trees.
Future<int?> writeBoundaryPng(
  WidgetTester tester, {
  required GlobalKey boundaryKey,
  required String path,
  double pixelRatio = 2.0,
  bool skipIfExists = false,
}) async {
  int? written;
  // Two nested guards, for two different throws. The inner one catches the capture
  // itself, and has to be inside the callback because `runAsync` runs it in a zone
  // whose unhandled errors are reported as test failures rather than thrown back
  // here. The outer one catches `runAsync` — which throws when it is called at a
  // moment the binding forbids, and this dump is now also called from
  // `measureOverflowCell`'s `catch`, i.e. after a cell has already thrown.
  try {
    // `toImage` is asynchronous work the test binding will not otherwise run.
    await tester.binding.runAsync(() async {
      try {
        final file = File(path);
        if (skipIfExists && file.existsSync()) return;

        final boundary = boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) {
          // ignore: avoid_print
          print('[PNG DUMP FAILED] boundary is null for $path');
          return;
        }
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          // ignore: avoid_print
          print('[PNG DUMP FAILED] byteData is null for $path');
          return;
        }
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData.buffer.asUint8List());
        written = byteData.lengthInBytes;
      } catch (error, stack) {
        // ignore: avoid_print
        print('[PNG DUMP EXCEPTION] Failed to save $path: $error\n$stack');
      }
    });
  } catch (error) {
    // ignore: avoid_print
    print('[PNG DUMP EXCEPTION] Could not run the capture for $path: $error');
  }
  return written;
}
