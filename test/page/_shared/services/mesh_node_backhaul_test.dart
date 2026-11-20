import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/_shared/services/mesh_node_backhaul.dart';

/// A [MeshNode] carrying only the two fields these helpers read.
///
/// Deliberately minimal. The point of the helpers under test is that
/// controller-vs-agent is decided by `LinkType` and `BackhaulDeviceID` and
/// nothing else — a builder that filled in the rest of the schema would hide a
/// helper that started consulting something it should not. That is also the one
/// reason this file would *not* simply adopt a shared `MeshNode` builder if one
/// existed: see `mesh_topology_builder_test.dart`'s `_node` for the promotion
/// trigger, and keep this file's fixture narrow whatever happens to the others.
MeshNode _node({
  String id = 'AA:BB:CC:DD:EE:01',
  String? linkType,
  String? parentDeviceId,
}) =>
    MeshNode(
      instancePath: 'Device.WiFi.DataElements.Network.Device.1.',
      id: id,
      backhaulLinkType: linkType,
      backhaulBackhaulDeviceId: parentDeviceId,
      radios: const [],
    );

void main() {
  // ---------------------------------------------------------------------------
  // hasMeshBackhaulLink — controller vs agent (#1555, AC2)
  // ---------------------------------------------------------------------------
  //
  // This is the discriminator that replaced `Device.{i}.BackhaulALID` /
  // `BackhaulMediaType` / `BackhaulPHYRate`, none of which FL-WRT 2.0 defines.
  // Both consumers — `MeshTopologyBuilder.build` and
  // `UnifiedDiagnosticsService` — call this function rather than re-deriving the
  // rule, and both of their test files pump the same table through the real
  // code path so the two cannot drift apart from this one.

  group('hasMeshBackhaulLink', () {
    test('a LinkType naming a medium is an agent', () {
      expect(hasMeshBackhaulLink(_node(linkType: 'Wi-Fi')), isTrue);
      expect(hasMeshBackhaulLink(_node(linkType: 'Ethernet')), isTrue);
    });

    // prplMesh reports `None` on the controller row — a positive statement of
    // "no backhaul", not a missing field.
    test('LinkType None is the controller', () {
      expect(hasMeshBackhaulLink(_node(linkType: 'None')), isFalse);
    });

    test('LinkType None is matched regardless of case', () {
      for (final spelling in ['None', 'none', 'NONE', 'nOnE']) {
        expect(hasMeshBackhaulLink(_node(linkType: spelling)), isFalse,
            reason: '"$spelling" must not read as a medium');
      }
    });

    test('an absent or blank LinkType is the controller', () {
      expect(hasMeshBackhaulLink(_node()), isFalse);
      expect(hasMeshBackhaulLink(_node(linkType: '')), isFalse);
      expect(hasMeshBackhaulLink(_node(linkType: '   ')), isFalse);
    });

    // A parent ID is positive evidence of a link, so it outranks a LinkType
    // that has not been filled in yet. Getting this backwards would strand a
    // connected agent as the controller and leave the topology with two roots.
    test('a parent ID wins over a LinkType that says nothing', () {
      expect(hasMeshBackhaulLink(_node(parentDeviceId: 'AA:BB:CC:DD:EE:01')),
          isTrue);
      expect(
          hasMeshBackhaulLink(
              _node(linkType: '', parentDeviceId: 'AA:BB:CC:DD:EE:01')),
          isTrue);
    });

    // And over one that says None, which is the ordering the doc comment
    // promises: field 1 is checked first and returns outright.
    test('a parent ID wins over LinkType None', () {
      expect(
          hasMeshBackhaulLink(
              _node(linkType: 'None', parentDeviceId: 'AA:BB:CC:DD:EE:01')),
          isTrue);
    });

    test('a blank parent ID is not evidence of a parent', () {
      expect(hasMeshBackhaulLink(_node(parentDeviceId: '')), isFalse);
      expect(hasMeshBackhaulLink(_node(parentDeviceId: '  ')), isFalse);
    });

    // The all-zero MAC is the same sentinel `isUnsetMac` was written for, on a
    // sibling field of the same `MultiAPDevice.Backhaul` object. Taken at face
    // value here it makes the *controller* an agent — the one node in the
    // topology that must not have a parent gets one nothing can resolve, and the
    // tree ends up with no root.
    test('the all-zero parent ID is not evidence of a parent', () {
      for (final spelling in [
        '00:00:00:00:00:00',
        '00-00-00-00-00-00',
        '000000000000',
        ' 00:00:00:00:00:00 ',
      ]) {
        expect(hasMeshBackhaulLink(_node(parentDeviceId: spelling)), isFalse,
            reason: 'unset parent written $spelling read as a real parent');
      }
    });

    // ...and it must not shadow the other field either: a node that reports the
    // sentinel parent *and* a medium is still an agent, decided by the medium.
    test('the all-zero parent ID leaves the LinkType to decide', () {
      expect(
          hasMeshBackhaulLink(
              _node(linkType: 'Wi-Fi', parentDeviceId: '00:00:00:00:00:00')),
          isTrue);
      expect(
          hasMeshBackhaulLink(
              _node(linkType: 'None', parentDeviceId: '00:00:00:00:00:00')),
          isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // meshControllerKey / isMeshController — the controller test (#1688 review)
  // ---------------------------------------------------------------------------
  //
  // `ControllerID` decides when it names a listed node; otherwise the backhaul
  // rule above does. `MeshTopologyBuilder`, `PnpService` and
  // `UnifiedDiagnosticsService` all call these, and each of their test files
  // pins an agent that has not filled in its backhaul yet through the real code
  // path, so none of the three can drift back to the backhaul rule alone.

  group('meshControllerKey / isMeshController', () {
    const controllerMac = '74:12:13:21:56:3A';
    final controller = _node(id: controllerMac, linkType: 'None');
    // Just joined: no LinkType and no parent yet, so by backhaul alone it is
    // indistinguishable from the controller.
    final joiningAgent = _node(id: 'AA:BB:CC:DD:EE:02');
    final network = DataElementsNetwork(items: [controller, joiningAgent]);

    test('with ControllerID only that node is the controller', () {
      final key = meshControllerKey(controllerMac, network);

      expect(isMeshController(controller, key), isTrue);
      expect(isMeshController(joiningAgent, key), isFalse,
          reason: 'an agent with no backhaul yet is still an agent');
    });

    test('without ControllerID the backhaul rule decides', () {
      final key = meshControllerKey(null, network);

      expect(key, isNull);
      expect(isMeshController(controller, key), isTrue);
      expect(isMeshController(joiningAgent, key), isTrue,
          reason: 'the fallback cannot tell a joining agent apart');
    });

    test('ControllerID matches regardless of MAC spelling', () {
      for (final spelling in [
        '74-12-13-21-56-3a',
        ' 74:12:13:21:56:3a ',
        '7412132156 3A',
      ]) {
        final key = meshControllerKey(spelling, network);
        expect(isMeshController(controller, key), isTrue,
            reason: '"$spelling" names the controller');
        expect(isMeshController(joiningAgent, key), isFalse);
      }
    });

    // A stale or foreign ControllerID must not demote the real controller: no
    // node would be the controller at all.
    test('a ControllerID naming no listed node gives no key', () {
      expect(meshControllerKey('11:22:33:44:55:66', network), isNull);
    });

    test('a blank or all-zero ControllerID gives no key', () {
      for (final id in ['', '  ', '00:00:00:00:00:00']) {
        expect(meshControllerKey(id, network), isNull, reason: '"$id"');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // meshBackhaulParentId — the parent MAC, or null (#1555)
  // ---------------------------------------------------------------------------
  //
  // One reader for the field the controller/agent discriminator keys on, so the
  // record a builder writes and the decision it made cannot disagree about
  // whether the node has a parent.

  group('meshBackhaulParentId', () {
    test('a real parent passes through trimmed', () {
      expect(meshBackhaulParentId(_node(parentDeviceId: ' AA:BB:CC:DD:EE:00 ')),
          'AA:BB:CC:DD:EE:00');
    });

    test('absent, blank and the all-zero sentinel are all null', () {
      expect(meshBackhaulParentId(_node()), isNull);
      expect(meshBackhaulParentId(_node(parentDeviceId: '')), isNull);
      expect(meshBackhaulParentId(_node(parentDeviceId: '  ')), isNull);
      expect(meshBackhaulParentId(_node(parentDeviceId: '00:00:00:00:00:00')),
          isNull);
    });

    // The invariant that made this a shared function rather than two readers:
    // "has a link" and "has a parent" are answered from the same value.
    test('a parent implies a link', () {
      for (final parent in [
        'AA:BB:CC:DD:EE:00',
        '00:00:00:00:00:00',
        '',
        null,
      ]) {
        final node = _node(parentDeviceId: parent);
        if (meshBackhaulParentId(node) != null) {
          expect(hasMeshBackhaulLink(node), isTrue,
              reason: '"$parent" yielded a parent but no link');
        }
      }
    });
  });

  // ---------------------------------------------------------------------------
  // meshBackhaulLinkType — the medium string, or null (#1555, AC2)
  // ---------------------------------------------------------------------------

  group('meshBackhaulLinkType', () {
    test('returns firmware spelling untouched', () {
      expect(meshBackhaulLinkType(_node(linkType: 'Wi-Fi')), 'Wi-Fi');
      expect(meshBackhaulLinkType(_node(linkType: 'Ethernet')), 'Ethernet');
    });

    test('trims surrounding whitespace', () {
      expect(meshBackhaulLinkType(_node(linkType: '  Ethernet ')), 'Ethernet');
    });

    // Callers treat null as "no medium to display". Returning the literal
    // 'None' instead would put that word in the backhaul card as if it were a
    // link technology.
    test('None collapses to null, in any case', () {
      for (final spelling in ['None', 'none', 'NONE']) {
        expect(meshBackhaulLinkType(_node(linkType: spelling)), isNull,
            reason: '"$spelling" is absence, not a medium');
      }
    });

    test('absent and blank collapse to null', () {
      expect(meshBackhaulLinkType(_node()), isNull);
      expect(meshBackhaulLinkType(_node(linkType: '')), isNull);
      expect(meshBackhaulLinkType(_node(linkType: '  ')), isNull);
    });

    // The two helpers are read together at every call site, so a state where
    // one says "there is a link" and the other says "there is no medium" would
    // be incoherent. It is reachable on purpose in exactly one direction: a
    // parent ID with no LinkType is a link whose medium is unknown.
    test('a medium implies a link', () {
      for (final linkType in ['Wi-Fi', 'Ethernet', 'None', '', '  ']) {
        final node = _node(linkType: linkType);
        if (meshBackhaulLinkType(node) != null) {
          expect(hasMeshBackhaulLink(node), isTrue,
              reason: '"$linkType" yielded a medium but no link');
        }
      }
    });
  });
}
