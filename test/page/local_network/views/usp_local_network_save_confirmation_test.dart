// The router-IP save confirmation on `usp_local_network_view`, pinned as a
// mechanism rather than as pixels.
//
// This page's Save button asks before it writes: changing the router IP or the
// subnet mask can drop the browser's connection, so `_onSave` awaits
// `_showNetworkChangeConfirmation` and returns early unless the answer is
// literally `true` (`confirmed != true` treats both a Cancel and a barrier
// dismissal as "don't"). That dialog was a raw Material `AlertDialog` popped
// with `Navigator.of(ctx).pop(...)`; it is now `showSimpleAppDialog` popped with
// `context.pop(...)` — the app's dialog frame, per constitution Art. XV, and the
// same shape as the four shipped `showConfirmActionDialog` call sites.
//
// The conversion moved two things a static read cannot check:
//
//   - **Which navigator receives the pop.** `showSimpleAppDialog` pushes on the
//     ROOT navigator (`useRootNavigator: true`), and `context.pop` is go_router's
//     pop, not the enclosing `Navigator`'s. If those two disagree, the tap either
//     throws or pops the *page* — so these tests assert the page is still on
//     screen afterwards, which is the observation that tells the two apart.
//   - **Whether the value survives the trip.** A dialog that closes but returns
//     null reads as a cancel, which would silently turn Continue into a no-op.
//
// So the assertions are the save count, not the button colours: Cancel must leave
// it at zero and Continue must raise it to one. `AppDialog` present /
// `AlertDialog` absent is the one structural assertion, and it is here because it
// is the whole point of the change — a revert to the bare `AlertDialog` reds this
// file instead of passing quietly.
//
// Scope, stated plainly: `save()` is stubbed (see [_CountingLocalNetworkNotifier]),
// so nothing here covers the write itself or the post-save redirect — those are
// `usp_local_network_notifier_test.dart` and `lan_ip_redirect_dialog_test.dart`.
// What is covered is the gate in front of them.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/local_network/models/local_network_feature_state.dart';
import 'package:privacy_gui/page/local_network/providers/usp_local_network_notifier.dart';
import 'package:privacy_gui/page/local_network/views/usp_local_network_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../layout_gate/surface.dart';
import '../../../mocks/provider_overrides/mock_local_network.dart';
import '../../../mocks/test_data/scenes/local_network_scene_data.dart';

/// [FixedLocalNetworkNotifier] with a counted `save()`.
///
/// `save()` and not `performSave()`: the real `save()` reads
/// `sseManagerProvider` on an IP change (to drop SSE intentionally before the
/// redirect), which is the notifier's own behaviour and has its own tests. This
/// file only needs to know whether the save path was entered at all, and
/// stubbing the whole method keeps the confirmation dialog the only thing under
/// test.
class _CountingLocalNetworkNotifier extends FixedLocalNetworkNotifier {
  _CountingLocalNetworkNotifier(super.state);

  int saveCalls = 0;

  @override
  Future<LocalNetworkFeatureState> save() async {
    saveCalls++;
    return state;
  }
}

/// The English copy this file matches on, from `app_en.arb`.
const _confirmTitle = 'Change Network Settings?';
const _saveLabel = 'Save';

Finder _appButtonWithIdentifier(String identifier) => find.byWidgetPredicate(
      (w) => w is AppButton && w.identifier == identifier,
      description: "AppButton(identifier: '$identifier')",
    );

Finder _appButtonWithLabel(String label) => find.byWidgetPredicate(
      (w) => w is AppButton && w.label == label,
      description: "AppButton(label: '$label')",
    );

void main() {
  /// Pumps the real page over [dirtyState] — router IP 192.168.1.1 ->
  /// 192.168.2.1, so `hasNetworkChange` is true and Save must ask — and returns
  /// the notifier so the caller can read `saveCalls`.
  ///
  /// [pageSurfaceHost] is the shared "how do I pump a real view" tree
  /// (`GoRouter` + `LinksysRoute` + the app's theme/locale wiring + the GetIt
  /// singletons `UspTopBar` reads). The `GoRouter` ancestor is not scaffolding
  /// here: it is the thing `context.pop` talks to.
  Future<_CountingLocalNetworkNotifier> pumpPage(WidgetTester tester) async {
    final notifier = _CountingLocalNetworkNotifier(dirtyState());
    await setLayoutSurface(tester, const Size(1200, 1200));
    await tester.pumpWidget(pageSurfaceHost(
      view: const UspLocalNetworkView(),
      locale: const Locale('en'),
      overrides: [uspLocalNetworkProvider.overrideWith(() => notifier)],
    ));
    await tester.pumpAndSettle();
    return notifier;
  }

  Future<void> tapSave(WidgetTester tester) async {
    final save = _appButtonWithLabel(_saveLabel);
    expect(save, findsOneWidget,
        reason:
            'the bottom bar Save button should be the only one so labelled');
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  group('local network save confirmation', () {
    testWidgets(
        'Save on a changed router IP asks first, in the AppDialog frame',
        (tester) async {
      final notifier = await pumpPage(tester);
      await tapSave(tester);

      expect(find.byType(AppDialog), findsOneWidget,
          reason: 'the confirmation must use the app dialog frame');
      expect(find.byType(AlertDialog), findsNothing,
          reason:
              'the raw Material AlertDialog this replaced must not be back');
      expect(find.text(_confirmTitle), findsOneWidget);
      expect(_appButtonWithIdentifier('network-change-cancel'), findsOneWidget);
      expect(
          _appButtonWithIdentifier('network-change-continue'), findsOneWidget);
      expect(notifier.saveCalls, 0,
          reason: 'nothing may be written before the answer');
    });

    testWidgets('Cancel closes only the dialog and does not save',
        (tester) async {
      final notifier = await pumpPage(tester);
      await tapSave(tester);

      await tester.tap(_appButtonWithIdentifier('network-change-cancel'));
      await tester.pumpAndSettle();

      expect(find.text(_confirmTitle), findsNothing,
          reason: 'the dialog should be gone');
      // The page, not the dialog, is what a wrong navigator would have popped.
      expect(find.byType(UspLocalNetworkView), findsOneWidget,
          reason: 'context.pop must close the dialog, not the page under it');
      expect(find.byType(AppIpv4TextField), findsWidgets,
          reason: 'the page should still be rendering its form');
      expect(notifier.saveCalls, 0, reason: 'Cancel must not save');
    });

    testWidgets('Continue closes the dialog and runs the save', (tester) async {
      final notifier = await pumpPage(tester);
      await tapSave(tester);

      await tester.tap(_appButtonWithIdentifier('network-change-continue'));
      await tester.pumpAndSettle();

      expect(find.text(_confirmTitle), findsNothing,
          reason: 'the dialog should be gone');
      expect(find.byType(UspLocalNetworkView), findsOneWidget,
          reason: 'context.pop must close the dialog, not the page under it');
      // The assertion the returned value is load-bearing for: `_onSave` only
      // reaches `save()` when the dialog answers exactly `true`, so a dropped
      // result would read back as 0 here.
      expect(notifier.saveCalls, 1, reason: 'Continue must save exactly once');
    });
  });
}
