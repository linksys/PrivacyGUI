import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';

/// The persisted shape of the dashboard layout (#1293).
///
/// Before this envelope existed the pref held a bare list of layout items with
/// no record of which grid they were measured on. `exportLayout()` always
/// returns coordinates in the controller's *current* slot count, so a save made
/// at mobile (4 columns) was read back as if it were desktop (12) — every card
/// came back a third of its width, with `minW`/`maxW` scaled down too, which is
/// permanent because those caps then block any attempt to widen the card again.
///
/// The envelope's whole job is to record the grid. Decoding is deliberately
/// forgiving of *unknown* content (a saved id we no longer ship is still a
/// layout we should honour) and deliberately strict about *unreadable* content:
/// anything it cannot place on a known grid decodes to null, and the caller
/// falls back to the default layout rather than importing garbage.
///
/// ## Mutation table — the #1299 addition, as #1400 left it
///
/// The version stamp arrived with #1299 and the picks with it, in a `forms` map
/// beside the layouts; #1400 moved each pick onto the item it describes and
/// deleted the map, leaving a one-time migration behind. The rest of this file is
/// #1293's. Every row edits `usp_layout_envelope.dart` or `card_form_choice.dart`
/// and was run against this file.
///
/// | # | mutation | killed by |
/// |---|---|---|
/// | 1 | `version` always returns `currentVersion` | encode stamps the version the payload actually needs |
/// | 2 | `version` always returns `versionWithoutForms` | the same test's shaping-pick half |
/// | 3 | `_hasFormBeyondNormal` drops the `!= normal` test (any pick counts) | a payload whose only picks are normal is still stamped v2 |
/// | 4 | `_hasFormBeyondNormal` walks the desktop layout only | one shaping pick raises the stamp for the whole payload |
/// | 5 | `encode` writes the picks in a sibling map as well | the payload holds nothing but version and layouts |
/// | 6 | `_foldLegacyPicks` returns null always (no migration) | every test in the v3 migration group |
/// | 7 | `_foldLegacyPicks` folds the picks but `migratedPicks` stays false | a migrated envelope says so, so the caller re-derives once |
/// | 8 | `_foldLegacyPicks` ignores the slot count and folds every grid's picks onto every grid | a v3 pick lands on the grid it was filed under |
/// | 9 | `props` includes `migratedPicks` | a migrated envelope still equals what its own bytes decode to |
/// | 10 | `mapLayouts` and `withLayout` rebuild without `migratedPicks` | 2 — the copier tests; +1 in `usp_card_form_persistence_test.dart`, where the migration then re-runs on every boot |
/// | 11 | `_hasFormBeyondNormal` casts with `item as Map` instead of testing `item is Map` | *survivor, and left alive on purpose* — no caller can construct an envelope holding a non-map item today, since `tryDecode` validates through `_isItemList` and `_exportAllBreakpoints` gets its items from the grid. The guard is there because this getter runs on the encode path, where `_writeLayout` logs and swallows a throw: the failure it prevents is silent, and one bad entry would stop the dashboard saving for the rest of the session. A test would have to build an envelope no production path can. |
void main() {
  /// An item carrying [pick] the way the production writer does.
  ///
  /// Through [CardFormChoice.writeInto] rather than a hand-built `extra` map, so
  /// these fixtures cannot drift from the key the app actually writes — the whole
  /// claim of #1400 is that there is one place a pick is stored.
  Map<String, dynamic> item(
    String id, {
    int w = 6,
    int h = 3,
    CardFormChoice? pick,
  }) =>
      {
        'id': id,
        'x': 0,
        'y': 0,
        'w': w,
        'h': h,
        if (pick != null) 'extra': pick.writeInto(null),
      };

  group('decode', () {
    test('a legacy bare list is migrated as the desktop entry', () {
      // The only shape that existed before #1293. It was always written by a
      // 12-column controller at load time, so desktop is the honest reading.
      final legacy = jsonEncode([
        {'id': 'stats_panel', 'x': 0, 'y': 0, 'w': 12, 'h': 1},
        {'id': 'device_info', 'x': 0, 'y': 1, 'w': 6, 'h': 3},
      ]);

      final envelope = UspLayoutEnvelope.tryDecode(legacy);

      expect(envelope, isNotNull);
      expect(envelope!.slotCounts, [UspLayoutEnvelope.desktopSlotCount]);
      expect(envelope[UspLayoutEnvelope.desktopSlotCount], hasLength(2));
      expect(envelope[UspLayoutEnvelope.mobileSlotCount], isNull,
          reason: 'A legacy value says nothing about the mobile grid; the '
              'caller must derive it, not inherit a wrong one.');
    });

    test('an empty legacy list stays an empty desktop layout', () {
      // Not the same as unreadable: a user who deleted every card gets an empty
      // dashboard, which is what the pre-#1293 code did too.
      final envelope = UspLayoutEnvelope.tryDecode('[]');

      expect(envelope, isNotNull);
      expect(envelope![UspLayoutEnvelope.desktopSlotCount], isEmpty);
    });

    test('a v2 envelope round-trips every breakpoint independently', () {
      final original = UspLayoutEnvelope({
        12: [
          {'id': 'device_info', 'x': 0, 'y': 0, 'w': 6, 'h': 3}
        ],
        8: [
          {'id': 'device_info', 'x': 0, 'y': 0, 'w': 4, 'h': 3}
        ],
        4: [
          {'id': 'device_info', 'x': 0, 'y': 0, 'w': 4, 'h': 5}
        ],
      });

      final decoded = UspLayoutEnvelope.tryDecode(original.encode());

      expect(decoded, isNotNull);
      expect(decoded!.slotCounts, [12, 8, 4]);
      // The point of the whole ticket: a height set at mobile does not follow
      // the card to desktop, and a width set at desktop does not follow it down.
      expect((decoded[12]!.single as Map)['w'], 6);
      expect((decoded[4]!.single as Map)['w'], 4);
      expect((decoded[4]!.single as Map)['h'], 5);
      expect((decoded[12]!.single as Map)['h'], 3);
    });

    test('encode stamps the version the payload actually needs', () {
      final withoutPicks =
          jsonDecode(UspLayoutEnvelope(const {12: []}).encode())
              as Map<String, dynamic>;

      expect(withoutPicks['version'], UspLayoutEnvelope.versionWithoutForms,
          reason: 'What v3 and v4 both added is the geometry a shaping pick '
              'writes, so an install that never used the form control is still '
              'writing a v2 payload. Stamping it v4 would make a rollback to a '
              'pre-#1299 build reject it and reset a dashboard the user '
              'arranged, for a feature they never touched.');
      expect(withoutPicks['layouts'], isA<Map>());

      for (final shaping in [CardDensity.popup, CardDensity.compact]) {
        final withPicks = jsonDecode(UspLayoutEnvelope({
          12: [item('device_info', pick: CardFormChoice(density: shaping))],
        }).encode()) as Map<String, dynamic>;

        expect(withPicks['version'], UspLayoutEnvelope.currentVersion,
            reason: 'The first ${shaping.name} pick is when an older build '
                'would start drawing a card with no handles, or a floor it has '
                'no rule for.');
      }
    });

    test('the payload holds nothing but version and layouts', () {
      // #1400's shape claim, and the reason the migration below is one-way: a
      // pick is a field of the item it shaped, so a second top-level key holding
      // picks would be the store this ticket deleted, re-created.
      final json = jsonDecode(UspLayoutEnvelope({
        12: [
          item('device_info',
              pick: const CardFormChoice(density: CardDensity.popup)),
        ],
      }).encode()) as Map<String, dynamic>;

      expect(json.keys, unorderedEquals(['version', 'layouts']));
    });

    test('a payload whose only picks are normal is still stamped v2', () {
      // Returning a card to normal is how the user *undoes* a form, and the
      // geometry it writes is the spec's own bounds — bytes a pre-#1299 build
      // reads correctly. Keying the stamp on "are there picks at all" pinned the
      // payload at v3 for the rest of the install's life the moment anyone tried
      // popup once, so the users most likely to want a rollback — the ones who
      // tried the control and changed their mind — were the ones it stopped
      // protecting.
      final envelope = UspLayoutEnvelope({
        12: [
          item('device_info',
              pick: const CardFormChoice(density: CardDensity.normal)),
        ],
      });

      final json = jsonDecode(envelope.encode()) as Map<String, dynamic>;

      expect(json['version'], UspLayoutEnvelope.versionWithoutForms,
          reason: 'An explicit normal writes the spec bounds back and turns '
              '`isResizable` on, which is exactly what a build with no '
              'card-form rule writes for itself.');

      // The pick is still written, and still comes back. A v2 build ignores an
      // `extra` key it has no field for; this one needs it, or an explicit normal
      // would stop out-ranking the width-derived form on the next load.
      final decoded = UspLayoutEnvelope.tryDecode(envelope.encode());
      expect(
          CardFormChoice.readFrom((decoded![12]!.single as Map)['extra'])
              ?.density,
          CardDensity.normal,
          reason: 'Stamping v2 is a claim about how an older build reads these '
              'bytes, not a reason to drop what this build still honours.');
    });

    test('one shaping pick raises the stamp for the whole payload', () {
      // The stamp describes the bytes, not one card: a v2 build reading this
      // would render the popup tile with no handles regardless of how many
      // normal picks sit beside it.
      // And it is the *whole* payload, not the desktop grid: the popup pick here
      // is on the phone's copy of the card, which is where a phone-only pick
      // lives now that the picks travel on the items (#1400).
      final envelope = UspLayoutEnvelope({
        12: [
          item('device_info',
              pick: const CardFormChoice(density: CardDensity.normal)),
          item('lan_info'),
        ],
        4: [
          item('device_info', w: 4),
          item('lan_info',
              w: 4, pick: const CardFormChoice(density: CardDensity.popup)),
        ],
      });

      expect(jsonDecode(envelope.encode())['version'],
          UspLayoutEnvelope.currentVersion);
    });

    test('slot counts survive as ints even though JSON keys are strings', () {
      final decoded = UspLayoutEnvelope.tryDecode(jsonEncode({
        'version': 2,
        'layouts': {
          '4': [
            {'id': 'device_info', 'x': 0, 'y': 0, 'w': 4, 'h': 3}
          ],
        },
      }));

      expect(decoded![4], hasLength(1));
    });

    test('unknown slot counts are kept, not dropped', () {
      // A future ui_kit breakpoint (or a 6-column tablet regime) must not lose
      // the user's layout just because this build doesn't render it.
      final decoded = UspLayoutEnvelope.tryDecode(jsonEncode({
        'version': 2,
        'layouts': {
          '12': [],
          '6': [
            {'id': 'device_info', 'x': 0, 'y': 0, 'w': 3, 'h': 3}
          ],
        },
      }));

      expect(decoded![6], hasLength(1));
    });

    group('unreadable payloads decode to null', () {
      final cases = <String, String>{
        'not JSON at all': 'not json',
        'a bare string': '"nope"',
        'a number': '42',
        'an object with no layouts': jsonEncode({'version': 2}),
        'layouts that is not a map': jsonEncode({'version': 2, 'layouts': []}),
        'a slot count that is not a number': jsonEncode({
          'version': 2,
          'layouts': {'desktop': []},
        }),
        'a layout that is not a list': jsonEncode({
          'version': 2,
          'layouts': {'12': {}},
        }),
        'a layout item that is not a map': jsonEncode({
          'version': 2,
          'layouts': {
            '12': ['device_info'],
          },
        }),
        'a future version': jsonEncode({
          'version': UspLayoutEnvelope.currentVersion + 1,
          'layouts': {'12': []},
        }),
      };

      cases.forEach((name, raw) {
        test(name, () {
          expect(UspLayoutEnvelope.tryDecode(raw), isNull,
              reason: 'Importing this would be worse than resetting: the grid '
                  'either throws on import or renders a layout the user never '
                  'made. Returning null lets the caller re-seed the default.');
        });
      });
    });
  });

  group('withLayout', () {
    test('replaces one breakpoint and leaves the others alone', () {
      final envelope = UspLayoutEnvelope({
        12: [
          {'id': 'a', 'x': 0, 'y': 0, 'w': 6, 'h': 3}
        ],
        4: [
          {'id': 'a', 'x': 0, 'y': 0, 'w': 4, 'h': 3}
        ],
      });

      final updated = envelope.withLayout(4, [
        {'id': 'a', 'x': 0, 'y': 0, 'w': 4, 'h': 6}
      ]);

      expect((updated[4]!.single as Map)['h'], 6);
      expect((updated[12]!.single as Map)['h'], 3);
      expect(envelope[4]!.single, containsPair('h', 3),
          reason: 'withLayout must not mutate the receiver.');
    });
  });

  group('the copiers carry where the layouts came from', () {
    // Both copiers rebuild the envelope from a fresh map, so `migratedPicks` has
    // to be passed along by hand. It matters most for `mapLayouts`, whose only
    // caller *is* the migration: the flag is what buys the one re-save that
    // retires the v3 payload, and an envelope that dropped it would leave that
    // answer readable only off the object the transform was applied to.
    final migrated = UspLayoutEnvelope.tryDecode(jsonEncode({
      'version': 3,
      'layouts': {
        '12': [
          {'id': 'device_info', 'x': 0, 'y': 0, 'w': 6, 'h': 3},
        ],
      },
      'forms': {
        '12': {
          'device_info': {'density': 'popup'}
        }
      },
    }))!;

    test('mapLayouts keeps migratedPicks', () {
      expect(migrated.migratedPicks, isTrue);
      expect(
          migrated.mapLayouts((slots, layout) => layout).migratedPicks, isTrue,
          reason: 'Re-deriving the geometry a folded pick implies is exactly '
              'what the flag asks the caller to do, so the result of doing it '
              'cannot be the object that denies it happened.');
    });

    test('withLayout keeps migratedPicks', () {
      expect(migrated.withLayout(8, const []).migratedPicks, isTrue);
    });
  });

  group('value equality', () {
    UspLayoutEnvelope build({int h = 3, CardFormChoice? pick}) =>
        UspLayoutEnvelope({
          12: [item('a', h: h, pick: pick)],
          4: [item('a', w: 4, h: h, pick: pick)],
        });

    // Asserted rather than assumed: `props` hands Equatable a Map of Lists of
    // Maps, none of which compares by value on its own. If Equatable compared
    // those by identity, two separately built envelopes would already differ and
    // the equality would be worthless for the round-trip assertion below.
    test('two separately built envelopes with the same content are equal', () {
      expect(build(), build());
      expect(build().hashCode, build().hashCode);
    });

    test('an encode/decode round-trip returns an equal envelope', () {
      final original = build(
        pick: const CardFormChoice(density: CardDensity.compact, restoreW: 6),
      );

      // The whole point of the equality: one assertion covers every persisted
      // field, so a field added later cannot be silently left out of the
      // round-trip claim the way a per-getter walk would leave it out.
      expect(UspLayoutEnvelope.tryDecode(original.encode()), original);
    });

    test('a difference in the nested geometry is a difference', () {
      expect(build(h: 3), isNot(build(h: 6)));
    });

    test('a difference in a pick alone is a difference', () {
      // The pick is nested two collections deep now — a map inside an item inside
      // a per-slot-count list — so this is also what says Equatable is comparing
      // `extra` at all rather than stopping at the item's own keys.
      expect(
        build(),
        isNot(build(
          pick: const CardFormChoice(density: CardDensity.compact, restoreW: 6),
        )),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // #1400 AC 2 — the one-time migration off the (slotCount, cardId) map
  // ---------------------------------------------------------------------------
  //
  // A v3 install kept its picks in a `forms` map beside the layouts, keyed by slot
  // count and then by card id. Reading that payload with the map ignored would
  // silently undo every pick the user had made — the geometry stored alongside it
  // was re-derived from the map on every import, so the bytes alone do not carry
  // the form either. Decoding therefore folds the map onto the items it describes
  // and says so, and the caller re-derives the geometry once and re-saves; from
  // then on it is an ordinary v4 payload.
  //
  // The migration lives here, in pure JSON, rather than in the controller that
  // triggers it: `usp_layout_envelope.dart` cannot import `usp_widget_specs.dart`
  // without a cycle, and the fold needs neither — moving a value from one place in
  // a map to another is not a geometry question.
  group('v3 picks are folded onto their items on decode (#1400)', () {
    /// A v3 payload: layouts, plus the sibling `forms` map that used to name the
    /// picks.
    String v3({
      required Map<String, List<Map<String, dynamic>>> layouts,
      required Map<String, Map<String, dynamic>> forms,
    }) =>
        jsonEncode({'version': 3, 'layouts': layouts, 'forms': forms});

    CardFormChoice? pickOn(UspLayoutEnvelope? envelope, int slots, String id) {
      for (final entry in envelope?[slots] ?? const []) {
        if ((entry as Map)['id'] == id) {
          return CardFormChoice.readFrom(entry['extra']);
        }
      }
      return null;
    }

    test('the pick lands on the item, and the envelope says it moved', () {
      final decoded = UspLayoutEnvelope.tryDecode(v3(
        layouts: {
          '12': [
            {'id': 'device_info', 'x': 0, 'y': 0, 'w': 2, 'h': 1},
            {'id': 'lan_info', 'x': 2, 'y': 0, 'w': 6, 'h': 3},
          ],
        },
        forms: {
          '12': {
            'device_info': {'density': 'popup', 'restoreW': 6, 'restoreH': 3},
          },
        },
      ));

      final pick = pickOn(decoded, 12, 'device_info');
      expect(pick?.density, CardDensity.popup);
      expect(pick?.restoreW, 6,
          reason:
              'The box to give back when the popup is expanded again is the '
              'part of a pick that cannot be re-derived from anything. Losing it '
              'in the migration would leave the card stuck as a 2x1 tile.');
      expect(pickOn(decoded, 12, 'lan_info'), isNull,
          reason: 'A card the map does not name keeps no pick.');

      expect(decoded!.migratedPicks, isTrue,
          reason:
              'The caller re-derives the geometry once and re-saves off the '
              'back of this flag — see UspSliverDashboardControllerNotifier. '
              'Without it the migration would be free and wrong: v3 stored '
              'geometry that was recomputed on every import, so it is not what '
              'the writing build rendered either.');
    });

    test('a pick lands on the grid it was filed under', () {
      // Picks were per breakpoint in v3 and still are (#1294): the phone's popup
      // must not follow the card to the desktop grid and collapse it there.
      final decoded = UspLayoutEnvelope.tryDecode(v3(
        layouts: {
          '12': [
            {'id': 'device_info', 'x': 0, 'y': 0, 'w': 6, 'h': 3},
          ],
          '4': [
            {'id': 'device_info', 'x': 0, 'y': 0, 'w': 4, 'h': 1},
          ],
        },
        forms: {
          '4': {
            'device_info': {'density': 'popup'},
          },
        },
      ));

      expect(pickOn(decoded, 4, 'device_info')?.density, CardDensity.popup);
      expect(pickOn(decoded, 12, 'device_info'), isNull);
    });

    test('re-encoding a migrated envelope drops the map and stamps v4', () {
      final decoded = UspLayoutEnvelope.tryDecode(v3(
        layouts: {
          '12': [
            {'id': 'device_info', 'x': 0, 'y': 0, 'w': 2, 'h': 1},
          ],
        },
        forms: {
          '12': {
            'device_info': {'density': 'popup'},
          },
        },
      ));

      final json = jsonDecode(decoded!.encode()) as Map<String, dynamic>;

      expect(json.keys, unorderedEquals(['version', 'layouts']),
          reason: 'The next save is what makes the migration one-time.');
      expect(json['version'], UspLayoutEnvelope.currentVersion);
      expect(
          pickOn(UspLayoutEnvelope.tryDecode(decoded.encode()), 12,
                  'device_info')
              ?.density,
          CardDensity.popup);
    });

    test('a migrated envelope still equals what its own bytes decode to', () {
      // `migratedPicks` is outside `props` for this: it describes where the
      // layouts came from, `encode` does not write it, and the round-trip
      // assertion is the one thing the value equality exists for here.
      final migrated = UspLayoutEnvelope.tryDecode(v3(
        layouts: {
          '12': [
            {'id': 'device_info', 'x': 0, 'y': 0, 'w': 2, 'h': 1},
          ],
        },
        forms: {
          '12': {
            'device_info': {'density': 'popup'},
          },
        },
      ))!;

      expect(UspLayoutEnvelope.tryDecode(migrated.encode()), migrated);
      expect(UspLayoutEnvelope.tryDecode(migrated.encode())!.migratedPicks,
          isFalse,
          reason: 'The re-saved payload has no map left to move, so the next '
              'boot is an ordinary one.');
    });

    test('a v4 payload reports no migration', () {
      final decoded = UspLayoutEnvelope.tryDecode(UspLayoutEnvelope({
        12: [
          item('device_info',
              pick: const CardFormChoice(density: CardDensity.popup)),
        ],
      }).encode());

      expect(decoded!.migratedPicks, isFalse);
      expect(pickOn(decoded, 12, 'device_info')?.density, CardDensity.popup);
    });

    for (final (name, forms) in [
      ('a `forms` key that is not a map', 'nope'),
      ('an empty `forms` map', <String, dynamic>{}),
      (
        'picks filed under a grid this payload has no layout for',
        {
          '8': {
            'device_info': {'density': 'popup'},
          },
        }
      ),
      (
        'picks naming a card this payload does not hold',
        {
          '12': {
            'time_settings': {'density': 'popup'},
          },
        }
      ),
      (
        'a pick whose density is not one we ship',
        {
          '12': {
            'device_info': {'density': 'tiny'},
          },
        }
      ),
    ]) {
      test('$name is nothing to migrate', () {
        // Nothing to move is not a failure: there is no item to write the pick
        // onto, and the alternative to dropping it is keeping the sibling map
        // #1400 exists to delete. What matters is that the payload still decodes
        // and reports no migration, so the caller does not re-derive and re-save
        // for nothing on every boot.
        final decoded = UspLayoutEnvelope.tryDecode(jsonEncode({
          'version': 3,
          'layouts': {
            '12': [
              {'id': 'device_info', 'x': 0, 'y': 0, 'w': 6, 'h': 3},
            ],
          },
          'forms': forms,
        }));

        expect(decoded, isNotNull);
        expect(decoded!.migratedPicks, isFalse);
        expect(pickOn(decoded, 12, 'device_info'), isNull);
      });
    }
  });
}
