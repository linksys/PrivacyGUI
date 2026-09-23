import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/helpers/topology_slots.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The app's one spelling of ui_kit's slot vocabulary.
///
/// The kit takes the slot as a `String?` on purpose — one field names both a
/// built-in [NodeStyleSlot] and a key into a consumer's `extraNodeStyles`. That is
/// right for the library and wrong to scatter through a consumer, where the
/// vocabulary was spelled as a literal at 13 write sites and three read sites with
/// no compiler watching.
///
/// The constants matter because they are a **contract with the kit**: each must
/// still name a real `NodeStyleSlot`, or a node silently falls through to a derived
/// slot. That is the case a rename upstream would break and nothing else would
/// catch.
void main() {
  group('the constants name real kit slots', () {
    test('master, slave and device each resolve', () {
      // `parseNodeStyleSlot` returns null for a name the kit does not know, so a
      // non-null result is the assertion.
      expect(parseNodeStyleSlot(TopologySlots.master), NodeStyleSlot.primary);
      expect(parseNodeStyleSlot(TopologySlots.slave), NodeStyleSlot.secondary);
      expect(parseNodeStyleSlot(TopologySlots.device), NodeStyleSlot.leaf);
    });

    test('they are distinct', () {
      expect(
        {TopologySlots.master, TopologySlots.slave, TopologySlots.device},
        hasLength(3),
      );
    });
  });

  GraphNode node(String? slot) =>
      GraphNode(id: 'n', name: 'n', styleSlot: slot);

  group('what a reader gets back', () {
    test('a mesh node is a mesh node and not a device', () {
      for (final slot in [TopologySlots.master, TopologySlots.slave]) {
        expect(TopologySlots.isMeshNode(node(slot)), isTrue, reason: slot);
        expect(TopologySlots.isDevice(node(slot)), isFalse, reason: slot);
      }
    });

    test('a device is a device and not a mesh node', () {
      expect(TopologySlots.isDevice(node(TopologySlots.device)), isTrue);
      expect(TopologySlots.isMeshNode(node(TopologySlots.device)), isFalse);
    });

    test('an unassigned slot is neither', () {
      // The decision this class exists to hold once. Two readers used to answer it
      // differently: navigation gave such a node no page while the sort ranked it
      // among the devices. Refusing to call it a device is the half that matters,
      // because that is what would have given it a device's page.
      for (final unknown in [null, '', 'tertiary', 'typo', 'Leaf']) {
        expect(TopologySlots.isDevice(node(unknown)), isFalse,
            reason: '${unknown ?? "null"}');
        expect(TopologySlots.isMeshNode(node(unknown)), isFalse,
            reason: '${unknown ?? "null"}');
      }
    });

    test('a slot the kit authors but this app never assigns reads as unknown',
        () {
      // `tertiary` is a real kit slot, so `of` resolves it — but the app assigns
      // only three, and the two predicates must not quietly adopt a fourth.
      expect(TopologySlots.of(node('tertiary')), NodeStyleSlot.tertiary);
      expect(TopologySlots.isDevice(node('tertiary')), isFalse);
      expect(TopologySlots.isMeshNode(node('tertiary')), isFalse);
    });
  });
}
