// The source-scan half of REQ-C2 (#1552).
//
// The decision guarded: **the app never writes a schedule.** `FirmwareAutoUpdate`
// exposes `fwup_periodic_check` and `update_firmware_now` alongside the flag the
// toggle owns, and both are one named argument away from any call site. Scheduling
// was decided against because the data plane can only promise "at the next cron
// tick" — nothing in this stack can name the time a UI would be committing to — and
// `update_firmware_now` is a second flash entry point that would bypass the OTA
// page's confirmation.
//
// Why a source scan and not a service test: the service test pins what
// `setAutoUpdatePolicy` sends today by capturing the params map, which is the
// stronger assertion — for that one method. This file covers the method that has
// not been written yet. A second caller passing `fwupPeriodicCheck: '1'` from
// somewhere else in `lib/` leaves every existing test green, and the argument is
// optional, so nothing fails to compile either.
//
// Comment lines are stripped before scanning, deliberately. The service's own doc
// comment *names* both parameters to explain why they are unread, and that
// paragraph is the reason a future reader does not add them back — exempting the
// whole file to accommodate it would have blinded the scan to the one file most
// likely to grow the call.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The two writes this app does not make, by their generated Dart names.
///
/// Spelled as named arguments (`name:`) rather than bare identifiers, because bare
/// `updateFirmwareNow` would also match a plausible *local* verb — a method that
/// starts the OTA flow is a reasonable thing to call that — and a guard that fires
/// on an unrelated method name is a guard people delete.
const _forbiddenArguments = <String, String>{
  'fwupPeriodicCheck:':
      'writes a check schedule. The router can only promise "next cron tick", so '
          'no UI may name a time (REQ-C2).',
  'updateFirmwareNow:':
      'starts a flash outside the OTA page, skipping the confirmation that page '
          'exists to ask for.',
};

void main() {
  /// Everything in `lib/` except codegen, which necessarily declares both.
  List<File> appDartFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.startsWith('lib/generated/'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  /// [source] with `//` and `///` lines removed.
  ///
  /// Line comments only. A named argument buried in a `/* */` block would slip
  /// through, and that is an acceptable hole: this repo has no block comments in
  /// `lib/`, and a scanner that tried to parse them would be a Dart parser.
  String withoutLineComments(String source) => source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  group('the app writes no firmware schedule', () {
    test('no file in lib/ passes a scheduling argument', () {
      final offenders = <String>[];
      for (final file in appDartFiles()) {
        final code = withoutLineComments(file.readAsStringSync());
        for (final argument in _forbiddenArguments.keys) {
          if (code.contains(argument)) {
            offenders.add('${file.path}: $argument '
                '${_forbiddenArguments[argument]}');
          }
        }
      }

      expect(offenders, isEmpty,
          reason:
              'Pass only `autoupdateFlags` to `FirmwareAutoUpdate.update()`. '
              'If a schedule is genuinely wanted, it is a product decision that '
              'reopens #1552 — not an extra argument.\n'
              '${offenders.join('\n')}');
    });

    test('the scan still has something to look for', () {
      // Without this, a codegen rename turns the test above into an assertion
      // that two strings nobody uses are absent — green forever, and green for
      // the wrong reason. `usp-codegen` regenerates from YAML, so the names are
      // not ours to keep stable.
      final generated =
          File('lib/generated/firmware_auto_update.g.dart').readAsStringSync();
      for (final argument in _forbiddenArguments.keys) {
        expect(generated.contains(argument), isTrue,
            reason:
                'FirmwareAutoUpdate no longer spells "$argument". Re-derive '
                'the name from firmware_auto_update.g.dart — the decision has '
                'not changed, only its spelling.');
      }
    });

    test('the policy write is the only write the service makes', () {
      // The positive half, at the one call site that exists. Deliberately a
      // substring rather than a parse: `usp_firmware_update_service_test.dart`
      // already captures the exact params map the router receives, so what is
      // worth pinning in source is which argument is *spelled* there.
      final service = File(
        'lib/page/firmware_update/services/usp_firmware_update_service.dart',
      );
      expect(service.existsSync(), isTrue,
          reason: 'the service moved; re-point this scan at its new home');
      expect(withoutLineComments(service.readAsStringSync()),
          contains('autoupdateFlags: policy.rawValue'),
          reason:
              'the auto-update write must send the policy and nothing else');
    });
  });
}
