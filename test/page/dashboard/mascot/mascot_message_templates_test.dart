import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/mascot/mascot_message_templates.dart';

/// #1312: what the mascot's speech bubbles say.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ja = lookupAppLocalizations(const Locale('ja'));

  String say(
    String id,
    AppLocalizations l10n, [
    MascotMessageContext context = const MascotMessageContext.empty(),
  ]) =>
      MascotMessageCategory.values
          .expand(getTemplatesForCategory)
          .singleWhere((template) => template.id == id)
          .generate(context, l10n);

  group('a line with a count agrees with it', () {
    test('devices', () {
      expect(
        say(
            'status_devices',
            en,
            const MascotMessageContext(
                onlineDeviceCount: 1, totalDeviceCount: 1)),
        '1 of 1 device connected',
      );
      expect(
        say(
            'status_devices',
            en,
            const MascotMessageContext(
                onlineDeviceCount: 2, totalDeviceCount: 5)),
        '2 of 5 devices connected',
      );
    });

    test('mesh nodes', () {
      expect(
          say('status_mesh', en, const MascotMessageContext(meshNodeCount: 1)),
          'Your mesh network has 1 node active');
      expect(
          say('status_mesh', en, const MascotMessageContext(meshNodeCount: 3)),
          'Your mesh network has 3 nodes active');
    });

    test('every WiFi radio on', () {
      expect(
        say(
            'status_wifi_all',
            en,
            const MascotMessageContext(
                enabledRadioCount: 1, totalRadioCount: 1)),
        'Your WiFi radio is active',
      );
      expect(
        say(
            'status_wifi_all',
            en,
            const MascotMessageContext(
                enabledRadioCount: 3, totalRadioCount: 3)),
        'All 3 WiFi radios are active',
      );
    });

    test('no WiFi radio is not "all of them on"', () {
      // 0 == 0 used to pass the condition and read "All 0 WiFi radios are
      // active" — and in French, where 0 takes the `one` form, "your WiFi
      // radio is active".
      final allOn =
          statusTemplates.singleWhere((t) => t.id == 'status_wifi_all');
      expect(
        allOn.shouldShow(const MascotMessageContext(
            enabledRadioCount: 0, totalRadioCount: 0)),
        isFalse,
      );
    });

    test('some WiFi radios on', () {
      expect(
        say(
            'status_wifi_partial',
            en,
            const MascotMessageContext(
                enabledRadioCount: 0, totalRadioCount: 1)),
        '0 of 1 WiFi radio enabled',
      );
      expect(
        say(
            'status_wifi_partial',
            en,
            const MascotMessageContext(
                enabledRadioCount: 1, totalRadioCount: 3)),
        '1 of 3 WiFi radios enabled',
      );
    });
  });

  group('a tip that names a place in the app', () {
    test('names where it really is', () {
      // The app has no sidebar: its menu is a top bar on desktop and a bottom
      // bar on mobile.
      expect(say('guide_wifi', en), "WiFi settings are under 'WiFi Settings'");
      expect(say('guide_devices', en),
          "Tap 'Devices' to see all connected devices");
      // Firmware is the OTA Update card on the Administration page, Firewall is
      // under Advanced Settings, and the guest network is the Guest card on the
      // WiFi Settings page.
      expect(say('guide_firmware', en),
          "Check for firmware updates in 'Administration > OTA Update'");
      expect(say('guide_security', en),
          "Security settings are under 'Advanced Settings > Firewall'");
      expect(say('guide_guest', en),
          "Create a guest network in 'WiFi Settings > Guest'");
    });

    test('uses the names the app shows, in the user language', () {
      // The values of menuWifiSettings, devices, administration, otaUpdate,
      // advancedSettings, firewall and guest in `app_ja.arb`.
      expect(say('guide_wifi', ja), contains('WiFi 設定'));
      expect(say('guide_devices', ja), contains('デバイス'));
      expect(
          say('guide_firmware', ja), allOf(contains('管理'), contains('OTA 更新')));
      expect(say('guide_security', ja),
          allOf(contains('詳細設定'), contains('ファイアウォール')));
      expect(
          say('guide_guest', ja), allOf(contains('WiFi 設定'), contains('ゲスト')));
    });
  });

  test('before the dashboard has loaded, the mascot offers help', () {
    expect(MascotMessage.fallback(en).text, "I'm here if you need help!");
  });
}
