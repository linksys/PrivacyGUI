import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../../common/config.dart';
import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/internet_settings_notifier_mocks.dart';
import '../../../../test_data/internet_settings_state_data.dart';

const _readOnly = AccessPolicy(canWrite: false);
const _guardTooltip = 'This feature is unavailable in remote mode';

void main() {
  mockDependencyRegister();

  late MockInternetSettingsNotifier internetSettings;

  setUp(() {
    internetSettings = MockInternetSettingsNotifier();
    final state = InternetSettingsState.fromMap(internetSettingsStateDHCP);
    when(internetSettings.build()).thenReturn(state);
    when(internetSettings.fetch(fetchRemote: anyNamed('fetchRemote')))
        .thenAnswer((_) async => state);
  });

  Future<void> pumpPage(WidgetTester tester,
      {AccessPolicy policy = AccessPolicy.full,
      bool remoteLogin = false}) async {
    await tester.setScreenSize(device1440w.copyWith(height: 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        internetSettingsProvider.overrideWith(() => internetSettings),
        accessPolicyProvider.overrideWithValue(policy),
        isRemoteLoginProvider.overrideWithValue(remoteLogin),
      ],
      child: const InternetSettingsView(),
    ));
    await tester.pumpAndSettle();
  }

  // #1637: release and renew drops the WAN lease and asks for a new one, a
  // write on either stack, so both buttons are blocked before they open the
  // confirm dialog.
  group('release and renew', () {
    // The tab and both buttons share the label; the buttons are the ones that
    // are not tabs.
    final renewButtons = find.descendant(
        of: find.byType(TabBarView), matching: find.text('Release & Renew'));
    const confirmTitle = 'Release and Renew IP address';

    Future<void> openTab(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(Tab, 'Release & Renew'));
      await tester.pumpAndSettle();
      expect(renewButtons, findsNWidgets(2));
    }

    for (final (index, stack) in [(0, 'IPv4'), (1, 'IPv6')]) {
      testWidgets('the $stack button is blocked in read-only mode',
          (tester) async {
        await pumpPage(tester, policy: _readOnly);
        await openTab(tester);
        final button = renewButtons.at(index);

        expect(
            find.ancestor(of: button, matching: find.byTooltip(_guardTooltip)),
            findsOneWidget);

        await tester.tap(button, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text(confirmTitle), findsNothing);
        verifyNever(internetSettings.renewDHCPWANLease());
        verifyNever(internetSettings.renewDHCPIPv6WANLease());
      });

      testWidgets('the $stack button opens the confirm dialog with full access',
          (tester) async {
        await pumpPage(tester);
        await openTab(tester);

        await tester.tap(renewButtons.at(index));
        await tester.pumpAndSettle();

        expect(find.text(confirmTitle), findsOneWidget);
      });
    }
  });

  // #1637: Edit is local-only on top of read-only: changing the WAN over a
  // remote session can cut off the very connection the change is made through,
  // so any remote login is kept out of edit mode, full access or not.
  group('edit', () {
    final edit = find.byIcon(LinksysIcons.edit);

    testWidgets('is blocked on a remote login, even with full access',
        (tester) async {
      await pumpPage(tester, remoteLogin: true);

      expect(find.ancestor(of: edit, matching: find.byTooltip(_guardTooltip)),
          findsOneWidget);

      await tester.tap(edit, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byIcon(LinksysIcons.close), findsNothing,
          reason: 'the page never entered edit mode');
    });

    testWidgets('enters edit mode on a local login', (tester) async {
      await pumpPage(tester);

      await tester.tap(edit);
      await tester.pumpAndSettle();

      expect(find.byIcon(LinksysIcons.close), findsOneWidget);
    });
  });
}
