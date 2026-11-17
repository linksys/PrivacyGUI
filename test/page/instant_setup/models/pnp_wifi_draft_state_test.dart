import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/empty_status.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_draft_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_settings.dart';

/// The drafts the PnP wizard's setting steps keep (#1511 P4): a working copy
/// over what the router had, and nothing that would carry the passphrase out.
void main() {
  const main = PnpMainWifiSettings(ssid: 'Home', password: 'HomePass1');
  const guest = PnpGuestWifiSettings(
      enabled: true, ssid: 'Home-guest', password: 'GuestPass1');

  group('PnpMainWifiDraftState', () {
    test('begins at the read, clean, with no status', () {
      final draft = PnpMainWifiDraftState.from(main);

      expect(draft.settings.original, main);
      expect(draft.current, main);
      expect(draft.isDirty, isFalse);
      expect(draft.status, const EmptyStatus());
    });

    test('an edit is dirty, and saving it is clean again', () {
      final draft = PnpMainWifiDraftState.from(main);
      final edited = draft.copyWith(
          settings: draft.settings.update(main.copyWith(ssid: 'New')));

      expect(edited.isDirty, isTrue);
      expect(edited.settings.original, main,
          reason: 'what the router had stays, for a revert');
      expect(
          edited.copyWith(settings: edited.settings.saved()).isDirty, isFalse);
    });

    test('copyWith with nothing is the same draft', () {
      final draft = PnpMainWifiDraftState.from(main);

      expect(draft.copyWith(), draft);
    });

    test('toMap carries nothing — it would carry the passphrase', () {
      expect(PnpMainWifiDraftState.from(main).toMap(), isEmpty);
    });
  });

  group('PnpGuestWifiDraftState', () {
    test('begins at the read, clean, with no status', () {
      final draft = PnpGuestWifiDraftState.from(guest);

      expect(draft.settings.original, guest);
      expect(draft.current, guest);
      expect(draft.isDirty, isFalse);
      expect(draft.status, const EmptyStatus());
    });

    test('turning the guest network off is dirty', () {
      final draft = PnpGuestWifiDraftState.from(guest);
      final edited = draft.copyWith(
          settings: draft.settings.update(guest.copyWith(enabled: false)));

      expect(edited.isDirty, isTrue);
    });

    test('toMap carries nothing — it would carry the passphrase', () {
      expect(PnpGuestWifiDraftState.from(guest).toMap(), isEmpty);
    });
  });
}
