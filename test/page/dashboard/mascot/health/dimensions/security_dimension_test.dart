import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/dimensions/security_dimension.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/health_dimension.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';

void main() {
  group('SecurityHealthDimension', () {
    late SecurityHealthDimension dimension;

    setUp(() {
      dimension = SecurityHealthDimension();
    });

    FirewallData createFirewallData({
      bool ipv4 = true,
      bool ipv6 = true,
      bool dmzEnabled = false,
    }) {
      return FirewallData(
        firewallModel: FirewallUIModel(
          isIPv4FirewallEnabled: ipv4,
          isIPv6FirewallEnabled: ipv6,
        ),
        ruleContext: FirewallRuleContext.empty,
        ruleSummaries: const [],
        dmzModel: DmzUIModel(
          isEnabled: dmzEnabled,
          destIp: '',
          sourceType: DmzSourceType.any,
          sourcePrefix: '',
        ),
        dmzSummaries: const [],
      );
    }

    group('evaluate', () {
      test('returns 100 when firewall data is null', () {
        const context = HealthEvaluationContext();

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 100 when both firewalls on and DMZ off', () {
        final context = HealthEvaluationContext(
          firewall:
              createFirewallData(ipv4: true, ipv6: true, dmzEnabled: false),
        );

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 80 when IPv4 only and DMZ off', () {
        final context = HealthEvaluationContext(
          firewall:
              createFirewallData(ipv4: true, ipv6: false, dmzEnabled: false),
        );

        final score = dimension.evaluate(context);

        expect(score, 80);
      });

      test('returns 50 when firewall on but DMZ enabled', () {
        final context = HealthEvaluationContext(
          firewall:
              createFirewallData(ipv4: true, ipv6: true, dmzEnabled: true),
        );

        final score = dimension.evaluate(context);

        expect(score, 50);
      });

      test('returns 30 when IPv4 firewall off', () {
        final context = HealthEvaluationContext(
          firewall:
              createFirewallData(ipv4: false, ipv6: true, dmzEnabled: false),
        );

        final score = dimension.evaluate(context);

        expect(score, 30);
      });
    });

    group('getSummary', () {
      test('returns Protected when fully secured', () {
        final context = HealthEvaluationContext(
          firewall:
              createFirewallData(ipv4: true, ipv6: true, dmzEnabled: false),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'Protected');
      });

      test('returns At Risk when firewall off', () {
        final context = HealthEvaluationContext(
          firewall: createFirewallData(ipv4: false),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'At Risk');
      });

      test('returns DMZ Active when DMZ enabled', () {
        final context = HealthEvaluationContext(
          firewall: createFirewallData(ipv4: true, dmzEnabled: true),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'DMZ Active');
      });
    });

    group('watchedDomains', () {
      test('watches firewall and DMZ domains', () {
        expect(dimension.watchedDomains,
            contains(InvalidationDomain.firewallRules));
        expect(dimension.watchedDomains, contains(InvalidationDomain.dmz));
      });
    });

    group('getActions', () {
      testWidgets('returns firewall and DMZ actions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SizedBox(),
          ),
        );
        final context = tester.element(find.byType(SizedBox));

        final actions = dimension.getActions(context);

        expect(actions.any((a) => a.id == 'firewall_settings'), true);
        expect(actions.any((a) => a.id == 'dmz_settings'), true);
      });
    });
  });
}
