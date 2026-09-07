/// The composed scene for `usp_system_log_view` — the layout gate's, and the only
/// one this page has.
///
/// **Written for #1380 (wave 4), not moved.** Every other page this wave brought into
/// the gate already had a golden fixture, and the rule there was to *move* it so one
/// file feeds both suites (`dmz_scene_data.dart` records why: the gate may not import
/// from `test/golden_test/`, #1361). This page has no golden test, so there was
/// nothing to move.
///
/// What it is deliberately **not** is a promotion of the two `LogFileUIModel` locals
/// in `test/page/system_log/providers/usp_system_log_notifier_test.dart`. Those look
/// shareable and are not: that suite reads its own values back
/// (`valueOrNull![0].name` is asserted to be `'syslog'`, `hasLength(2)`), so they are
/// arrange-locals for behaviour assertions rather than a composed state. Sharing them
/// would mean a later widening of this scene — a longer file name to press a row
/// harder — silently breaks a notifier test that has nothing to do with layout. The
/// values below overlap with that suite's because both describe the same router, not
/// because either file reads the other.
library;

import 'package:privacy_gui/page/system_log/models/log_file_ui_model.dart';

/// The two vendor log files every `page.system_log` cell is measured against.
///
/// Two rows rather than one, because between them they render **all four** of the
/// states the card's second `Row` can be in, and that row is the page's only tight
/// one — `Max Size: …` then the badge then a `Spacer` then the export button, none of
/// them flexible:
///
/// - `persistent: true` renders the `Persistent` badge, `false` renders `Volatile`.
///   `Persistent` is the wider of the two, so the first row is the worst case and the
///   second proves the narrow one is not accidentally wider.
/// - `maximumSize: 524288` renders `512 KB` through `UspFormatters.formatBytes`;
///   `maximumSize: 0` renders the model's `'Unknown'` fallback, which is the longer
///   string of the two. So neither row is the worst case on both counts, and the
///   sweep sees the longer size beside the shorter badge and vice versa.
///
/// Note for whoever reads a failure here: `Max Size: `, `Persistent` and `Volatile`
/// are hard-coded English in `usp_system_log_view.dart` and do not vary across the 26
/// locales. `loc(context).export` on the button does. So a locale-specific failure on
/// this page is a failure about the export label's width, and the rest of the row is
/// the same in every cell.
const _gateLogFiles = [
  LogFileUIModel(
    instancePath: 'Device.DeviceInfo.VendorLogFile.1.',
    name: 'syslog',
    maximumSize: 524288,
    persistent: true,
  ),
  LogFileUIModel(
    instancePath: 'Device.DeviceInfo.VendorLogFile.2.',
    name: 'kernel',
    maximumSize: 0,
    persistent: false,
  ),
];

/// The router shape `page.system_log` sweeps: two log files, so the card path renders.
///
/// The empty list is the page's other content state — an icon over one line of prose,
/// inside a `Center`, with no `Row` in it at all — and it is not swept because there is
/// nothing there that can overflow horizontally. `kSystemLogPageCase` requires
/// `AppCard` partly to pin that this scene did not quietly become that one.
const gateSystemLogState = _gateLogFiles;
