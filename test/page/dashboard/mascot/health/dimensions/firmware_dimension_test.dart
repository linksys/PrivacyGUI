import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/dimensions/firmware_dimension.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/health_dimension.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';

void main() {
  group('FirmwareHealthDimension', () {
    late FirmwareHealthDimension dimension;

    setUp(() {
      dimension = FirmwareHealthDimension();
    });

    FirmwareImageUIModel createBank({
      required String version,
      required bool isActive,
      required bool available,
      int instance = 1,
      String? alias,
    }) {
      return FirmwareImageUIModel(
        instance: instance,
        instancePath: 'Device.DeviceInfo.FirmwareImage.$instance',
        alias: alias,
        name: 'Bank $instance',
        version: version,
        status: isActive ? 'Active' : 'Valid',
        available: available,
        isBootTarget: isActive,
      );
    }

    /// The measured shape of a router that is **already up to date**: the spare
    /// physical bank reports `Available=1` with an empty version, and the
    /// virtual ota row reports no update. Reading `availableBank` here is what
    /// pinned firmware health at 60 forever.
    FirmwareBanksData upToDateRouter() => FirmwareBanksData(banks: [
          createBank(
            version: '2.0.1.26091007',
            isActive: true,
            available: true,
            alias: 'fw1',
          ),
          createBank(
            version: '',
            isActive: false,
            available: true,
            instance: 2,
            alias: 'fw2',
          ),
          FirmwareImageUIModel(
            instance: 3,
            instancePath: 'Device.DeviceInfo.FirmwareImage.3',
            alias: 'ota',
            name: '',
            version: '',
            status: 'NoImage',
            available: false,
          ),
        ]);

    /// Same router, but the ota row now reports a newer version.
    FirmwareBanksData updateAvailableRouter() => FirmwareBanksData(banks: [
          createBank(
            version: '2.0.1.26091007',
            isActive: true,
            available: true,
            alias: 'fw1',
          ),
          createBank(
            version: '',
            isActive: false,
            available: true,
            instance: 2,
            alias: 'fw2',
          ),
          FirmwareImageUIModel(
            instance: 3,
            instancePath: 'Device.DeviceInfo.FirmwareImage.3',
            alias: 'ota',
            name: '',
            version: '2.0.1.26091009',
            status: 'Available',
            available: true,
          ),
        ]);

    group('evaluate', () {
      test('returns 100 when firmware data is null', () {
        const context = HealthEvaluationContext();

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 100 when no update available', () {
        final context = HealthEvaluationContext(
          firmware: FirmwareBanksData(
            banks: [
              createBank(version: '1.0.0', isActive: true, available: true),
            ],
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 100 on an up-to-date router with a spare bank', () {
        final context = HealthEvaluationContext(firmware: upToDateRouter());

        expect(dimension.evaluate(context), 100);
      });

      test('returns 60 when the ota row reports an update', () {
        final context =
            HealthEvaluationContext(firmware: updateAvailableRouter());

        expect(dimension.evaluate(context), 60);
      });

      test('returns 100 when there is no ota row at all', () {
        // OEM / rebadged builds never report one. That is "no update
        // information", not "update available".
        final context = HealthEvaluationContext(
          firmware: FirmwareBanksData(
            banks: [
              createBank(version: '1.0.0', isActive: true, available: true),
              createBank(
                version: '',
                isActive: false,
                available: true,
                instance: 2,
              ),
            ],
          ),
        );

        expect(dimension.evaluate(context), 100);
      });
    });

    group('getSummary', () {
      test('returns Up to Date when no update available', () {
        final context = HealthEvaluationContext(
          firmware: FirmwareBanksData(
            banks: [
              createBank(version: '1.0.0', isActive: true, available: true),
            ],
          ),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'Up to Date');
        expect(summary.items.any((i) => i.label == 'Current'), true);
      });

      test('up-to-date router: Up to Date, Current only, no Available row', () {
        final summary = dimension.getSummary(
          HealthEvaluationContext(firmware: upToDateRouter()),
        );

        expect(summary.status, 'Up to Date');
        expect(
          summary.items.singleWhere((i) => i.label == 'Current').value,
          '2.0.1.26091007',
        );
        expect(
          summary.items.any((i) => i.label == 'Available'),
          isFalse,
          reason: 'the spare bank is not an update — and its version is empty, '
              'so the row would have shown a blank value',
        );
      });

      test('update available: the Available row shows the ota version', () {
        final summary = dimension.getSummary(
          HealthEvaluationContext(firmware: updateAvailableRouter()),
        );

        expect(summary.status, 'Update Available');
        expect(
          summary.items.singleWhere((i) => i.label == 'Available').value,
          '2.0.1.26091009',
          reason: 'not the spare physical bank version',
        );
      });

      test('no ota row: Up to Date and no Available row', () {
        final summary = dimension.getSummary(
          HealthEvaluationContext(
            firmware: FirmwareBanksData(
              banks: [
                createBank(version: '1.0.0', isActive: true, available: true),
                createBank(
                  version: '',
                  isActive: false,
                  available: true,
                  instance: 2,
                ),
              ],
            ),
          ),
        );

        expect(summary.status, 'Up to Date');
        expect(summary.items.any((i) => i.label == 'Available'), isFalse);
      });
    });

    group('watchedDomains', () {
      test('has no SSE domains (polls only)', () {
        expect(dimension.watchedDomains, isEmpty);
      });
    });

    group('getActions', () {
      testWidgets('returns firmware update action', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SizedBox(),
          ),
        );
        final context = tester.element(find.byType(SizedBox));

        final actions = dimension.getActions(context);

        expect(actions.any((a) => a.id == 'firmware_update'), true);
      });
    });
  });
}
