import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/usp_formatters.dart';
import 'package:privacy_gui/page/firmware_update/localizations/firmware_failure_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_failure.dart';

/// The defect these tests exist for, stated once: the failure card used to render
/// `FirmwareUpdateState.errorMessage`, a `String` the notifier assembled from
/// hard-coded English at thirteen call sites — so **twenty-five of twenty-six
/// locales read English**, two of them English wrapped around a bare `fwup_state`
/// digit.
///
/// So there are two kinds of test below and they fail for different reasons.
/// `reason → key` pins the mapping the way
/// `test/components/localizations/service_error_localizations_test.dart` does —
/// against `loc(ctx).xxx`, never a literal, so copy edits stay green and a swapped
/// arm goes red. `every locale` is the one that would have caught the original
/// defect: it walks all 26 locales and requires each to differ from `en`. A key
/// added to `app_en.arb` and forgotten in the other twenty-five still compiles,
/// still renders, and still reads English — nothing but this sweep notices.
void main() {
  /// Pumps a localized tree at [locale] and hands back its `BuildContext`.
  Future<BuildContext> pumpContext(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    late BuildContext captured;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Builder(builder: (c) {
        captured = c;
        return const SizedBox();
      }),
    ));
    return captured;
  }

  /// One failure per reason, and the reason the map is keyed by the enum rather
  /// than being a plain list: the first test asserts its keys **are**
  /// `FirmwareFailureReason.values`, so a fourteenth reason arrives as a red test
  /// here instead of as an untested arm.
  final samples = <FirmwareFailureReason, FirmwareFailure>{
    FirmwareFailureReason.serviceError:
        const FirmwareFailure.serviceError(NetworkError()),
    FirmwareFailureReason.fileEmpty: const FirmwareFailure.fileEmpty(),
    FirmwareFailureReason.fileTooSmall:
        const FirmwareFailure.fileTooSmall(sizeBytes: 4096),
    FirmwareFailureReason.fileTooLarge:
        const FirmwareFailure.fileTooLarge(sizeBytes: 300 * 1024 * 1024),
    FirmwareFailureReason.fileTypeUnsupported:
        const FirmwareFailure.fileTypeUnsupported(),
    FirmwareFailureReason.noImageSelected:
        const FirmwareFailure.noImageSelected(),
    FirmwareFailureReason.routerReportedFailure:
        const FirmwareFailure.routerReportedFailure(fwupState: '5'),
    FirmwareFailureReason.progressStalled:
        const FirmwareFailure.progressStalled(fwupState: '3'),
    FirmwareFailureReason.progressStalledNoReading:
        const FirmwareFailure.progressStalledNoReading(),
    FirmwareFailureReason.banksUnreadableAfterReboot:
        const FirmwareFailure.banksUnreadableAfterReboot(),
    FirmwareFailureReason.multipleActiveBanks:
        const FirmwareFailure.multipleActiveBanks(count: 2),
    FirmwareFailureReason.expectedBankMissing:
        const FirmwareFailure.expectedBankMissing(instance: 2),
    FirmwareFailureReason.bootedOldImage:
        const FirmwareFailure.bootedOldImage(instance: 2, status: 'Standby'),
  };

  group('localizeFirmwareFailure — reason → key', () {
    test('every reason has a sample', () {
      expect(samples.keys.toSet(), FirmwareFailureReason.values.toSet(),
          reason: 'a new reason needs a sample here or it goes untested');
    });

    testWidgets('each reason maps to its own l10n string', (tester) async {
      final ctx = await pumpContext(tester);
      final l = loc(ctx);

      final expected = <FirmwareFailureReason, String>{
        // Delegated, not duplicated — `localizeServiceError` stays the only
        // place a ServiceError becomes a string.
        FirmwareFailureReason.serviceError:
            localizeServiceError(ctx, const NetworkError()),
        FirmwareFailureReason.fileEmpty: l.firmwareFileEmpty,
        FirmwareFailureReason.fileTooSmall:
            l.firmwareFileTooSmall(UspFormatters.formatBytes(4096)),
        FirmwareFailureReason.fileTooLarge: l
            .firmwareFileTooLarge(UspFormatters.formatBytes(300 * 1024 * 1024)),
        FirmwareFailureReason.fileTypeUnsupported:
            l.firmwareFileTypeUnsupported,
        // Reuses the picker's own empty-state sentence rather than adding a
        // twelfth key: "no image selected" is the same fact in both places, and
        // that sentence already names the two extensions that work.
        FirmwareFailureReason.noImageSelected: l.noFirmwareImageSelected,
        FirmwareFailureReason.routerReportedFailure:
            l.firmwareRouterReportedFailure('5'),
        FirmwareFailureReason.progressStalled: l.firmwareProgressStalled('3'),
        // The stall with nothing to name. A second key rather than a sentinel in
        // the placeholder above: the first version passed the literal `unread`,
        // which is an English word inside twenty-five translated sentences.
        FirmwareFailureReason.progressStalledNoReading:
            l.firmwareProgressStalledNoReading,
        FirmwareFailureReason.banksUnreadableAfterReboot:
            l.firmwareBanksUnreadableAfterReboot,
        FirmwareFailureReason.multipleActiveBanks:
            l.firmwareMultipleActiveBanks('2'),
        FirmwareFailureReason.expectedBankMissing:
            l.firmwareExpectedBankMissing('2'),
        FirmwareFailureReason.bootedOldImage:
            l.firmwareBootedOldImage('2', 'Standby'),
      };

      for (final reason in FirmwareFailureReason.values) {
        expect(localizeFirmwareFailure(ctx, samples[reason]!), expected[reason],
            reason: '$reason should map to its own key');
      }
    });

    testWidgets('no two reasons share a sentence', (tester) async {
      final ctx = await pumpContext(tester);
      final rendered = {
        for (final entry in samples.entries)
          entry.key: localizeFirmwareFailure(ctx, entry.value)
      };
      expect(rendered.values.toSet(), hasLength(rendered.length),
          reason: 'two reasons rendering identically means one of them is '
              'wearing the other one\'s copy: $rendered');
    });

    testWidgets('the raw fwup_state reaches the sentence', (tester) async {
      final ctx = await pumpContext(tester);
      // The digit is the whole diagnostic a support call has to work from, and
      // it is the one part of these two sentences that must NOT be translated.
      expect(
          localizeFirmwareFailure(
              ctx, const FirmwareFailure.routerReportedFailure(fwupState: '5')),
          contains('5'));
      expect(
          localizeFirmwareFailure(
              ctx, const FirmwareFailure.progressStalled(fwupState: '3')),
          contains('3'));
    });

    testWidgets('a stall with no reading names no reading', (tester) async {
      // The hole a placeholder leaves open. The first version of this reported a
      // reading-less stall as `progressStalled(fwupState: 'unread')`, which put an
      // English word inside twenty-five translated sentences — so the placeholder
      // that exists to keep `5` untranslated was also keeping a word untranslated.
      //
      // Asserted on the value rather than on the copy: a reason that carries no
      // token cannot leak one, whatever any locale's sentence says.
      const stalled = FirmwareFailure.progressStalledNoReading();
      expect(stalled.detail, isNull);
      expect(stalled.number, isNull);

      final ctx = await pumpContext(tester);
      expect(
        localizeFirmwareFailure(ctx, stalled),
        isNot(contains('fwup_state')),
        reason:
            'there was no state to report, so the sentence must not name one',
      );
    });

    testWidgets('sizes are formatted, not printed as raw bytes',
        (tester) async {
      final ctx = await pumpContext(tester);
      final tooLarge = localizeFirmwareFailure(ctx,
          const FirmwareFailure.fileTooLarge(sizeBytes: 300 * 1024 * 1024));
      expect(tooLarge, contains('300 MB'));
      expect(tooLarge, isNot(contains('314572800')),
          reason: 'nine digits is not a size a user can read');
    });

    testWidgets('a null failure falls back rather than rendering nothing',
        (tester) async {
      final ctx = await pumpContext(tester);
      expect(localizeFirmwareFailure(ctx, null), loc(ctx).unknownError);
    });
  });

  // ---------------------------------------------------------------------------
  // The sweep. This is the test that would have caught the original defect.
  // ---------------------------------------------------------------------------
  group('every locale gets its own sentence', () {
    testWidgets('all 26 locales render every reason non-empty', (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        final ctx = await pumpContext(tester, locale: locale);
        for (final entry in samples.entries) {
          final rendered = localizeFirmwareFailure(ctx, entry.value);
          expect(rendered.trim(), isNotEmpty,
              reason: '${entry.key} is blank in $locale');
        }
      }
    });

    testWidgets(
        'the 25 non-en locales differ from en for every firmware reason',
        (tester) async {
      // `serviceError` is excluded because its copy belongs to
      // `localizeServiceError`, which has its own ARB keys and its own tests —
      // asserting it here would test that file's translations, not this one's.
      final firmwareReasons = FirmwareFailureReason.values
          .where((r) => r != FirmwareFailureReason.serviceError);

      final ctxEn = await pumpContext(tester);
      final english = {
        for (final r in firmwareReasons)
          r: localizeFirmwareFailure(ctxEn, samples[r]!)
      };

      final untranslated = <String>[];
      for (final locale in AppLocalizations.supportedLocales) {
        if (locale.languageCode == 'en') continue;
        final ctx = await pumpContext(tester, locale: locale);
        for (final r in firmwareReasons) {
          if (localizeFirmwareFailure(ctx, samples[r]!) == english[r]) {
            untranslated.add('$locale/${r.name}');
          }
        }
      }

      expect(untranslated, isEmpty,
          reason: 'these render the English sentence — the exact defect this '
              'mapper replaced, and one an ARB key added to app_en.arb alone '
              'reproduces silently');
    });
  });
}
