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
    }) {
      return FirmwareImageUIModel(
        instance: 1,
        instancePath: 'Device.DeviceInfo.FirmwareImage.1',
        name: 'Bank 1',
        version: version,
        status: isActive ? 'Active' : 'Valid',
        available: available,
        isBootTarget: isActive,
      );
    }

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

      test('returns 60 when update available', () {
        final context = HealthEvaluationContext(
          firmware: FirmwareBanksData(
            banks: [
              createBank(version: '1.0.0', isActive: true, available: true),
              createBank(version: '1.1.0', isActive: false, available: true),
            ],
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 60);
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

      test('returns Update Available when update exists', () {
        final context = HealthEvaluationContext(
          firmware: FirmwareBanksData(
            banks: [
              createBank(version: '1.0.0', isActive: true, available: true),
              createBank(version: '1.1.0', isActive: false, available: true),
            ],
          ),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'Update Available');
        expect(summary.items.any((i) => i.label == 'Available'), true);
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
