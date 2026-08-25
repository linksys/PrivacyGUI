import 'dart:convert';
import 'dart:io';

// Imported directly rather than through `overflow_probe.dart`'s re-export, and
// deliberately so rather than as a tidy-up: since #1340 the probe is a shim that
// re-exports `test/layout_gate/collector.dart`, and the collector imports *this*
// file for [OverflowCell] and [emitOverflowBaselineRecord]. Reaching the parser
// through the probe would therefore put this file in a two-library cycle —
// legal in Dart, and pointless, because [OverflowIncident] and
// [kOverflowTolerancePx] are defined in `incident.dart` and the probe only
// forwards them. This file's own import of the golden framework's second parser
// went in #1351, and #1339 deleted that parser outright — so `incident.dart` is
// now the only overflow parser anything in the repo can reach. See the record
// builder below.
import '../layout_gate/incident.dart';

/// Capture side of the sweep baselines (#1337).
///
/// ## What this is for
///
/// Epic #1335 rewrites four overflow sweeps onto one framework, and every one of
/// those ports is verified by the same claim: *the failure set is identical, cell
/// by cell*. The main card sweep alone measures 1,917 coordinates, so that claim is not
/// checkable by eye, and #1321 is the standing proof of what an unchecked signal
/// change costs — a fixture whose lease expired in 2024 turned a red gate green
/// and nothing said so.
///
/// So each sweep emits, per measured coordinate, one line of machine-readable
/// text: the cell it measured and every overflow it saw there, with each
/// incident's source location. `flutter test --reporter json` carries those lines
/// out as `print` events, `test_scripts/overflow_baseline.dart` turns them into a
/// sorted TSV dataset, and two datasets are compared with a plain diff.
///
/// Capture through `tool/overflow_baseline.sh`, which knows the five sweeps and
/// how the stream has to be redirected — `--file-reporter json:<file>` drops
/// records silently, for the reason spelled out where the extractor rejects it.
///
/// ## Two properties the dataset needs, and where they come from
///
/// * **A clean cell is a row, not an absence.** Emission happens whether or not
///   the pump found anything, so "nobody measured this" and "this was measured
///   and was clean" are different lines rather than the same silence. A port that
///   drops a cell therefore fails the diff instead of reading as a pass.
/// * **The coordinate is intrinsic, not the test's name.** #1335 has already
///   frozen a regrouping — the ported framework groups by every axis except
///   locale and loops locale inside one test — so test names and test counts
///   change by design. A dataset keyed on them would diff 100% after the port and
///   prove nothing. Hence [OverflowCell]: the sweep names its own axes, and the
///   ported framework's obligation is to name the same ones with the same values.
///
/// ## What it deliberately does not record
///
/// No timestamps, no run ids, no durations, no test names, no failure prose — the
/// dataset has to be byte-identical across two runs of unchanged code, and the
/// port is allowed to reword every message it prints.

/// Marks a baseline record on stdout.
///
/// Deliberately unlike anything else the sweeps print (the allowlist notice, the
/// PNG dump lines): the extractor takes marked lines only, so ordinary logging
/// from a card under test can never be read as a measurement.
const String kOverflowBaselineMarker = '#LAYOUT-CELL#';

/// Overrides [isOverflowBaselineCaptureEnabled] for the tests that observe the
/// emitter. Capture is normally gated on the environment, which a test in the
/// same process cannot set.
bool? debugOverflowBaselineCapture;

/// Whether the sweeps should emit baseline records.
///
/// Off by default, and it must stay that way: the five sweeps run in the PR gate
/// on every push, where ~4,000 extra lines have no reader. Turned on by
/// `OVERFLOW_BASELINE=1` in the environment — an environment variable rather than
/// a `--dart-define` so switching it does not invalidate the compiled kernel and
/// make every capture pay a cold build. Both spellings of the define are read too,
/// for symmetry with the sweeps' own `LOCALE` / `MIN_SCREEN` / `DUMP` handling.
bool get isOverflowBaselineCaptureEnabled {
  final override = debugOverflowBaselineCapture;
  if (override != null) return override;

  const defines = [
    String.fromEnvironment('OVERFLOW_BASELINE'),
    String.fromEnvironment('overflow_baseline'),
  ];
  for (final d in defines) {
    if (_isTruthy(d)) return true;
  }
  final env = Platform.environment;
  return _isTruthy(env['OVERFLOW_BASELINE']) ||
      _isTruthy(env['overflow_baseline']);
}

bool _isTruthy(String? value) => value == '1' || value == 'true';

/// One measured coordinate: which sweep took the measurement, and where.
///
/// [sweep] is `<baseline>.<group>`, where `<baseline>` selects the committed file
/// (`card`, `popup`, `forced_form`, `chrome`) and `<group>` names the shape inside
/// it. Both halves are part of the ratchet: a port that renames either one reads
/// as every cell of that group disappearing and every cell of a new group
/// appearing, which is the correct verdict — nobody can then claim the two runs
/// were compared.
///
/// [axes] is the coordinate, in reading order. Insertion order is preserved into
/// the cell id, so `card|width|tab|locale` stays the sweep's own reading order
/// rather than becoming alphabetical. It is no longer the allowlist's grammar —
/// #1341 re-keyed that on `file:line` — but the dataset's coordinate is still a
/// coordinate, and this is the order a person reads it in.
class OverflowCell {
  const OverflowCell(this.sweep, this.axes);

  final String sweep;
  final Map<String, Object?> axes;
}

/// The dataset's join key: `sweep|axis=value|axis=value…`.
///
/// Values are stringified through [Object.toString], so a double axis records the
/// width it was pumped at (`191.4`) and reads the same as the test name a human
/// would look for.
String overflowBaselineCellId(OverflowCell cell) {
  if (cell.sweep.isEmpty) {
    throw ArgumentError.value(cell.sweep, 'sweep',
        'a baseline record must name the sweep it came from');
  }
  if (cell.axes.isEmpty) {
    throw ArgumentError.value(
        cell.axes,
        'axes',
        'a cell with no axes cannot be told apart from any other cell of '
            '"${cell.sweep}"');
  }
  final parts = [
    _sanitize(cell.sweep),
    for (final entry in cell.axes.entries)
      '${_sanitize(entry.key)}=${_sanitize('${entry.value}')}',
  ];
  return parts.join('|');
}

/// Keeps the row and field separators out of a value.
///
/// The dataset is one TSV row per incident and the cell id is pipe-delimited, so
/// a value carrying either would split one row into two — and a diff cannot tell
/// that apart from a coverage change. The chrome family already names its header
/// modes in prose, so this is not hypothetical.
String _sanitize(String value) => value.replaceAll(RegExp(r'[|\t\r\n]'), '_');

/// Builds the record for one measured cell.
///
/// Emitted as JSON rather than as the final TSV row because one cell can hold
/// several incidents and the extractor is what flattens, sorts and formats them —
/// keeping the sweeps' side of the contract to "name the coordinate, hand over
/// what you measured".
///
/// Every incident is recorded, including sub-tolerance ones: dropping them would
/// mean a port that loosened the filter looked identical to one that fixed a
/// layout. Each carries its own verdict against [kOverflowTolerancePx] instead —
/// evaluated here, where the shared constant is in scope, so the extractor never
/// has to restate the number (#1270 shared it for exactly that reason).
///
/// [threw] says the pump did not reach the end. Without it the dataset has a hole
/// in exactly the place it claims to have none: a cell whose tree failed to build
/// collects no incidents, so it would render as `clean` and read as "measured, and
/// it fits" — the not-measured-versus-measured-clean confusion, one level in from
/// the missing row AC 5 is usually about. Required rather than defaulted, because
/// an emitter that forgets to pass it must not be able to mean "it was fine".
///
/// #1351 **removed** a `runDirectory` parameter here rather than leaving it
/// unused. It existed only to feed the golden framework's parser; the incident
/// now normalises its own path at collection time, and the testability purpose
/// the parameter served has moved to [OverflowIncident.parse]'s own
/// `runDirectory`. An ignored parameter would have been worse than the signature
/// change: it still reads as "this is what the recorded paths are relative to",
/// and nothing — not `flutter analyze`, not a test — would notice that it had
/// stopped being true. The only callers were [emitOverflowBaselineRecord] and
/// this file's own test.
String overflowBaselineRecordLine(
  OverflowCell cell,
  List<OverflowIncident> incidents, {
  required bool threw,
}) {
  return jsonEncode({
    'cell': overflowBaselineCellId(cell),
    'threw': threw,
    'incidents': [
      for (final incident in incidents)
        {
          // `toString()` rather than a rounded value: infinity is
          // [OverflowIncident.unparseablePixels], which exists so a message
          // shape Flutter changed fails loudly instead of reading as clean, and
          // rounding it here would hide exactly that.
          'px': incident.pixels.toString(),
          'side': incident.side,
          'significant': incident.pixels > kOverflowTolerancePx,
          // The source columns, read off the incident. Until #1351 this line was
          // `...parseOverflowSource(incident.fullLog, runDirectory: …)` — the
          // third call site into the golden framework's parser, and the only
          // reason this file imported it. #1338 had already given the incident
          // the same three fields, so the location is now resolved once, at
          // collection time, by the parser the whole gate family shares.
          //
          // **`line` is emitted unquoted — a JSON number, not a string.**
          // `parseOverflowSource` returned `Map<String, String>` and serialized
          // `"line":"120"`; [OverflowIncident.line] is an `int`, so this
          // serializes `"line":120`. Stated here so the first future overflow
          // record does not read as corruption.
          //
          // The committed TSVs cannot move over it, for two independent reasons.
          // The extractor renders every column through `'$value'`
          // (`test_scripts/overflow_baseline.dart:_field`), so `120` and `"120"`
          // both reach the `site` column as `120` — the type is invisible past
          // the JSON. And all 4,032 rows across the five frozen baselines are
          // `clean` with `-` in every incident column, so no committed row
          // exercises these keys at all.
          //
          // [file] and [line] go in together or not at all, following
          // [OverflowIncident.site]: the extractor builds `site` from the bare
          // path when `line` is absent, and a path with no line is a key that
          // joins to nothing while reading as resolved.
          if (incident.widget != null) 'widget': incident.widget,
          if (incident.site != null) ...{
            'file': incident.file,
            'line': incident.line,
          },
        },
    ],
  });
}

/// Prints the record for [cell] when capture is on, and nothing otherwise.
///
/// A null [cell] is silence by design. Not every pump through
/// `runWithOverflowCollection` is a sweep coordinate — the popup file uses the
/// probe to open a dialog and measure its height, the report generator re-pumps a
/// recommended geometry — and an unlabelled row could not be diffed against
/// anything.
void emitOverflowBaselineRecord(
  OverflowCell? cell,
  List<OverflowIncident> incidents, {
  required bool threw,
}) {
  if (cell == null || !isOverflowBaselineCaptureEnabled) return;
  final line = overflowBaselineRecordLine(cell, incidents, threw: threw);
  // ignore: avoid_print
  print('$kOverflowBaselineMarker $line');
}
