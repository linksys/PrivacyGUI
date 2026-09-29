import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/topology/helpers/topology_tree_labels.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The words the app puts on a tree row, including the three it deliberately
/// withholds.
///
/// ui_kit 3.4.0 stopped shipping label text for a node's slot and state, which
/// closed a defect — the kit used to print its own enum names, so the row read
/// `GATEWAY` / `online` in English in all 26 locales. The replacement is these
/// two builders, and **three of their five slot arms return null on purpose**.
/// That intent lived only in a doc comment, so filling an arm in later would have
/// been silent; these tests are what make it loud.
void main() {
  /// A context with the app's localisations resolved, which the builders need.
  Future<BuildContext> contextFor(WidgetTester tester, Locale locale) async {
    late BuildContext captured;
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        captured = context;
        return const SizedBox.shrink();
      }),
    ));
    await tester.pumpAndSettle();
    return captured;
  }

  GraphNode node({bool external = false}) => GraphNode(
        id: 'n1',
        name: 'n1',
        external: external,
        status: NodeState.active,
      );

  group('the slot label', () {
    testWidgets('names the master and the slave', (tester) async {
      final context = await contextFor(tester, const Locale('en'));

      expect(TopologyTreeLabels.slot(context, node(), NodeStyleSlot.primary),
          'MASTER');
      expect(TopologyTreeLabels.slot(context, node(), NodeStyleSlot.secondary),
          'SLAVE');
    });

    testWidgets('withholds a word for a leaf', (tester) async {
      final context = await contextFor(tester, const Locale('en'));

      // Every string this app has for a terminal device is plural (`devices`,
      // `clients`) and a row label is singular. A leaf is also what a tree row is
      // by default, so it is the row that needs a caption least. If a `device` key
      // is ever added to the ARB, this expectation is what says to revisit.
      expect(
          TopologyTreeLabels.slot(context, node(), NodeStyleSlot.leaf), isNull);
    });

    testWidgets('withholds a word for tertiary, which this app never assigns',
        (tester) async {
      final context = await contextFor(tester, const Locale('en'));

      expect(TopologyTreeLabels.slot(context, node(), NodeStyleSlot.tertiary),
          isNull);
    });

    testWidgets('withholds a word for an external node, whatever its slot',
        (tester) async {
      final context = await contextFor(tester, const Locale('en'));

      // Tested across every slot, because the externality check sits *before* the
      // switch: "Master" is wrong for an upstream endpoint, and a future slot
      // assignment must not leak a word for it.
      for (final slot in NodeStyleSlot.values) {
        expect(
          TopologyTreeLabels.slot(context, node(external: true), slot),
          isNull,
          reason: slot.name,
        );
      }
    });
  });

  group('the status label', () {
    testWidgets('names active and inactive', (tester) async {
      final context = await contextFor(tester, const Locale('en'));

      expect(TopologyTreeLabels.status(context, NodeState.active), 'Online');
      expect(TopologyTreeLabels.status(context, NodeState.inactive), 'Offline');
    });

    testWidgets('withholds a word for alert, which this app never produces',
        (tester) async {
      final context = await contextFor(tester, const Locale('en'));

      // Borrowing `Online` or `Offline` here would assert something about the node
      // that is not true, and there is no third string.
      expect(TopologyTreeLabels.status(context, NodeState.alert), isNull);
    });
  });

  group('the labels are localised, which is the point of owning them', () {
    testWidgets('a non-English locale gets its own words', (tester) async {
      final english = await contextFor(tester, const Locale('en'));
      final englishSlot =
          TopologyTreeLabels.slot(english, node(), NodeStyleSlot.primary);
      final englishStatus =
          TopologyTreeLabels.status(english, NodeState.active);

      final chinese = await contextFor(
          tester, const Locale.fromSubtags(languageCode: 'zh'));
      final chineseSlot =
          TopologyTreeLabels.slot(chinese, node(), NodeStyleSlot.primary);
      final chineseStatus =
          TopologyTreeLabels.status(chinese, NodeState.active);

      // Asserted as "differs from English" rather than against a literal
      // translation: the ARB owns the wording, and pinning it here would make a
      // copy change red this test for no defect. What matters is that the words
      // come from the ARB at all — the kit's own enum names would be identical in
      // every locale, which is the defect this replaced.
      expect(chineseSlot, isNotNull);
      expect(chineseStatus, isNotNull);
      expect(
        [chineseSlot, chineseStatus],
        isNot([englishSlot, englishStatus]),
        reason: 'a localised label must not be the English one in zh',
      );
    });
  });
}
