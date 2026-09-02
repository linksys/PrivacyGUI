import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/helpers/card_detail_identifier.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

/// Unit coverage for the detail-entry hook's derivation (#1450), required of a
/// per-instance identifier key by constitution Article XVI §16.3.
///
/// The widget-level contract — which card publishes which hook, and that it lands
/// on the link's own semantics node — is
/// `test/page/dashboard/cards/dashboard_card_detail_identifier_widget_test.dart`.
/// What is here is only what does not need a tree: the transform, and the shape
/// every id it can be handed comes out as.
void main() {
  group('cardDetailIdentifierFor', () {
    test('turns a registry id into a kebab hook under the shared prefix', () {
      expect(cardDetailIdentifierFor('wifi_status'), 'card-detail-wifi-status');
      expect(cardDetailIdentifierFor('topology'), 'card-detail-topology');
      expect(
        cardDetailIdentifierFor('dhcp_reservations'),
        'card-detail-dhcp-reservations',
      );
    });

    test('replaces every underscore, not just the first', () {
      // No id in the registry has three segments today, so this is the case the
      // transform has to keep handling for a card added later rather than one it
      // is exercised by now.
      expect(
        cardDetailIdentifierFor('a_b_c'),
        'card-detail-a-b-c',
      );
    });

    /// The one that can fail silently in production.
    ///
    /// A slug the generator's STATIC_RE rejects is dropped from
    /// `identifiers.generated.ts` without an error, so the app renders a hook that
    /// no E2E spec can import and nothing anywhere reports a problem. Asserted over
    /// the *whole registry* rather than over the ids that happen to have detail
    /// entries: a card that gains one later gets its hook with no edit to the
    /// derivation, so the pattern has to hold for every id that could reach it.
    test('every registered card id derives a hook the E2E generator accepts',
        () {
      for (final spec in UspWidgetSpecs.all) {
        final identifier = cardDetailIdentifierFor(spec.id);
        expect(
          identifier,
          matches(kE2eIdentifierPattern),
          reason: 'card "${spec.id}" derives "$identifier", which '
              'gen-identifiers.mts would silently drop — an uppercase letter or '
              'a non-alphanumeric character in the registry id is the usual '
              'cause (see _connectionTypeSlug in usp_ipv4_section.dart)',
        );
      }
    });

    test('distinct cards derive distinct hooks', () {
      final ids = UspWidgetSpecs.all.map((s) => s.id).toList();
      final identifiers = ids.map(cardDetailIdentifierFor).toSet();
      expect(
        identifiers,
        hasLength(ids.length),
        reason: 'the hook is only worth having if it names one card: two cards '
            'sharing it is the defect #1450 exists to remove',
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
