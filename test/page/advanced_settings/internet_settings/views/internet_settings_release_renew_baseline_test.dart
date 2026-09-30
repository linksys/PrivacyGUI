// Baseline for Internet Settings' Release & Renew in the default build.
//
// Release & Renew writes to the router from its own confirm dialog, bypassing
// the page's Save bar, so a read-only build has to disable both buttons
// individually. These tests pin that in the default build, with a DHCP WAN,
// both are live and each reaches its lease renewal after confirmation.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/di.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/internet_settings_notifier_mocks.dart';
import '../../../../test_data/internet_settings_state_data.dart';

void main() {
  late MockInternetSettingsNotifier mockInternetSettingsNotifier;

  mockDependencyRegister();

  setUp(() {
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();
    final state = InternetSettingsState.fromMap(internetSettingsStateDHCP);
    when(mockInternetSettingsNotifier.build()).thenReturn(state);
    when(mockInternetSettingsNotifier.fetch(
            fetchRemote: anyNamed('fetchRemote')))
        .thenAnswer((_) async => state);
    when(mockInternetSettingsNotifier.renewDHCPWANLease())
        .thenAnswer((_) async {});
    when(mockInternetSettingsNotifier.renewDHCPIPv6WANLease())
        .thenAnswer((_) async {});
  });

  Future<void> openReleaseAndRenewTab(WidgetTester tester) async {
    await tester.pumpWidget(testableSingleRoute(
      overrides: [
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
      ],
      child: const InternetSettingsView(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Release & Renew').first);
    await tester.pumpAndSettle();
  }

  // The tab label is also "Release & Renew"; the buttons are the text buttons.
  Finder renewButtons() =>
      find.widgetWithText(AppTextButton, 'Release & Renew');

  testWidgets('both renew buttons are live on a DHCP WAN', (tester) async {
    await openReleaseAndRenewTab(tester);

    final buttons = tester.widgetList<AppTextButton>(renewButtons()).toList();
    expect(buttons, hasLength(2));
    expect(buttons.every((b) => b.onTap != null), isTrue);
  });

  for (final (index, label) in [(0, 'IPv4'), (1, 'IPv6')]) {
    testWidgets('$label renew asks first, then renews', (tester) async {
      await openReleaseAndRenewTab(tester);

      await tester.tap(renewButtons().at(index));
      await tester.pumpAndSettle();
      verifyNever(mockInternetSettingsNotifier.renewDHCPWANLease());
      verifyNever(mockInternetSettingsNotifier.renewDHCPIPv6WANLease());

      // The dialog's confirm button carries the same label; it is the last one.
      await tester.tap(renewButtons().last);
      await tester.pumpAndSettle();
      if (index == 0) {
        verify(mockInternetSettingsNotifier.renewDHCPWANLease()).called(1);
      } else {
        verify(mockInternetSettingsNotifier.renewDHCPIPv6WANLease()).called(1);
      }
    });
  }

  testWidgets('cancelling renew sends nothing', (tester) async {
    await openReleaseAndRenewTab(tester);

    await tester.tap(renewButtons().first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppTextButton, 'Cancel'));
    await tester.pumpAndSettle();
    verifyNever(mockInternetSettingsNotifier.renewDHCPWANLease());
  });
}
