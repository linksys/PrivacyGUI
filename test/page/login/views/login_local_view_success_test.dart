import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/login/views/login_local_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_login.dart';
import '../../../mocks/test_data/scenes/login_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// #1641: after a successful login the page showed its password form again for
/// a moment before the post-login redirect replaced it — the full-screen loader
/// ended the instant auth left `loading`, and the form was the `data` branch.
/// Seen on the bench as a flash of the login page between submit and dashboard.
///
/// Once the login has succeeded the page is leaving, so the loader must stay up
/// until it does: this pins that the form is not on screen anywhere between the
/// login completing and the navigation away.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  testWidgets('a successful login keeps the loader up until the page leaves',
      (tester) async {
    final auth = _ScriptedAuth();
    await tester.pumpWidget(pageSurfaceHost(
      view: const LoginLocalView(),
      locale: const Locale('en'),
      overrides: [
        ...loginLocalOverrides(
          authState: localLoginWithHintState,
          deviceInfo: testLoginDeviceInfo,
        ),
        authProvider.overrideWith(() => auth),
      ],
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(AppPasswordInput), findsOneWidget,
        reason: 'the form is shown before submitting');

    auth.startLogin();
    await tester.pump();
    expect(find.byType(AppFullScreenLoader), findsOneWidget);

    auth.finishLogin();
    // In the app the post-login redirect replaces this page a few frames later;
    // here the page *is* `/`, so `go('/')` keeps it, which holds open exactly the
    // frames the flash appeared in.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(AppPasswordInput), findsNothing,
          reason: 'the login succeeded — the form must not flash back');
      expect(find.byType(AppFullScreenLoader), findsOneWidget);
    }
  });

  testWidgets(
      'if the redirect lands back on the login page, the form comes back',
      (tester) async {
    // e.g. `_prepare` could not read device info and routed to
    // `/localLoginPassword?error=noDeviceInfo`: the same page, new args. It must
    // not stay on the loader it showed while leaving.
    final auth = _ScriptedAuth();
    final args = ValueNotifier<Map<String, dynamic>>(const {});
    await tester.pumpWidget(pageSurfaceHost(
      view: ValueListenableBuilder<Map<String, dynamic>>(
        valueListenable: args,
        builder: (_, a, __) => LoginLocalView(args: a),
      ),
      locale: const Locale('en'),
      overrides: [
        ...loginLocalOverrides(
          authState: localLoginWithHintState,
          deviceInfo: testLoginDeviceInfo,
        ),
        authProvider.overrideWith(() => auth),
      ],
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    auth.startLogin();
    await tester.pump();
    auth.finishLogin();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(AppFullScreenLoader), findsOneWidget);

    args.value = const {'error': 'noDeviceInfo'};
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(AppPasswordInput), findsOneWidget);
  });
}

/// Auth whose login the test steps through: loading, then logged in.
class _ScriptedAuth extends AuthNotifier {
  @override
  Future<AuthState> build() async => localLoginWithHintState;

  void startLogin() => state = const AsyncValue.loading();

  void finishLogin() => state = AsyncValue.data(
      localLoginWithHintState.copyWith(loginType: LoginType.local));
}
