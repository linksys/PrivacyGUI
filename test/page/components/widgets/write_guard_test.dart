import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/components/widgets/write_guard.dart';

void main() {
  Future<int> tapGuarded(WidgetTester tester, AccessPolicy policy,
      {bool localOnly = false, bool isRemote = false}) async {
    var taps = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        accessPolicyProvider.overrideWithValue(policy),
        isRemoteLoginProvider.overrideWithValue(isRemote),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WriteGuard(
            localOnly: localOnly,
            child: TextButton(
                onPressed: () => taps++, child: const Text('change')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('change'), warnIfMissed: false);
    await tester.pump();
    return taps;
  }

  testWidgets('blocks the control and says why in read-only mode',
      (tester) async {
    expect(await tapGuarded(tester, const AccessPolicy(canWrite: false)), 0);
    expect(find.byTooltip('This feature is unavailable in remote mode'),
        findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.5);
  });

  testWidgets('is transparent with full access', (tester) async {
    expect(await tapGuarded(tester, AccessPolicy.full), 1);
    expect(find.byType(Tooltip), findsNothing);
    expect(find.byType(Opacity), findsNothing);
  });

  // Manual firmware upload posts to the router's local address, so it cannot
  // work over a remote session whether or not the build asks for read-only.
  testWidgets('a local-only control is blocked on any remote login',
      (tester) async {
    expect(
        await tapGuarded(tester, AccessPolicy.full,
            localOnly: true, isRemote: true),
        0);
  });

  testWidgets('a local-only control works on a local login', (tester) async {
    expect(
        await tapGuarded(tester, AccessPolicy.full,
            localOnly: true, isRemote: false),
        1);
  });
}
