// Apps & Gaming's page after a refused read (#1974).
//
// The page says the read failed, and offers no save until every tab is read:
// an edit on a tab that was not read could not be saved, so it would be
// dropped unseen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/views/apps_and_gaming_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/di.dart';
import '../../../../common/router_boundary.dart';
import '../../../../common/testable_router.dart';
import '../_router_lan_settings.dart';

const _rules = <String, dynamic>{
  'rules': <Map<String, dynamic>>[],
  'maxRules': 50,
  'maxDescriptionLength': 32,
};

void main() {
  late RouterBoundary router;

  mockDependencyRegister();

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getDDNSSettings, {
        'ddnsProvider': 'No-IP',
        'noipSettings': {
          'username': 'bob',
          'password': 'pw',
          'hostName': 'bob.ddns.net',
        },
      })
      ..holds(JNAPAction.getSupportedDDNSProviders, {
        'supportedDDNSProviders': ['DynDNS', 'No-IP', 'TZO'],
      })
      ..holds(JNAPAction.getDDNSStatus, {'status': 'Success'})
      ..holds(JNAPAction.getWANStatus, {
        'macAddress': '00:11:22:33:44:55',
        'detectedWANType': 'DHCP',
        'wanStatus': 'Connected',
        'wanIPv6Status': 'Connecting',
        'supportedWANTypes': ['DHCP', 'Static', 'PPPoE'],
      })
      ..holds(JNAPAction.getLANSettings, routerLanSettings)
      ..holds(JNAPAction.getSinglePortForwardingRules, _rules)
      ..holds(JNAPAction.getPortRangeForwardingRules, _rules)
      ..holds(JNAPAction.getPortRangeTriggeringRules, _rules);
  });

  /// Opens the page, and turns DDNS off: an edit on a tab that was read.
  Future<void> openAndEdit(WidgetTester tester) async {
    await tester.pumpWidget(testableSingleRoute(
      overrides: [routerRepositoryProvider.overrideWithValue(router.repo)],
      child: const AppsGamingSettingsView(),
    ));
    await tester.pumpAndSettle();
    ProviderScope.containerOf(
            tester.element(find.byType(AppsGamingSettingsView)))
        .read(ddnsProvider.notifier)
        .setProvider(noDNSProviderName);
    await tester.pumpAndSettle();
  }

  /// The router refuses [action] after 200 ms, as a router does over the
  /// network. Refused at once, the page's read would fail before
  /// doSomethingWithSpinner listens to it, 100 ms after it puts up its
  /// spinner, and the test would end on an uncaught error.
  void refusesLate(JNAPAction action) {
    when(router.repo.send(
      action,
      data: anyNamed('data'),
      extraHeaders: anyNamed('extraHeaders'),
      auth: anyNamed('auth'),
      type: anyNamed('type'),
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      throw const JNAPError(result: 'ErrorUnknown');
    });
  }

  bool isSaveOn(WidgetTester tester) =>
      tester
          .widget<AppFilledButton>(find.widgetWithText(AppFilledButton, 'Save'))
          .onTap !=
      null;

  testWidgets('every tab read: an edit turns Save on', (tester) async {
    await openAndEdit(tester);

    expect(find.textContaining('Unknown error'), findsNothing);
    expect(isSaveOn(tester), isTrue);
  });

  testWidgets('a refused read is reported, and Save stays off after an edit',
      (tester) async {
    refusesLate(JNAPAction.getPortRangeTriggeringRules);

    await openAndEdit(tester);

    expect(find.text('Unknown error: ErrorUnknown'), findsOneWidget);
    expect(isSaveOn(tester), isFalse);
  });
}
