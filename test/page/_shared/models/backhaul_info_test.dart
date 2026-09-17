import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';

/// The three predicates on [BackhaulInfo] — `isEthernet`, `isWifi`, `hasInfo` —
/// against the four states the fields can be in.
///
/// They were exercised only through the node-detail widget tests and the topology
/// builder's decision table, which means every assertion about them ran a page
/// build first. #1555 changed what `isEthernet` reads (a shared, case-folded
/// predicate instead of `linkType == 'Ethernet'`) and what `hasInfo` counts (the
/// medium *or* the parent), so the rules get a home of their own: the widget
/// tests pin how the card branches, this pins what the branches mean.
void main() {
  group('isEthernet', () {
    test('firmware spelling is wired', () {
      expect(const BackhaulInfo(linkType: 'Ethernet').isEthernet, isTrue);
    });

    // Routed through `isMeshBackhaulEthernet` since #1555, so this and the other
    // three medium tests in the app fold case together. Before that all four
    // spelled the comparison by hand and would have misread the same alternative
    // spelling in the same direction at the same time.
    test('case and padding do not change the answer', () {
      for (final spelling in ['ethernet', 'ETHERNET', ' Ethernet ']) {
        expect(BackhaulInfo(linkType: spelling).isEthernet, isTrue,
            reason: '"$spelling" must read as wired');
      }
    });

    test('a wireless or absent medium is not wired', () {
      expect(const BackhaulInfo(linkType: 'Wi-Fi').isEthernet, isFalse);
      expect(const BackhaulInfo(linkType: '').isEthernet, isFalse);
      expect(BackhaulInfo.none.isEthernet, isFalse);
    });
  });

  group('isWifi', () {
    test('a named wireless medium is wireless', () {
      expect(const BackhaulInfo(linkType: 'Wi-Fi').isWifi, isTrue);
    });

    test('Ethernet is not wireless', () {
      expect(const BackhaulInfo(linkType: 'Ethernet').isWifi, isFalse);
      expect(const BackhaulInfo(linkType: 'ethernet').isWifi, isFalse);
    });

    // #1430: without the `hasInfo` guard `!isEthernet` reports *wireless* for a
    // node we hold no backhaul data for at all, and the card draws it a signal
    // indicator with no signal behind it.
    test('no backhaul at all is not wireless', () {
      expect(BackhaulInfo.none.isWifi, isFalse);
      expect(const BackhaulInfo(signalStrength: -60).isWifi, isFalse,
          reason:
              'a stray reading with neither medium nor parent is not a link');
    });

    // The state #1555 made representable end to end: a link whose medium
    // firmware never named. It is a link, and it is not Ethernet, so it is
    // graded as wireless — while `linkType` stays null so the interface row can
    // still say `unknown` instead of naming a medium nobody reported.
    test('a link with a parent but no medium is wireless of unknown medium',
        () {
      const link = BackhaulInfo(parentNodeId: 'AA:BB:CC:DD:EE:00');
      expect(link.isWifi, isTrue);
      expect(link.isEthernet, isFalse);
      expect(link.linkType, isNull);
    });
  });

  group('hasInfo', () {
    test('a medium alone is a link', () {
      expect(const BackhaulInfo(linkType: 'Wi-Fi').hasInfo, isTrue);
      expect(const BackhaulInfo(linkType: 'Ethernet').hasInfo, isTrue);
    });

    // The half #1555 added. Keying on the medium alone made a node with a known
    // parent and an empty `LinkType` read as having no backhaul — painted 0.0, a
    // dead link — while diagnostics graded the same node on its RSSI.
    test('a parent alone is a link', () {
      expect(const BackhaulInfo(parentNodeId: 'AA:BB:CC:DD:EE:00').hasInfo,
          isTrue);
    });

    test('neither is no link', () {
      expect(BackhaulInfo.none.hasInfo, isFalse);
      expect(
          const BackhaulInfo(linkType: '', parentNodeId: '').hasInfo, isFalse,
          reason:
              'an empty string is what an unset DataElements leaf reads as, '
              'not a value');
    });

    // Rates and a signal reading are not evidence of a link: they are what a
    // link *has*. A node whose stats arrived but whose identity fields did not is
    // still a node with no known backhaul.
    test('stats without a medium or parent are not a link', () {
      expect(
        const BackhaulInfo(
                signalStrength: -55, uplinkRate: 800, downlinkRate: 900)
            .hasInfo,
        isFalse,
      );
    });
  });

  // `BackhaulInfo.none` exists so the absent state reads as deliberate at each
  // site rather than as an empty constructor somebody forgot to fill in. If it
  // ever stops being the all-null value, every `hasInfo` guard above is reading a
  // different object than the builders write.
  test('BackhaulInfo.none is the all-absent value', () {
    expect(BackhaulInfo.none, const BackhaulInfo());
    expect(BackhaulInfo.none.props.every((p) => p == null), isTrue);
  });
}
