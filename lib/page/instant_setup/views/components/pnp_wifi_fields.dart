import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_band.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The Wi-Fi password rules the PnP steps show under a password field.
///
/// The hex rule is shown only for a 64-character entry, which is a PSK.
List<AppPasswordRule> pnpWifiPasswordRules(BuildContext context, String text) =>
    [
      AppPasswordRule(
        label: loc(context).wifiPasswordLimit, // "8 - 64 characters"
        validate: (text) => LengthRule(min: 8, max: 64).validate(text),
      ),
      AppPasswordRule(
        label: loc(context).routerPasswordRuleStartEndWithSpace,
        validate: (text) =>
            text.isEmpty || NoSurroundWhitespaceRule().validate(text),
      ),
      AppPasswordRule(
        label: loc(context).routerPasswordRuleUnsupportSpecialChar,
        validate: (text) => text.isEmpty || AsciiRule().validate(text),
      ),
      if (text.length == 64)
        AppPasswordRule(
          label: loc(context).wifiPasswordRuleHex,
          validate: (text) => WiFiPSKRule().validate(text),
        ),
    ];

/// Whether [text] passes every rule [pnpWifiPasswordRules] shows. An empty
/// password never does.
bool pnpWifiPasswordValid(BuildContext context, String text) =>
    text.isNotEmpty &&
    pnpWifiPasswordRules(context, text).every((r) => r.validate(text));

/// One network's name and password, in a [LayoutBlock] — the form of both
/// PnP Wi-Fi steps, once for a unified network or once per band of a split one.
class PnpWifiFields extends StatelessWidget {
  const PnpWifiFields({
    super.key,
    required this.guest,
    this.band,
    required this.ssidController,
    required this.passwordController,
    required this.onSsidChanged,
    required this.onPasswordChanged,
  });

  /// The guest network's fields rather than the main network's — which E2E
  /// hook they carry.
  final bool guest;

  /// The band, for a split network; `null` for a unified one.
  final PnpWifiBand? band;
  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final ValueChanged<String> onSsidChanged;

  /// Also what makes the rule list re-check: the caller rebuilds on it.
  final ValueChanged<String> onPasswordChanged;

  // The E2E hooks (constitution Article XVI) are literal ternaries right at the
  // `identifier:` site, braced interpolation and all: that is the one shape the
  // E2E generator harvests. A bare `$key`, or a string handed in from the
  // caller, would compile and silently never reach its selector map.
  @override
  Widget build(BuildContext context) {
    return LayoutBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (band != null) ...[
            AppText.labelLarge(band!.bandName),
            AppGap.md(),
          ],
          AppText.labelMedium(loc(context).wifiName),
          AppGap.xs(),
          AppTextField(
            hintText: loc(context).wifiName,
            controller: ssidController,
            identifier: guest
                ? 'pnp-guest-ssid-${pnpBandIdentifierKey(band)}'
                : 'pnp-wifi-ssid-${pnpBandIdentifierKey(band)}',
            onChanged: onSsidChanged,
          ),
          AppGap.lg(),
          AppPasswordInput(
            label: loc(context).wifiPassword,
            hintText: loc(context).wifiPassword,
            controller: passwordController,
            rules: pnpWifiPasswordRules(context, passwordController.text),
            identifier: guest
                ? 'pnp-guest-password-${pnpBandIdentifierKey(band)}'
                : 'pnp-wifi-password-${pnpBandIdentifierKey(band)}',
            onChanged: onPasswordChanged,
          ),
        ],
      ),
    );
  }
}
