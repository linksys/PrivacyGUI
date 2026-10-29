import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/setting_blocks.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/usp_firewall_notifier.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';
import 'package:privacy_gui/page/firewall/views/usp_firewall_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/test_data/firewall_test_data.dart';
import '../../../util/app_test_fonts.dart';

class MockUspFirewallService extends Mock implements UspFirewallService {}

/// The Firewall page on the real notifier over a mocked service: the NAT
/// redirection switch FWDEV#204 brought back, and the page a router with no
/// named rule gets (#1611).
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  late MockUspFirewallService svc;

  setUpAll(() async {
    await loadAppFonts();
    registerFallbackValue(const FirewallUIModel());
    registerFallbackValue(FirewallRuleContext.empty);
  });

  setUp(() {
    svc = MockUspFirewallService();
    when(() => svc.save(
          original: any(named: 'original'),
          pending: any(named: 'pending'),
          context: any(named: 'context'),
        )).thenAnswer((_) async => 1);
  });

  Finder block(String identifier) => find
      .byWidgetPredicate((w) => w is SwitchBlock && w.identifier == identifier);

  Finder switchIn(String identifier) =>
      find.descendant(of: block(identifier), matching: find.byType(AppSwitch));

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpFirewall(WidgetTester tester, FirewallData data) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: const UspFirewallView(),
      locale: const Locale('en'),
      overrides: [
        uspFirewallProvider.overrideWith(UspFirewallNotifier.new),
        uspFirewallServiceProvider.overrideWithValue(svc),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        firewallDataProvider.overrideWith(() => _FixedFirewallData(data)),
      ],
    ));
    await settle(tester);
  }

  group('UspFirewallView - NAT redirection', () {
    testWidgets('sits between the multicast and IDENT filters', (tester) async {
      await pumpFirewall(
        tester,
        FirewallTestData.createFirewallData(
          ruleContext: FirewallTestData.createNamedRuleContext(),
        ),
      );

      final multicastY =
          tester.getTopLeft(block('firewall-filter-multicast')).dy;
      final natY =
          tester.getTopLeft(block('firewall-filter-nat-redirection')).dy;
      final identY = tester.getTopLeft(block('firewall-filter-ident')).dy;

      expect(find.text('Filter Internet NAT redirection'), findsOneWidget);
      expect(multicastY, lessThan(natY));
      expect(natY, lessThan(identY));
    });

    testWidgets('shows the value read from the router', (tester) async {
      await pumpFirewall(
        tester,
        FirewallTestData.createFirewallData(
          firewallModel: FirewallTestData.createFirewallUIModel(
            blockNATRedirection: true,
          ),
          ruleContext: FirewallTestData.createNamedRuleContext(),
        ),
      );

      expect(
        tester
            .widget<AppSwitch>(switchIn('firewall-filter-nat-redirection'))
            .value,
        isTrue,
      );
    });

    testWidgets('saving after a toggle sends it to the service',
        (tester) async {
      await pumpFirewall(
        tester,
        FirewallTestData.createFirewallData(
          ruleContext: FirewallTestData.createNamedRuleContext(),
        ),
      );

      await tester.tap(switchIn('firewall-filter-nat-redirection'));
      await settle(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await settle(tester);

      final pending = verify(() => svc.save(
            original: any(named: 'original'),
            pending: captureAny(named: 'pending'),
            context: any(named: 'context'),
          )).captured.single as FirewallUIModel;
      expect(pending.blockNATRedirection, isTrue);
    });
  });

  group('UspFirewallView - some named rules missing', () {
    testWidgets('a switch whose rule is absent cannot be changed',
        (tester) async {
      await pumpFirewall(
        tester,
        FirewallTestData.createFirewallData(
          ruleContext: FirewallTestData.createNamedRuleContext(
            without: const {'RULE_NAT_REDIRECTION'},
          ),
        ),
      );

      expect(
          tester
              .widget<AppSwitch>(switchIn('firewall-filter-nat-redirection'))
              .onChanged,
          isNull);
      expect(
          tester.widget<AppSwitch>(switchIn('firewall-filter-ident')).onChanged,
          isNotNull,
          reason: 'its rule is there');
    });
  });

  group('UspFirewallView - no named rule on the router', () {
    testWidgets('shows the load error instead of switches', (tester) async {
      await pumpFirewall(
        tester,
        FirewallTestData.createFirewallData(),
      );

      expect(find.byType(SwitchBlock), findsNothing);
      expect(find.text('Failed to load settings'), findsOneWidget);
    });
  });
}

class _FixedFirewallData extends FirewallDataNotifier {
  _FixedFirewallData(this._data);

  final FirewallData _data;

  @override
  Future<FirewallData> build() async => _data;
}
