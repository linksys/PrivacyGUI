import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/helpers/card_identifier.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

/// Unit coverage for the key both card hooks are built from — the detail-entry
/// button's and the popup tile's (#1450) — required of a per-instance identifier
/// key by constitution Article XVI §16.3.
///
/// The composition itself is not here, and deliberately: the prefix is spelled
/// inline at each attribute site because that is the only shape the E2E generator
/// harvests (see the library header). So the contract splits three ways and each
/// half has the test that can see it:
///
///   * the transform and the shape it produces — here;
///   * that `lib/` spells the prefixes in a harvestable form —
///     `card_identifier_harvest_test.dart`;
///   * which card publishes which hook, and where the node sits —
///     `test/page/dashboard/cards/dashboard_card_identifier_widget_test.dart`.
void main() {
  group('cardIdentifierKey', () {
    test('turns a registry id into its kebab key', () {
      expect(cardIdentifierKey('wifi_status'), 'wifi-status');
      expect(cardIdentifierKey('topology'), 'topology');
      expect(cardIdentifierKey('dhcp_reservations'), 'dhcp-reservations');
    });

    test('replaces every underscore, not just the first', () {
      // No id in the registry has three segments today, so this is the case the
      // transform has to keep handling for a card added later rather than one it
      // is exercised by now.
      expect(cardIdentifierKey('a_b_c'), 'a-b-c');
    });

    /// The one that can fail silently in production.
    ///
    /// A slug the generator's STATIC_RE rejects is dropped from
    /// `identifiers.generated.ts` without an error, so the app renders a hook that
    /// no E2E spec can import and nothing anywhere reports a problem. The assert
    /// inside the derivation is what turns that into a failure, and it composes the
    /// full hook to do it — a key can look fine on its own and still produce an
    /// identifier the generator drops.
    test('rejects an id whose hook the E2E generator would silently drop', () {
      expect(
          () => cardIdentifierKey('wifiStatus'), throwsA(isA<AssertionError>()),
          reason: 'an uppercase letter survives the transform and fails '
              'STATIC_RE, which the generator does not report');
      expect(() => cardIdentifierKey('wifi status'),
          throwsA(isA<AssertionError>()));
      expect(() => cardIdentifierKey('wifi__status'),
          throwsA(isA<AssertionError>()),
          reason: 'a doubled underscore becomes a doubled hyphen, which is an '
              'empty segment');
    });

    /// Swept over the *whole registry* rather than over the cards that have hooks
    /// today: a card that gains a detail entry or a popup form gets its hook with no
    /// edit to the derivation, so the shape has to hold for every id that could
    /// reach it.
    test('every registered card id composes two hooks the generator accepts',
        () {
      for (final spec in UspWidgetSpecs.all) {
        final key = cardIdentifierKey(spec.id);
        for (final prefix in [
          kCardDetailIdentifierPrefix,
          kCardPopupIdentifierPrefix,
        ]) {
          expect(
            '$prefix$key',
            matches(kE2eIdentifierPattern),
            reason: 'card "${spec.id}" composes "$prefix$key", which '
                'gen-identifiers.mts would silently drop (see '
                '_connectionTypeSlug in usp_ipv4_section.dart)',
          );
        }
      }
    });

    test('distinct cards derive distinct keys', () {
      final ids = UspWidgetSpecs.all.map((s) => s.id).toList();
      expect(
        ids.map(cardIdentifierKey).toSet(),
        hasLength(ids.length),
        reason: 'the hook is only worth having if it names one card: two cards '
            'sharing it is the defect #1450 exists to remove',
      );
    });

    /// The property that makes two prefixes better than one namespace: a tile and
    /// a detail button are different controls, and no spec should be able to click
    /// one believing it clicked the other. Over both families at once, because
    /// within one family the uniqueness test above already holds — what is new here
    /// is that the two cannot meet, for any pair of cards.
    test('no tile hook can collide with any card\'s detail hook', () {
      final keys = UspWidgetSpecs.all.map((s) => cardIdentifierKey(s.id));
      final all = [
        for (final key in keys) '$kCardDetailIdentifierPrefix$key',
        for (final key in keys) '$kCardPopupIdentifierPrefix$key',
      ];
      expect(
        all.toSet(),
        hasLength(all.length),
        reason:
            'the two hook families must stay disjoint: a tile answering to a '
            'detail handle would let a spec open a dialog where it meant to '
            'enter a page',
      );
    });
  });

  group('kE2eIdentifierPattern', () {
    test('accepts the shapes the app ships and rejects the ones it must not',
        () {
      // Pinned because the pattern is a restatement of a regex owned by another
      // repo: if this drifts from STATIC_RE, the sweep above stops meaning what
      // it claims.
      expect('card-detail-wifi-status', matches(kE2eIdentifierPattern));
      expect('topology-node-slave-a1b2', matches(kE2eIdentifierPattern));
      expect('card-detail-Wifi-Status', isNot(matches(kE2eIdentifierPattern)));
      expect('card_detail_wifi_status', isNot(matches(kE2eIdentifierPattern)));
      expect('carddetail', isNot(matches(kE2eIdentifierPattern)));
      expect('card--detail', isNot(matches(kE2eIdentifierPattern)));
    });
  });
}
