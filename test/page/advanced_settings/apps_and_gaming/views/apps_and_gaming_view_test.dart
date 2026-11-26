import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_state.dart';

import '../../../../common/config.dart';
import '../../../../common/di.dart';
import '../../../../common/semantics_identifiers.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/apps_and_gaming_view_notifier_spec_mocks.dart';
import '../../../../mocks/ddns_notifier_spec_mocks.dart';
import '../../../../mocks/port_range_forwarding_list_notifier_mocks.dart';
import '../../../../mocks/port_range_triggering_list_notifier_mocks.dart';
import '../../../../mocks/single_port_forwarding_list_notifier_mocks.dart';
import '../../../../test_data/ddns_test_state.dart';

const _tabIds = [
  'apps-gaming-tab-ddns',
  'apps-gaming-tab-single-port',
  'apps-gaming-tab-port-range',
  'apps-gaming-tab-port-triggering',
];

// E2E tests reach each tab by these (constitution 11.2, 11.3): a raw Tab takes
// no identifier, and its text is translated.
void main() {
  late MockAppsAndGamingViewNotifier mockAppsAndGamingViewNotifier;
  late MockDDNSNotifier mockDDNSNotifier;
  late MockSinglePortForwardingListNotifier
      mockSinglePortForwardingListNotifier;
  late MockPortRangeForwardingListNotifier mockPortRangeForwardingListNotifier;
  late MockPortRangeTriggeringListNotifier mockPortRangeTriggeringListNotifier;

  mockDependencyRegister();

  setUp(() {
    mockAppsAndGamingViewNotifier = MockAppsAndGamingViewNotifier();
    mockDDNSNotifier = MockDDNSNotifier();
    mockSinglePortForwardingListNotifier =
        MockSinglePortForwardingListNotifier();
    mockPortRangeForwardingListNotifier = MockPortRangeForwardingListNotifier();
    mockPortRangeTriggeringListNotifier = MockPortRangeTriggeringListNotifier();

    when(mockAppsAndGamingViewNotifier.build())
        .thenReturn(AppsAndGamingViewState.fromMap(const {}));
    when(mockDDNSNotifier.build()).thenReturn(DDNSState.fromMap(ddnsTestState));
    when(mockSinglePortForwardingListNotifier.build())
        .thenReturn(const SinglePortForwardingListState());
    when(mockPortRangeForwardingListNotifier.build())
        .thenReturn(const PortRangeForwardingListState());
    when(mockPortRangeTriggeringListNotifier.build())
        .thenReturn(const PortRangeTriggeringListState());
  });

  testWidgets('a test opens Single Port Forwarding by its tab\'s identifier',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        appsAndGamingProvider.overrideWith(() => mockAppsAndGamingViewNotifier),
        ddnsProvider.overrideWith(() => mockDDNSNotifier),
        singlePortForwardingListProvider
            .overrideWith(() => mockSinglePortForwardingListNotifier),
        portRangeForwardingListProvider
            .overrideWith(() => mockPortRangeForwardingListNotifier),
        portRangeTriggeringListProvider
            .overrideWith(() => mockPortRangeTriggeringListNotifier),
      ],
      child: const AppsGamingSettingsView(),
    ));
    await tester.pumpAndSettle();

    final tabs = identifierCounts(_tabIds);
    final addBefore = identifierCounts(['pf-single-add']);
    await tester.tap(find.bySemanticsIdentifier('apps-gaming-tab-single-port'));
    await tester.pumpAndSettle();
    final addAfter = identifierCounts(['pf-single-add']);
    // Before any expect: flutter_test checks for a live handle before
    // tear-down runs.
    semantics.dispose();

    expect(tabs.values, everyElement(1), reason: '$tabs');
    expect(addBefore, {'pf-single-add': 0});
    expect(addAfter, {'pf-single-add': 1});
  });
}
