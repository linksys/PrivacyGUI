import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/device_credentials_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/support/views/components/remote_assistance_card.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

// =============================================================================
// The support page's Remote Assistance row must say when it cannot be used
// (#1582).
//
// Before this, an unusable row was *indistinguishable from a usable one*:
// `LayoutBlock` with a null `onTap` omits the `InkWell` and nothing else changes,
// so the row kept its chevron and its subtitle and simply ignored taps. On
// FL-WRT 2.0 that was the permanent state, because the UUID the row needs came
// from a `Device.Hosts.Host.{i}` leaf that firmware deleted.
//
// The semantics assertions are not decoration: an un-tappable `LayoutBlock` also
// drops `Semantics(button:)`, so E2E can still find the node while it is not a
// button. Both facts are pinned here so neither half can regress quietly.
//
// Not tagged `ui`: those tests are excluded by `run_tests.sh`, the repo's only CI
// test job, and this needs to run there.
// =============================================================================

void main() {
  const identifier = 'support-remote-assistance';

  const credentials = DeviceCredentials(
    serialNumber: '67A10M24F00066',
    macAddress: '74:12:13:21:55:02',
    deviceUUID: '3E68DD2F-CF4F-4E47-A99B-741213215502',
  );

  Widget wrap({DeviceCredentials? creds}) {
    return ProviderScope(
      overrides: [deviceCredentialsProvider.overrideWithValue(creds)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        home: const Scaffold(body: RemoteAssistanceCard()),
      ),
    );
  }

  testWidgets(
      'says it is not available, and is not a button, without credentials',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(creds: null));
    await tester.pumpAndSettle();

    expect(find.text('Not available'), findsOneWidget,
        reason: 'an unusable row must say so rather than look normal');
    expect(find.byIcon(Icons.chevron_right), findsNothing,
        reason: 'a chevron promises navigation this row cannot deliver');

    final node = tester.getSemantics(find.bySemanticsIdentifier(identifier));
    expect(node.flagsCollection.isButton, isFalse);

    handle.dispose();
  });

  testWidgets('is a button with a chevron once credentials exist',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(creds: credentials));
    await tester.pumpAndSettle();

    expect(find.text('Not available'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    final node = tester.getSemantics(find.bySemanticsIdentifier(identifier));
    expect(node.flagsCollection.isButton, isTrue);

    handle.dispose();
  });

  testWidgets('keeps its E2E identifier in both states', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(wrap(creds: null));
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier(identifier), findsOneWidget);

    await tester.pumpWidget(wrap(creds: credentials));
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier(identifier), findsOneWidget);

    handle.dispose();
  });
}
