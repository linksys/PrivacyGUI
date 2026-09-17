/// Constitution Article I §1.7 asks for this file, and round 2 of review noticed it
/// was missing while `firmware_auto_update_ui_model.dart` grew derived logic.
///
/// **It deliberately does not re-test the raw-string mapping.** Turning `"4"` into
/// `installing` or `"1"` into `serverUnreachable` belongs to `mapAutoUpdateStatus`, and
/// `usp_firmware_update_service_test.dart` covers every arm of it — duplicating that
/// here would give two places to update for one decision. What is tested below is what
/// the *model* decides once the mapping has run: the three predicates consumers gate
/// on, and the one copy method that is narrower than a `copyWith`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';

FirmwareAutoUpdateUIModel _model({
  FirmwareAutoUpdateStatus status = FirmwareAutoUpdateStatus.idle,
  String rawFlags = '2',
  FirmwareAutoUpdatePolicy policy = FirmwareAutoUpdatePolicy.autoInstall,
  FirmwareUpdateErrorCode errorCode = FirmwareUpdateErrorCode.unreported,
  bool? checkedAfterBoot,
}) =>
    FirmwareAutoUpdateUIModel(
      status: status,
      progress: 0,
      rawState: '0',
      policy: policy,
      rawFlags: rawFlags,
      errorCode: errorCode,
      checkedAfterBoot: checkedAfterBoot,
    );

void main() {
  group('isBusy — what blocks a second install', () {
    // The predicate the dashboard banner hides on and both install paths refuse on,
    // so its membership is a product decision rather than a convenience.
    test('covers exactly the three states the router is working in', () {
      for (final status in FirmwareAutoUpdateStatus.values) {
        expect(
          _model(status: status).isBusy,
          status == FirmwareAutoUpdateStatus.checking ||
              status == FirmwareAutoUpdateStatus.downloading ||
              status == FirmwareAutoUpdateStatus.installing,
          reason: '${status.name} classified wrongly',
        );
      }
    });

    test('rebooting is not busy, and unknown is not busy', () {
      // `rebooting` is out because the router has committed and stopped answering —
      // refusing a dispatch then would outlive the reboot it is guarding. `unknown` is
      // out because an unrecognised value is the weakest evidence of anything, and this
      // predicate *blocks* a user action.
      expect(
          _model(status: FirmwareAutoUpdateStatus.rebooting).isBusy, isFalse);
      expect(_model(status: FirmwareAutoUpdateStatus.unknown).isBusy, isFalse);
    });
  });

  group('checksForUpdates — read off the raw flags, not the enum', () {
    test('any positive value counts, including one this build cannot name', () {
      // REQ-C3 is a numeric comparison. A firmware that adds a `3` is a router that is
      // checking, and withholding a banner for an update it has already *found* would
      // hide real information behind a gap in this app's enum.
      expect(
          _model(rawFlags: '3', policy: FirmwareAutoUpdatePolicy.unknown)
              .checksForUpdates,
          isTrue);
      expect(_model(rawFlags: '1').checksForUpdates, isTrue);
      expect(_model(rawFlags: '2').checksForUpdates, isTrue);
    });

    test('zero and unreadable values do not', () {
      expect(_model(rawFlags: '0').checksForUpdates, isFalse);
      expect(_model(rawFlags: '').checksForUpdates, isFalse);
      expect(_model(rawFlags: 'yes').checksForUpdates, isFalse);
    });
  });

  group('withPolicy — narrower than a copyWith, on purpose', () {
    test('moves the policy and its raw flags together, and nothing else', () {
      final before = _model(
        status: FirmwareAutoUpdateStatus.installing,
        errorCode: FirmwareUpdateErrorCode.flash,
        checkedAfterBoot: true,
      );

      final after = before.withPolicy(FirmwareAutoUpdatePolicy.notifyOnly);

      expect(after.policy, FirmwareAutoUpdatePolicy.notifyOnly);
      // A confirmed write means the router now holds exactly this value.
      expect(after.rawFlags, FirmwareAutoUpdatePolicy.notifyOnly.rawValue);
      // Everything the *daemon* reports is untouched: a policy write is not an
      // observation of what the daemon is doing, and the diagnostics are its history.
      expect(after.status, before.status);
      expect(after.rawState, before.rawState);
      expect(after.errorCode, before.errorCode);
      expect(after.checkedAfterBoot, before.checkedAfterBoot);
    });
  });

  group('the two error-code predicates are not the same set', () {
    // They answer different questions, and conflating them is how an install-only
    // reason ended up rendering as a failed *check*.
    test(
        'isFailure is every named reason; couldBeACheck excludes the install ones',
        () {
      const installOnly = {
        FirmwareUpdateErrorCode.download,
        FirmwareUpdateErrorCode.flash,
        FirmwareUpdateErrorCode.signature,
      };
      for (final code in FirmwareUpdateErrorCode.values) {
        if (installOnly.contains(code)) {
          expect(code.isFailure, isTrue, reason: '${code.name} is a failure');
          expect(code.couldBeACheck, isFalse,
              reason:
                  '${code.name} happens after a check has already succeeded');
        } else if (code.isFailure) {
          expect(code.couldBeACheck, isTrue,
              reason: '${code.name} can come from a check');
        } else {
          expect(code.couldBeACheck, isFalse,
              reason: '${code.name} is the absence of a reason');
        }
      }
    });
  });

  group('checkedAfterBoot is a tri-state the model preserves', () {
    test('null is not false', () {
      // The distinction the nullable contract exists for: `false` is the router saying
      // it has not checked, null is the router not answering. Only the first may become
      // "not checked yet" on screen.
      expect(_model(checkedAfterBoot: null).checkedAfterBoot, isNull);
      expect(_model(checkedAfterBoot: false).checkedAfterBoot, isFalse);
      expect(_model(checkedAfterBoot: true).checkedAfterBoot, isTrue);
    });
  });

  group('equality', () {
    test('every diagnostics field takes part', () {
      // `props` comes from `namedProps` via `DiagnosticLoggable`, so a field left out
      // of that map is a field a `ref.watch` cannot see change.
      expect(_model(errorCode: FirmwareUpdateErrorCode.none),
          isNot(_model(errorCode: FirmwareUpdateErrorCode.flash)));
      expect(_model(checkedAfterBoot: true),
          isNot(_model(checkedAfterBoot: null)));
      expect(_model(), _model());
    });
  });
}
