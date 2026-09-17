import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_backhaul_link.dart';

/// A [MeshNode] carrying only the two fields these helpers read.
///
/// Deliberately minimal. The point of the helpers under test is that
/// controller-vs-agent is decided by `LinkType` and `BackhaulDeviceID` and
/// nothing else — a builder that filled in the rest of the schema would hide a
/// helper that started consulting something it should not. That is also the one
/// reason this file would *not* simply adopt a shared `MeshNode` builder if one
/// existed: see `mesh_topology_builder_test.dart`'s `_node` for the promotion
/// trigger, and keep this file's fixture narrow whatever happens to the others.
MeshNode _node({String? linkType, String? parentDeviceId}) => MeshNode(
      instancePath: 'Device.WiFi.DataElements.Network.Device.1.',
      id: 'AA:BB:CC:DD:EE:01',
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
  // isMeshBackhaulEthernet — the single medium test (#1555)
  // ---------------------------------------------------------------------------
  //
  // Four sites spelled this `linkType == 'Ethernet'` by hand
  // (`BackhaulInfo.isEthernet`, `MeshNodeBackhaulUIModel.isWired`,
  // `UnifiedDiagnosticsService`'s `wired`, `node_detail_popup`). All four would
  // have misread the same alternative spelling in the same direction at the same
  // moment — a wired node graded on an RSSI it does not have.

  group('isMeshBackhaulEthernet', () {
    test('firmware spelling is wired', () {
      expect(isMeshBackhaulEthernet('Ethernet'), isTrue);
    });

    test('case and padding do not change the answer', () {
      for (final spelling in [
        'ethernet',
        'ETHERNET',
        'EtHeRnEt',
        '  Ethernet ',
        '\tethernet\n',
      ]) {
        expect(isMeshBackhaulEthernet(spelling), isTrue,
            reason: '"$spelling" must read as wired');
      }
    });

    test('every other medium, and absence, is not wired', () {
      for (final spelling in [
        'Wi-Fi',
        'WiFi',
        'None',
        '',
        '   ',
        null,
        // Not a prefix match: a longer value containing the word is a different
        // medium, not this one.
        'Ethernet over Coax',
      ]) {
        expect(isMeshBackhaulEthernet(spelling), isFalse,
            reason: '"$spelling" must not read as wired');
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

  // ---------------------------------------------------------------------------
  // nonEpoch — the unset-timestamp sentinel (#1555, AC6)
  // ---------------------------------------------------------------------------
  //
  // `MultiAPDevice.LastContactTime` and `Backhaul.Stats.TimeStamp` read the
  // epoch on a node that has never reported. `DateTime.tryParse` succeeds on
  // it, so without this guard "never contacted" reaches the UI as "last seen 56
  // years ago" — a confident wrong answer rather than a blank.

  group('nonEpoch', () {
    test('a real timestamp passes through unchanged', () {
      final real = DateTime.parse('2026-05-18T10:00:00Z');
      expect(nonEpoch(real), real);
    });

    test('null stays null', () {
      expect(nonEpoch(null), isNull);
    });

    test('the measured sentinel is null', () {
      // Verbatim what the bench read off a node with no collected stats.
      expect(nonEpoch(DateTime.parse('1970-01-01T00:00:00Z')), isNull);
    });

    // The generated parser hands `DateTime.tryParse` firmware's string as-is,
    // so a sentinel without a trailing `Z` becomes a *local* DateTime — hours
    // away from the epoch instant, and in 1969 for positive UTC offsets. An
    // exact-equality guard catches the `Z` spelling and lets this one through.
    test('the sentinel without a timezone is null too', () {
      expect(nonEpoch(DateTime.parse('1970-01-01T00:00:00')), isNull);
      expect(nonEpoch(DateTime(1970)), isNull);
    });

    test('every timezone spelling of the sentinel is null', () {
      for (final offset in ['+14:00', '+08:00', 'Z', '-05:00', '-12:00']) {
        final stamp = DateTime.parse('1970-01-01T00:00:00$offset');
        expect(nonEpoch(stamp), isNull,
            reason: 'the sentinel at UTC$offset parses to '
                '${stamp.toUtc().toIso8601String()} and must still read as '
                'absence');
      }
    });

    // The slack is a day, not a year. A timestamp far enough from the epoch to
    // be a real reading must survive, or the guard starts eating data.
    test('a date near but outside the sentinel window survives', () {
      final justOutside = DateTime.parse('1970-01-03T00:00:00Z');
      expect(nonEpoch(justOutside), justOutside);
      final y2k = DateTime.parse('2000-01-01T00:00:00Z');
      expect(nonEpoch(y2k), y2k);
    });
  });

  // ---------------------------------------------------------------------------
  // nonEmpty — the empty-string sentinel (#1555)
  // ---------------------------------------------------------------------------
  //
  // Promoted out of two byte-identical private copies (one in
  // `MeshTopologyBuilder`, one in `UnifiedDiagnosticsService`) that this ticket
  // had itself just written. Both read `BackhaulDeviceID`, so a divergence
  // between them would be the exact class of bug this ticket is fixing: the two
  // graders disagreeing about whether a node has a parent.

  group('nonEmpty', () {
    test('a value passes through trimmed', () {
      expect(nonEmpty('MR7500'), 'MR7500');
      expect(nonEmpty('  AA:BB:CC:DD:EE:01 '), 'AA:BB:CC:DD:EE:01');
    });

    test('absent, empty and whitespace are all null', () {
      // The middle one is what a DataElements string leaf reads when firmware
      // has never set it — not a missing key, which is why `??` on the raw
      // value is not enough.
      expect(nonEmpty(null), isNull);
      expect(nonEmpty(''), isNull);
      expect(nonEmpty('   '), isNull);
      expect(nonEmpty('\t\n'), isNull);
    });

    test('a value that is only partly blank keeps its middle', () {
      expect(nonEmpty(' Qualcomm Technologies, Inc. IP '),
          'Qualcomm Technologies, Inc. IP');
    });
  });

  // ---------------------------------------------------------------------------
  // isUnsetMac — the all-zero backhaul-station sentinel (#1555)
  // ---------------------------------------------------------------------------
  //
  // Two call sites read `Radio.{i}.BackhaulSta.MACAddress` and both have to
  // reject the same value: `MeshTopologyBuilder._backhaulStaMac` would otherwise
  // pick it as a node's station MAC, and `UspInstantPrivacyService`
  // `meshBackhaulMacs` would write it into the allow-list. They held the check
  // as two private constants until this function replaced them, and they hold the
  // MAC in different spellings — hence the spelling table below.

  group('isUnsetMac', () {
    test('the measured sentinel is unset in every spelling', () {
      for (final spelling in [
        '00:00:00:00:00:00', // as firmware writes it, and as `normalizeMac`
        // (instant_privacy_service) renders it
        '00-00-00-00-00-00', // the dash spelling that helper folds away
        '000000000000', // as `node_identifier.normalizeMac` renders it
        ' 00:00:00:00:00:00 ',
      ]) {
        expect(isUnsetMac(spelling), isTrue, reason: 'unset written $spelling');
      }
    });

    test('a real address is not unset', () {
      expect(isUnsetMac('AA:BB:CC:DD:EE:01'), isFalse);
      // The one that would slip past a "contains only zeros after stripping"
      // reading of the rule if it were written carelessly: a genuine address
      // with plenty of zeros in it.
      expect(isUnsetMac('00:00:00:00:00:01'), isFalse);
      expect(isUnsetMac('01:00:00:00:00:00'), isFalse);
    });

    test('absence is not the sentinel', () {
      // Different state, and both callers test for it separately: an empty field
      // means firmware said nothing, the all-zero MAC means it said "no station".
      expect(isUnsetMac(null), isFalse);
      expect(isUnsetMac(''), isFalse);
      expect(isUnsetMac('   '), isFalse);
      expect(isUnsetMac('::::'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // nonUnsetMac — both MAC absences at once (#1555)
  // ---------------------------------------------------------------------------
  //
  // [nonEmpty] and [isUnsetMac] composed. Three sites read a MAC off this
  // subtree — the parent device ID, the parent BSSID, the bSTA MAC — and each had
  // its own hand-rolled pair of checks, in different orders. Consumers do not
  // care which kind of absence they got, only that they got one.

  group('nonUnsetMac', () {
    test('a real address passes through trimmed', () {
      expect(nonUnsetMac('AA:BB:CC:DD:EE:01'), 'AA:BB:CC:DD:EE:01');
      expect(nonUnsetMac(' AA:BB:CC:DD:EE:01 '), 'AA:BB:CC:DD:EE:01');
      // A genuine address that is mostly zeros still survives.
      expect(nonUnsetMac('00:00:00:00:00:01'), '00:00:00:00:00:01');
    });

    test('both kinds of absence collapse to null', () {
      expect(nonUnsetMac(null), isNull);
      expect(nonUnsetMac(''), isNull);
      expect(nonUnsetMac('   '), isNull);
      expect(nonUnsetMac('00:00:00:00:00:00'), isNull);
      expect(nonUnsetMac('000000000000'), isNull);
      expect(nonUnsetMac(' 00-00-00-00-00-00 '), isNull);
    });

    // The two halves answer differently about whitespace — `isUnsetMac('  ')` is
    // false, because whitespace is absence rather than the sentinel — and this
    // function has to return null for it either way. That is the whole reason
    // callers get one helper instead of two checks to remember the polarity of.
    test('whitespace is absence, whichever half catches it', () {
      expect(nonUnsetMac('\t\n'), isNull);
      expect(isUnsetMac('\t\n'), isFalse);
    });
  });
}
