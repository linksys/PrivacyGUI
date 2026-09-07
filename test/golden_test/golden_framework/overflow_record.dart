import 'package:flutter/foundation.dart';

import '../../layout_gate/incident.dart';

/// Builds the JSON record the golden runner writes for one overflow error, so
/// the golden reports can say where and by how much a layout overflowed instead
/// of only that it did (#1197).
///
/// **This file no longer parses anything.** Until #1339 it was
/// `overflow_diagnostics.dart`, a second reader of Flutter's overflow message
/// with its own `RegExp`s beside `test/layout_gate/incident.dart`'s — the same
/// error string read two ways, so the gate could report a site the golden report
/// spelled differently, and an SDK message change broke one of them silently.
/// What is left here is the shape of the record: which keys, in which order,
/// with which fields omitted. The reading is [OverflowIncident.parse]'s.
///
/// Both the error message and the diagnostics dump are Flutter implementation
/// details, not API contracts. Every extraction stays individually
/// failure-tolerant — an unmatched pattern yields absent fields rather than an
/// exception, because a diagnostic path must never turn a passing golden run
/// into a failure. `overflow_record_test.dart` pins this file's contract and
/// `test/util/overflow_probe_test.dart` pins the parser's, so an SDK upgrade that
/// changes the formats now fails in one place instead of two.

/// Builds the full record written for one overflow error.
///
/// [runDirectory] is the directory the test process runs in, which is the app
/// root: `golden_runner` reads and writes `goldens/...` through relative paths.
///
/// `message` is kept verbatim so nothing that reads it today breaks and so
/// multi-side overflows keep their full text. `log` carries the whole
/// diagnostics dump — the constraints, the flex configuration and the creator
/// chain, none of which the one-line message conveys. It is the only lead on an
/// overflow whose location did not resolve, so it is recorded unconditionally
/// (#1197).
///
/// The extractions stay independent: an unreadable pixel count still yields a
/// usable location, and an unresolvable location still yields a usable
/// measurement.
///
/// ## Key order is part of the contract
///
/// `golden, message, pixels, side, log, widget, file, line` — the order the
/// pre-#1339 implementation produced, preserved because `overflow_warnings.json`
/// is written by `jsonEncode` over this map and is diffed between runs. Changing
/// the order would rewrite every byte of a file whose *content* did not change,
/// and the swap was verified against a stored real report
/// (`test/fixtures/golden_overflow_warnings.json`) precisely so that a diff means
/// something.
Map<String, String> buildOverflowRecord({
  required String goldenName,
  required FlutterErrorDetails details,
  required String runDirectory,
}) {
  final message = details.exceptionAsString();
  final record = <String, String>{'golden': goldenName, 'message': message};

  // toDiagnosticsNode() runs the inspector transformer that resolves the
  // creating widget's source location. Guard it: this runs inside an error
  // handler, and a throw here would surface as a test failure. Parsed below
  // either way — the message alone still carries the measurement.
  String? dump;
  try {
    dump = details.toDiagnosticsNode().toStringDeep();
  } catch (_) {
    // No location and no `log`; the measurement below still stands.
  }

  final incident = OverflowIncident.parse(
    message,
    fullLog: dump ?? '',
    runDirectory: runDirectory,
  );

  // The advisory opt-out, and the one place it is taken. The shared parser's
  // default for a message it cannot read is deliberately loud: `pixels` comes
  // back as [OverflowIncident.unparseablePixels] — infinity — which survives
  // every tolerance and fails the gate rather than reading clean (see that
  // field's doc). This report judges nothing, so the same input must produce an
  // *absent* amount here, as it did before #1339: a `"pixels": "Infinity"` in
  // the JSON would render as `Infinitypx` on a badge and sort to the top of
  // every report.
  //
  // Opting out is spelled as a null check on [OverflowIncident.pixelsText]
  // rather than as a tolerance or a sentinel comparison, so a future gate-side
  // caller cannot inherit this leniency by omission — it has to write the same
  // three lines and own them.
  final amount = incident.pixelsText;
  if (amount != null) {
    record['pixels'] = amount;
    record['side'] = incident.side;
  }

  if (dump != null) {
    record['log'] = stripOverflowObjectIds(
      normalizeOverflowDumpPaths(dump, runDirectory: runDirectory),
    );

    final widget = incident.widget;
    final file = incident.file;
    final line = incident.line;
    // All three or none: the parser resolves them from one match, and a `file`
    // without a `line` is not half a location — the reports key on both.
    if (widget != null && file != null && line != null) {
      record['widget'] = widget;
      record['file'] = file;
      record['line'] = '$line';
    }
  }

  return record;
}
