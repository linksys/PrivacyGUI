import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/dimensions/internet_dimension.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/health_dimension.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';

void main() {
  group('InternetHealthDimension', () {
    late InternetHealthDimension dimension;

    setUp(() {
      dimension = InternetHealthDimension();
    });

    group('evaluate', () {
      test('returns 100 when wan data is null (assume healthy)', () {
        const context = HealthEvaluationContext();

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 100 when WAN is up', () {
        final context = HealthEvaluationContext(
          wan: WanData(
            model: const WanStatusUIModel(
              isUp: true,
              ipAddress: '192.168.1.100',
              subnetMask: '255.255.255.0',
              addressingType: 'DHCP',
              mtu: 1500,
              gateway: '192.168.1.1',
            ),
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 0 when WAN is down', () {
        final context = HealthEvaluationContext(
          wan: WanData(
            model: const WanStatusUIModel(
              isUp: false,
              ipAddress: '',
              subnetMask: '',
              addressingType: '',
              mtu: 0,
            ),
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 0);
      });
    });

    group('getSummary', () {
      test('returns loading state when wan data is null', () {
        const context = HealthEvaluationContext();

        final summary = dimension.getSummary(context);

        expect(summary.status, 'Loading...');
        expect(summary.hint, 'Tap for actions');
      });

      test('returns Connected status when WAN is up', () {
        final context = HealthEvaluationContext(
          wan: WanData(
            model: const WanStatusUIModel(
              isUp: true,
              ipAddress: '192.168.1.100',
              subnetMask: '255.255.255.0',
              addressingType: 'DHCP',
              mtu: 1500,
              gateway: '192.168.1.1',
            ),
          ),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'Connected');
        expect(summary.items.any((i) => i.label == 'IP'), true);
        expect(summary.items.firstWhere((i) => i.label == 'IP').value,
            '192.168.1.100');
      });

      test('returns Disconnected status when WAN is down', () {
        final context = HealthEvaluationContext(
          wan: WanData(
            model: const WanStatusUIModel(
              isUp: false,
              ipAddress: '',
              subnetMask: '',
              addressingType: '',
              mtu: 0,
            ),
          ),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'Disconnected');
      });
    });

    group('watchedDomains', () {
      test('watches wanStatus domain', () {
        expect(
            dimension.watchedDomains, contains(InvalidationDomain.wanStatus));
      });
    });

    group('getActions', () {
      testWidgets('returns diagnose and settings actions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SizedBox(),
          ),
        );
        final context = tester.element(find.byType(SizedBox));

        final actions = dimension.getActions(context);

        expect(actions.length, 2);
        expect(actions.any((a) => a.id == 'diagnose_internet'), true);
        expect(actions.any((a) => a.id == 'internet_settings'), true);
      });
    });
  });
}
