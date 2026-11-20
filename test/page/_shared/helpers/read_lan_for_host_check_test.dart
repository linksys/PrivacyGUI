import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/helpers/read_lan_for_host_check.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../../mocks/provider_overrides/mock_dhcp.dart';
import '../../../mocks/test_data/local_network_test_data.dart';

/// A LAN whose read is answered when the test says so.
class _PendingLanDataNotifier extends LanDataNotifier {
  _PendingLanDataNotifier(this.answer);
  final Completer<LanData> answer;

  @override
  Future<LanData> build() => answer.future;
}

/// The LAN read every form that writes a LAN host's address makes first
/// (#1838).
void main() {
  /// Pumps one button that calls [readLanForHostCheck] and records each
  /// result; returns the list it records into.
  Future<List<({String ip, String mask})?>> pump(
      WidgetTester tester, Override lan) async {
    final results = <({String ip, String mask})?>[];
    await tester.pumpWidget(ProviderScope(
      overrides: [lan],
      child: MaterialApp(
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () async =>
                  results.add(await readLanForHostCheck(context, ref)),
              child: const Text('check'),
            ),
          ),
        ),
      ),
    ));
    return results;
  }

  testWidgets('answers the LAN address and mask', (tester) async {
    final results = await pump(
        tester,
        lanDataProvider.overrideWith(
            () => FixedLanDataNotifier(LocalNetworkTestData.createLanData())));

    await tester.tap(find.text('check'));
    await tester.pumpAndSettle();

    expect(results, [(ip: '192.168.1.1', mask: '255.255.255.0')]);
  });

  testWidgets('a LAN that cannot be read answers null and says why',
      (tester) async {
    final results = await pump(tester,
        lanDataProvider.overrideWith(() => UnreadableLanDataNotifier()));

    await tester.tap(find.text('check'));
    await tester.pumpAndSettle();

    expect(results, [null]);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('a second tap while the LAN is read does nothing',
      (tester) async {
    final answer = Completer<LanData>();
    final results = await pump(tester,
        lanDataProvider.overrideWith(() => _PendingLanDataNotifier(answer)));

    await tester.tap(find.text('check'));
    await tester.pump();
    await tester.tap(find.text('check'));
    await tester.pump();

    // The second call returns at once, with nothing; the first still waits.
    expect(results, [null]);

    answer.complete(LocalNetworkTestData.createLanData());
    await tester.pumpAndSettle();
    expect(results, [null, (ip: '192.168.1.1', mask: '255.255.255.0')]);

    // Once that read is over, a tap reads again.
    await tester.tap(find.text('check'));
    await tester.pumpAndSettle();
    expect(results, hasLength(3));
    expect(results.last, (ip: '192.168.1.1', mask: '255.255.255.0'));
  });
}
