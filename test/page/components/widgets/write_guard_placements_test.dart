import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/views/device_list_widget.dart';
import 'package:privacy_gui/page/instant_topology/views/model/node_instant_actions.dart';
import 'package:privacy_gui/page/instant_topology/views/widgets/node_action_menu.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../common/config.dart';
import '../../../common/screen.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

const _readOnly = AccessPolicy(canWrite: false);

// #1637: the shared components that write each carry their own guard, so every
// page built on them is covered without checking access itself.
void main() {
  mockDependencyRegister();

  Future<void> pump(WidgetTester tester, Widget child,
      {AccessPolicy policy = AccessPolicy.full,
      ScreenSize screen = device1440w}) async {
    await tester.setScreenSize(screen);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [accessPolicyProvider.overrideWithValue(policy)],
      child: child,
    ));
    await tester.pumpAndSettle();
  }

  group('device list', () {
    const device = DeviceListItem(
      deviceId: 'd1',
      name: 'Phone',
      isOnline: true,
      isWired: false,
    );
    late List<String> calls;

    setUp(() {
      calls = [];
      when(serviceHelper.isSupportClientDeauth()).thenReturn(true);
    });

    Widget list() => Scaffold(
          body: DeviceListWidget(
            devices: const [device],
            enableDeauth: true,
            enableDelete: true,
            onItemDeauth: (_) => calls.add('deauth'),
            onItemDelete: (_) => calls.add('delete'),
            onItemClick: (_) => calls.add('open'),
          ),
        );

    Future<void> tapIcon(WidgetTester tester, IconData icon) async {
      await tester.tap(find.byIcon(icon), warnIfMissed: false);
      await tester.pump();
    }

    testWidgets('deauth and delete are blocked in read-only mode',
        (tester) async {
      await pump(tester, list(), policy: _readOnly);

      await tapIcon(tester, LinksysIcons.bidirectional);
      await tapIcon(tester, LinksysIcons.delete);

      expect(calls, isNot(contains('deauth')));
      expect(calls, isNot(contains('delete')));
    });

    // Opening a device's details only reads it.
    testWidgets('the device can still be opened in read-only mode',
        (tester) async {
      await pump(tester, list(), policy: _readOnly);

      await tester.tap(find.text('Phone'));
      await tester.pump();

      expect(calls, ['open']);
    });

    testWidgets('deauth and delete work with full access', (tester) async {
      await pump(tester, list());

      await tapIcon(tester, LinksysIcons.bidirectional);
      await tapIcon(tester, LinksysIcons.delete);

      expect(calls, ['deauth', 'delete']);
    });
  });

  group('node action menu', () {
    late List<NodeInstantActions> taps;

    setUp(() => taps = []);

    Widget menu() => Scaffold(
          body: NodeActionMenu(
            actions: const [NodeInstantActions.reboot],
            onActionTap: taps.add,
            itemBuilder: (context, action) => Text(action.name),
          ),
        );

    testWidgets('does not open in read-only mode', (tester) async {
      await pump(tester, menu(), policy: _readOnly);

      await tester.tap(find.byType(PopupMenuButton<NodeInstantActions>),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('reboot'), findsNothing);
    });

    testWidgets('opens and acts with full access', (tester) async {
      await pump(tester, menu());

      await tester.tap(find.byType(PopupMenuButton<NodeInstantActions>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('reboot'));
      await tester.pumpAndSettle();

      expect(taps, [NodeInstantActions.reboot]);
    });
  });

  // StyledAppTabPageView builds its menu rows with the same pageMenuItemTile as
  // StyledAppPageView, so a writing row is blocked there too. It shows the menu
  // only on a phone, in a sheet opened from the app bar.
  group('tab page menu', () {
    late int writes, navigations;

    setUp(() {
      writes = 0;
      navigations = 0;
    });

    // ignore: deprecated_member_use_from_same_package
    Widget page() => StyledAppTabPageView(
          tabs: const [Tab(text: 'Tab')],
          tabContentViews: const [SizedBox.shrink()],
          menu: PageMenu(items: [
            PageMenuItem(
                label: 'Restart',
                icon: null,
                isWrite: true,
                onTap: () => writes++),
            PageMenuItem(
                label: 'Open page', icon: null, onTap: () => navigations++),
          ]),
        );

    Future<void> tapRows(WidgetTester tester) async {
      await tester.tap(find.byIcon(LinksysIcons.moreHoriz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restart'), warnIfMissed: false);
      await tester.tap(find.text('Open page'));
      await tester.pump();
    }

    testWidgets('a writing row is blocked in read-only mode', (tester) async {
      await pump(tester, page(), policy: _readOnly, screen: device480w);
      await tapRows(tester);
      expect((writes, navigations), (0, 1));
    });

    testWidgets('both rows work with full access', (tester) async {
      await pump(tester, page(), screen: device480w);
      await tapRows(tester);
      expect((writes, navigations), (1, 1));
    });
  });
}
