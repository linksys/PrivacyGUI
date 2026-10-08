import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/administration_settings_test_state.dart';

const _readOnly = AccessPolicy(canWrite: false);
const _prompt = 'You have unsaved changes on this page';

/// The real notifier with the router taken out: it loads a fixed state and
/// keeps the real setters the page edits through.
class _LoadedAdministration extends AdministrationSettingsNotifier {
  @override
  AdministrationSettingsState build() =>
      AdministrationSettingsState.fromMap(administrationSettingsTestState);

  @override
  Future<AdministrationSettingsState> fetch([bool force = false]) async =>
      state;
}

// #1637: every settings page asks, through showUnsavedAlert, before leaving
// with unsaved edits. A login that may not write could never save them, so the
// question has only one answer and is not asked.
void main() {
  mockDependencyRegister();

  group('showUnsavedAlert', () {
    late bool? answer;

    Future<void> ask(WidgetTester tester, AccessPolicy policy) async {
      answer = null;
      await tester.pumpWidget(testableSingleRoute(
        locale: const Locale('en'),
        overrides: [accessPolicyProvider.overrideWithValue(policy)],
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () async => answer = await showUnsavedAlert(context),
            child: const Text('leave'),
          ),
        ),
      ));
      await tester.tap(find.text('leave'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks with full access, and Go back keeps the edits',
        (tester) async {
      await ask(tester, AccessPolicy.full);
      expect(find.text(_prompt), findsOneWidget);

      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();

      expect(answer, isNull);
    });

    testWidgets('asks with full access, and Discard changes discards',
        (tester) async {
      await ask(tester, AccessPolicy.full);

      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();

      expect(answer, isTrue);
    });

    testWidgets('discards without asking on a read-only login',
        (tester) async {
      await ask(tester, _readOnly);

      expect(find.text(_prompt), findsNothing);
      expect(answer, isTrue);
    });
  });

  // One page end to end, so the shortcut is seen to reach a caller: leaving an
  // edited page on a read-only login just leaves.
  group('leaving an edited settings page', () {
    Future<void> editThenLeave(WidgetTester tester, AccessPolicy policy) async {
      await tester.setScreenSize(device1440w);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(testableSingleRoute(
        locale: const Locale('en'),
        overrides: [
          administrationSettingsProvider.overrideWith(_LoadedAdministration.new),
          accessPolicyProvider.overrideWithValue(policy),
        ],
        extraRoutes: [
          LinksysRoute(
            path: '/administration',
            builder: (context, state) => const AdministrationSettingsView(),
          ),
        ],
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => context.push('/administration'),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate(
          (w) => w is AppSwitch && w.semanticLabel == 'upnp switch'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('back'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks first with full access', (tester) async {
      await editThenLeave(tester, AccessPolicy.full);

      expect(find.text(_prompt), findsOneWidget);
      expect(find.byType(AdministrationSettingsView), findsOneWidget);
    });

    testWidgets('just leaves on a read-only login', (tester) async {
      await editThenLeave(tester, _readOnly);

      expect(find.text(_prompt), findsNothing);
      expect(find.byType(AdministrationSettingsView), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
