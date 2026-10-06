import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/topology/views/components/node_detail_popup.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// What the panel shows for a mesh node, which nothing was pinning.
///
/// The leaf arm has had its own suite since 3.4.0 opened a panel for devices. This
/// arm had none, and that is how a regression shipped: localising the backhaul row
/// replaced a firmware string (`None`, honest but English) with a fabricated word
/// (`Wi-Fi`, localised and wrong), because the row's guard tested `isNotEmpty` while
/// the tree subtitle — added in the same commit — tested for the `None` sentinel too.
///
/// `LinkType` has three states, not two: a medium, the literal `None` that prplMesh
/// reports on the controller row, and absent. Each is a case below.
void main() {
  Future<void> pump(WidgetTester tester, Map<String, dynamic> metadata,
      {Locale locale = const Locale('en')}) async {
    final node = GraphNode(
      id: 'extender-1',
      name: 'Study Extender',
      styleSlot: 'secondary',
      status: NodeState.active,
      metadata: metadata,
    );

    await tester.pumpWidget(MaterialApp(
      locale: locale,
      theme: AppTheme.create(brightness: Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: NodeDetailPopup(node: node, metadata: metadata)),
    ));
    await tester.pumpAndSettle();
  }

  group('the backhaul medium row', () {
    testWidgets('a Wi-Fi backhaul says WiFi', (tester) async {
      await pump(tester, const {
        'isMaster': false,
        'backhaulLinkType': 'Wi-Fi',
        'backhaulSignalStrength': -55,
      });

      expect(find.text('WiFi'), findsOneWidget);
      expect(find.text('-55 dBm'), findsOneWidget);
    });

    testWidgets('an Ethernet backhaul says Ethernet and shows no signal',
        (tester) async {
      await pump(tester, const {
        'isMaster': false,
        'backhaulLinkType': 'Ethernet',
        // Present, and must still be suppressed: a wire has no RSSI by design, so a
        // reading beside `Ethernet` would be describing something else (#1555).
        'backhaulSignalStrength': -55,
      });

      expect(find.text('Ethernet'), findsOneWidget);
      expect(find.textContaining('dBm'), findsNothing);
    });

    testWidgets('a medium spelled unexpectedly still reads as Ethernet',
        (tester) async {
      // Classified through the shared predicate, which case-folds and trims, so a
      // build spelling the value differently does not fall into the Wi-Fi arm and
      // acquire a signal row it has no business showing.
      await pump(tester, const {
        'isMaster': false,
        'backhaulLinkType': '  ETHERNET  ',
        'backhaulSignalStrength': -55,
      });

      expect(find.text('Ethernet'), findsOneWidget);
      expect(find.textContaining('dBm'), findsNothing);
    });

    testWidgets("firmware's literal 'None' draws no medium row at all",
        (tester) async {
      // The regression. `None` is prplMesh's positive statement that this row has no
      // backhaul; an `isNotEmpty` guard let it through to a classifier that answers
      // "not Ethernet", so the panel said `WiFi` about a node that had just said it
      // has none.
      await pump(tester, const {
        'isMaster': false,
        'backhaulLinkType': 'None',
        'model': 'MX2000',
      });

      expect(find.text('WiFi'), findsNothing);
      expect(find.text('Ethernet'), findsNothing);
      // Nor the firmware string itself, which is what it printed before the row was
      // localised at all.
      expect(find.text('None'), findsNothing);
      // The rows it does have are unaffected.
      expect(find.text('MX2000'), findsOneWidget);
    });

    testWidgets("'None' is recognised whatever its casing", (tester) async {
      await pump(tester, const {
        'isMaster': false,
        'backhaulLinkType': '  NONE  ',
        'model': 'MX2000',
      });

      expect(find.text('WiFi'), findsNothing);
      expect(find.text('Ethernet'), findsNothing);
    });

    testWidgets('an absent medium draws no row either', (tester) async {
      await pump(tester, const {'isMaster': false, 'model': 'MX2000'});

      expect(find.text('WiFi'), findsNothing);
      expect(find.text('Ethernet'), findsNothing);
    });

    testWidgets('the medium is localised, not echoed', (tester) async {
      // Asserted on a **wired** backhaul: `wifi` is the literal `WiFi` in both
      // `app_en.arb` and `app_zh.arb`, so a Wi-Fi row reads identically in the two
      // locales whether the word came from the ARB or from firmware. Ethernet is the
      // one that differs.
      //
      // `Locale('zh')` resolves to `app_zh.arb`, which is Simplified — `以太网`, not
      // `app_zh_TW.arb`'s `乙太網路`. Measured, after asserting the Traditional form
      // and watching it find nothing.
      await pump(
        tester,
        const {'isMaster': false, 'backhaulLinkType': 'Ethernet'},
        locale: const Locale.fromSubtags(languageCode: 'zh'),
      );

      expect(find.text('Ethernet'), findsNothing,
          reason: 'the firmware spelling must not survive into a zh panel');
      expect(find.text('以太网'), findsOneWidget);
    });
  });

  group('the signal row', () {
    testWidgets('an RSSI with no named medium is still shown', (tester) async {
      // Deliberately **not** gated on the medium, unlike the row above.
      // `Backhaul.Stats.SignalStrength` measures this link whether or not firmware
      // named what carries it, so the reading is one we have and the label is one we
      // do not. The tree subtitle drops it in the same case for a different reason:
      // one line, shaped "medium, then signal", with nothing to hang it on.
      await pump(tester, const {
        'isMaster': false,
        'backhaulLinkType': 'None',
        'backhaulSignalStrength': -62,
      });

      expect(find.text('WiFi'), findsNothing);
      expect(find.text('-62 dBm'), findsOneWidget);
    });

    testWidgets('no RSSI means no row, not a zero', (tester) async {
      await pump(
          tester, const {'isMaster': false, 'backhaulLinkType': 'Wi-Fi'});

      expect(find.textContaining('dBm'), findsNothing);
    });
  });

  group('the master has no backhaul of this kind', () {
    testWidgets('no medium or signal row, whatever the metadata says',
        (tester) async {
      // The whole block sits inside `if (!isMaster)`: the controller's backhaul
      // fields describe nothing, so they are not drawn even when populated.
      await pump(tester, const {
        'isMaster': true,
        'backhaulLinkType': 'Wi-Fi',
        'backhaulSignalStrength': -55,
        'model': 'MR7500',
      });

      expect(find.text('WiFi'), findsNothing);
      expect(find.textContaining('dBm'), findsNothing);
      expect(find.text('MR7500'), findsOneWidget);
    });
  });

  group('the speed rows', () {
    testWidgets('both directions read from the ARB, not hardcoded English',
        (tester) async {
      await pump(
        tester,
        const {
          'isMaster': false,
          'backhaulLinkType': 'Wi-Fi',
          'backhaulUplinkRate': 100000000,
          'backhaulDownlinkRate': 200000000,
        },
        locale: const Locale.fromSubtags(languageCode: 'zh'),
      );

      // `Up:` / `Down:` used to be literals here. In zh the words come from the ARB
      // — Simplified, since `Locale('zh')` resolves to `app_zh.arb`.
      expect(find.textContaining('Up:'), findsNothing);
      expect(find.textContaining('Down:'), findsNothing);
      expect(find.textContaining('上传'), findsOneWidget);
    });

    testWidgets('one direction alone still draws a row', (tester) async {
      await pump(tester, const {
        'isMaster': false,
        'backhaulLinkType': 'Wi-Fi',
        'backhaulUplinkRate': 100000000,
      });

      expect(find.textContaining('Upload'), findsOneWidget);
      expect(find.textContaining('Download'), findsNothing);
    });
  });
}
