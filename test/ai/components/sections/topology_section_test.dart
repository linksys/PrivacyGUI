import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/ai/components/sections/topology_section.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// What the AI section builds from a model-authored payload.
///
/// The payload is written by a language model against the prompt's schema
/// (`router_system_prompt.dart:223-224`), so the question every field raises is what
/// the section does when it is **absent** — and the answer must be the same at every
/// place that field is read. It was not: an extender with no `rssi` got an edge
/// that declined to name its medium, a strength grade of `unknown` on that same
/// edge, and a node ring drawn full, because `getWifiSignalLevel(null)` answers
/// `wired`. One absent field, one abstention and two guesses.
///
/// Asserted on the `GraphData` the section hands the kit, which is its whole output.
void main() {
  Future<GraphData> build(
    WidgetTester tester, {
    List<Map<String, dynamic>>? extenders,
    List<Map<String, dynamic>>? clients,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.create(brightness: Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TopologySection(
          gatewayName: 'Router',
          extenders: extenders,
          clients: clients,
        ),
      ),
    ));
    await tester.pump();
    return tester.widget<AppTopology>(find.byType(AppTopology)).topology!;
  }

  GraphNode node(GraphData t, String id) =>
      t.nodes.firstWhere((n) => n.id == id);
  GraphEdge edgeTo(GraphData t, String id) =>
      t.edges.firstWhere((e) => e.targetId == id);

  group('an extender, whose schema has no medium field', () {
    testWidgets('with no rssi: nothing about the link is asserted',
        (tester) async {
      final t = await build(tester, extenders: [
        {'name': 'Study'},
      ]);

      final edge = edgeTo(t, 'extender-0');
      expect(edge.kind, isNull, reason: 'the model did not say');
      expect(edge.strength, isNull,
          reason: 'an edge that declines a medium must not also carry a grade');
      expect(node(t, 'extender-0').level, 0.0,
          reason: 'not a full ring — full means "wired" in this app');
    });

    testWidgets('with an rssi: wireless, graded, and the ring follows it',
        (tester) async {
      final t = await build(tester, extenders: [
        {'name': 'Study', 'rssi': -45},
      ]);

      final edge = edgeTo(t, 'extender-0');
      expect(edge.kind, EdgeKind.indirect);
      expect(edge.strength, isNotNull);
      expect(edge.strength, isNot(EdgeStrength.unknown));
      expect(node(t, 'extender-0').level, inExclusiveRange(0.0, 1.0));
    });
  });

  group('a client, whose schema does carry isWifi', () {
    testWidgets('known wired: direct, ungraded, full ring', (tester) async {
      final t = await build(tester, clients: [
        {'name': 'Desktop', 'isWifi': false},
      ]);

      final edge = edgeTo(t, 'client-0');
      expect(edge.kind, EdgeKind.direct);
      expect(edge.strength, isNull);
      expect(node(t, 'client-0').level, 1.0);
    });

    testWidgets('known wireless with a reading: indirect and graded',
        (tester) async {
      final t = await build(tester, clients: [
        {'name': 'Phone', 'isWifi': true, 'rssi': -60},
      ]);

      final edge = edgeTo(t, 'client-0');
      expect(edge.kind, EdgeKind.indirect);
      expect(edge.strength, isNotNull);
      expect(node(t, 'client-0').level, inExclusiveRange(0.0, 1.0));
    });

    testWidgets('known wireless with no reading: indirect, ring empty',
        (tester) async {
      // Wireless is stated, so the edge says so; but there is no measurement, so the
      // ring must not claim one — and certainly not the full ring a wired device gets.
      final t = await build(tester, clients: [
        {'name': 'Phone', 'isWifi': true},
      ]);

      expect(edgeTo(t, 'client-0').kind, EdgeKind.indirect);
      expect(node(t, 'client-0').level, 0.0);
    });

    testWidgets('medium not stated, but an rssi given: undeclared edge',
        (tester) async {
      // The client schema has `isWifi?`, so its absence is the model choosing not to
      // say. The reading still grades the ring — it is a measurement — but the edge
      // does not invent the medium from it the way the extender loop may, because
      // here the schema had a field for the medium and it was left out.
      final t = await build(tester, clients: [
        {'name': 'Laptop', 'rssi': -55},
      ]);

      expect(edgeTo(t, 'client-0').kind, isNull);
      expect(edgeTo(t, 'client-0').strength, isNull);
      expect(node(t, 'client-0').level, inExclusiveRange(0.0, 1.0));
    });

    testWidgets('nothing stated at all: nothing asserted', (tester) async {
      final t = await build(tester, clients: [
        {'name': 'Mystery'},
      ]);

      expect(edgeTo(t, 'client-0').kind, isNull);
      expect(edgeTo(t, 'client-0').strength, isNull);
      expect(node(t, 'client-0').level, 0.0);
    });
  });
}
