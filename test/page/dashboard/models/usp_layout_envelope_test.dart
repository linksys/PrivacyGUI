import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/card_form_choice.dart';
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
/// ## Mutation table — the #1299 addition
///
/// `forms` and the version stamp arrived with #1299; the rest of this file is
/// #1293's. Every row edits `usp_layout_envelope.dart` or `card_form_choice.dart`
/// and was run against this file.
///
/// | # | mutation | killed by |
/// |---|---|---|
/// | 1 | `version` always returns `currentVersion` | encode stamps the version the payload actually needs |
/// | 2 | `version` always returns `versionWithoutForms` | the same test's shaping-pick half |
/// | 3 | `version` keys on `forms.isEmpty` instead of `hasFormBeyondNormal` | an explicit normal is not a shaping pick |
/// | 4 | `hasFormBeyondNormal` drops the `!= normal` test (any pick counts) | the same test |
/// | 5 | `encode` keys the `forms` key on `hasFormBeyondNormal` too | an explicit normal survives a round-trip |
void main() {
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
          reason: 'What v3 added is the geometry a shaping pick writes, so an '
              'install that never used the form control is still writing a v2 '
              'payload. Stamping it v3 would make a rollback to a pre-#1299 '
              'build reject it and reset a dashboard the user arranged, for a '
              'feature they never touched.');
      expect(withoutPicks['layouts'], isA<Map>());
      expect(withoutPicks.containsKey('forms'), isFalse);

      for (final shaping in [CardDensity.popup, CardDensity.compact]) {
        final withPicks = jsonDecode(UspLayoutEnvelope(
          const {12: []},
          forms: CardForms({
            12: {'device_info': CardFormChoice(density: shaping)},
          }),
        ).encode()) as Map<String, dynamic>;

        expect(withPicks['version'], UspLayoutEnvelope.currentVersion,
            reason: 'The first ${shaping.name} pick is when an older build '
                'would start drawing a card with no handles, or a floor it has '
                'no rule for.');
      }
    });

    test('a payload whose only picks are normal is still stamped v2', () {
      // Returning a card to normal is how the user *undoes* a form, and the
      // geometry it writes is the spec's own bounds — bytes a pre-#1299 build
      // reads correctly. Keying the stamp on "are there picks at all" pinned the
      // payload at v3 for the rest of the install's life the moment anyone tried
      // popup once, so the users most likely to want a rollback — the ones who
      // tried the control and changed their mind — were the ones it stopped
      // protecting.
      final envelope = UspLayoutEnvelope(
        const {
          12: [
            {'id': 'device_info', 'x': 0, 'y': 0, 'w': 6, 'h': 3}
          ]
        },
        forms: const CardForms({
          12: {'device_info': CardFormChoice(density: CardDensity.normal)},
        }),
      );

      final json = jsonDecode(envelope.encode()) as Map<String, dynamic>;

      expect(json['version'], UspLayoutEnvelope.versionWithoutForms,
          reason: 'An explicit normal writes the spec bounds back and turns '
              '`isResizable` on, which is exactly what a build with no '
              'card-form rule writes for itself.');

      // The pick is still written, and still comes back. A v2 build ignores the
      // key; this one needs it, or an explicit normal would stop out-ranking the
      // width-derived form on the next load.
      expect(json.containsKey('forms'), isTrue,
          reason: 'Stamping v2 is a claim about how an older build reads these '
              'bytes, not a reason to drop what this build still honours.');

      final decoded = UspLayoutEnvelope.tryDecode(envelope.encode());
      expect(decoded?.forms.densityFor(12, 'device_info'), CardDensity.normal);
    });

    test('one shaping pick raises the stamp for the whole payload', () {
      // The stamp describes the bytes, not one card: a v2 build reading this
      // would render the popup tile with no handles regardless of how many
      // normal picks sit beside it.
      final envelope = UspLayoutEnvelope(
        const {12: []},
        forms: const CardForms({
          12: {
            'device_info': CardFormChoice(density: CardDensity.normal),
            'lan_info': CardFormChoice(density: CardDensity.popup),
          },
          4: {'time_settings': CardFormChoice(density: CardDensity.normal)},
        }),
      );

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
}
