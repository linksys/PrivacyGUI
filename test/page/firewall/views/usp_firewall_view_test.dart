import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/setting_blocks.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/usp_firewall_notifier.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';
import 'package:privacy_gui/page/firewall/views/usp_firewall_view.dart';
import 'package:privacy_gui/route/constants.dart';
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
      // A stand-in for the child page, so the IPv6 link has somewhere to go.
      childRoutes: [
        GoRoute(
          path: 'ipv6-port-service',
          name: RouteNamed.uspIpv6PortService,
          builder: (_, __) => const Scaffold(body: Text(_ipv6Stub)),
        ),
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

  // #1433: the IPv6 Port Service link asks first when a switch is unsaved.
  group('UspFirewallView - opening IPv6 Port Service with unsaved changes', () {
    Finder ipv6Link() => find.byWidgetPredicate((w) =>
        w is NavLinkBlock && w.identifier == 'firewall-ipv6-port-service');

    Finder promptButton(String identifier) => find
        .byWidgetPredicate((w) => w is AppButton && w.identifier == identifier);

    Future<void> changeASwitch(WidgetTester tester) async {
      await pumpFirewall(
        tester,
        FirewallTestData.createFirewallData(
          ruleContext: FirewallTestData.createNamedRuleContext(),
        ),
      );
      await tester.tap(switchIn('firewall-filter-nat-redirection'));
      await settle(tester);
    }

    Future<void> tapIpv6Link(WidgetTester tester) async {
      await tester.ensureVisible(ipv6Link());
      await tester.tap(ipv6Link());
      await settle(tester);
    }

    bool firewallIsDirty(WidgetTester tester) => ProviderScope.containerOf(
            tester.element(find.byType(UspFirewallView, skipOffstage: false)))
        .read(uspFirewallProvider)
        .isDirty;

    testWidgets('asks before opening, and opens nothing yet', (tester) async {
      await changeASwitch(tester);

      await tapIpv6Link(tester);

      expect(find.text(_unsavedTitle), findsOneWidget);
      expect(find.text(_ipv6Stub), findsNothing);
    });

    testWidgets('Save saves the switch, then opens IPv6 Port Service',
        (tester) async {
      await changeASwitch(tester);
      await tapIpv6Link(tester);

      await tester.tap(promptButton('unsaved-open-save'));
      await settle(tester);

      final pending = verify(() => svc.save(
            original: any(named: 'original'),
            pending: captureAny(named: 'pending'),
            context: any(named: 'context'),
          )).captured.single as FirewallUIModel;
      expect(pending.blockNATRedirection, isTrue);
      expect(find.text(_ipv6Stub), findsOneWidget);
      expect(firewallIsDirty(tester), isFalse);
    });

    testWidgets('a failed save keeps the user on Firewall with the change',
        (tester) async {
      // Fails after a delay, as a router answer does. A synchronous throw
      // completes the task before `doSomethingWithSpinner` listens to it, which
      // the test zone reports as an unhandled error although `_onSave` still
      // catches it: a property of that helper, not of this flow.
      when(() => svc.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
            context: any(named: 'context'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        throw const UnexpectedError(detail: 'refused');
      });
      await changeASwitch(tester);
      await tapIpv6Link(tester);

      await tester.tap(promptButton('unsaved-open-save'));
      await settle(tester);

      expect(find.byType(SnackBar), findsOneWidget,
          reason:
              'the save error is shown, as the bottom bar\'s Save shows it');
      expect(find.text(_ipv6Stub), findsNothing);
      expect(find.byType(UspFirewallView), findsOneWidget);
      expect(firewallIsDirty(tester), isTrue);
    });

    testWidgets('Discard changes drops the switch and opens IPv6 Port Service',
        (tester) async {
      await changeASwitch(tester);
      await tapIpv6Link(tester);

      await tester.tap(promptButton('unsaved-open-discard'));
      await settle(tester);

      verifyNever(() => svc.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
            context: any(named: 'context'),
          ));
      expect(find.text(_ipv6Stub), findsOneWidget);
      expect(firewallIsDirty(tester), isFalse);
    });

    testWidgets('with nothing unsaved the link opens IPv6 Port Service',
        (tester) async {
      await pumpFirewall(
        tester,
        FirewallTestData.createFirewallData(
          ruleContext: FirewallTestData.createNamedRuleContext(),
        ),
      );

      await tapIpv6Link(tester);

      expect(find.text(_unsavedTitle), findsNothing);
      expect(find.text(_ipv6Stub), findsOneWidget);
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

const _ipv6Stub = 'IPv6 Port Service stub';

/// From `app_en.arb`.
const _unsavedTitle = 'You have unsaved changes on this page';

class _FixedFirewallData extends FirewallDataNotifier {
  _FixedFirewallData(this._data);

  final FirewallData _data;

  @override
  Future<FirewallData> build() async => _data;
}
