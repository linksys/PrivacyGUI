import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_wifi_drafts.dart';
import 'package:privacy_gui/page/instant_setup/views/components/pnp_step_footer.dart';
import 'package:privacy_gui/page/instant_setup/views/components/pnp_wifi_fields.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The PnP wizard's guest step: the guest network on or off, and its name and
/// password (#1511 P4).
///
/// In the plan only when the router has a guest SSID. Its edits go to the
/// step's draft ([pnpGuestWifiDraftProvider]); see `PnpWifiStepView`.
class PnpGuestStepView extends ConsumerStatefulWidget {
  const PnpGuestStepView({super.key});

  /// This step's id in the plan.
  static const stepId = 'guest';

  @override
  ConsumerState<PnpGuestStepView> createState() => _PnpGuestStepViewState();
}

class _PnpGuestStepViewState extends ConsumerState<PnpGuestStepView> {
  late final TextEditingController _ssid;
  late final TextEditingController _password;
  final Map<String, TextEditingController> _bandSsid = {};
  final Map<String, TextEditingController> _bandPassword = {};

  @override
  void initState() {
    super.initState();
    final draft = ref.read(pnpGuestWifiDraftProvider).current;
    _ssid = TextEditingController(text: draft.ssid);
    _password = TextEditingController(text: draft.password);
    for (final band in draft.bands) {
      _bandSsid[band.ssidInstancePath] = TextEditingController(text: band.ssid);
      _bandPassword[band.ssidInstancePath] =
          TextEditingController(text: band.password);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _ssid,
      _password,
      ..._bandSsid.values,
      ..._bandPassword.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(pnpGuestWifiDraftProvider).current;
    final edit = ref.read(pnpGuestWifiDraftProvider.notifier);
    // A guest network that is off has no password to check.
    final valid = !draft.enabled ||
        (draft.splitMode
            ? _bandPassword.values
                .every((c) => pnpWifiPasswordValid(context, c.text))
            : pnpWifiPasswordValid(context, _password.text));

    return UiKitPageView.innerPage(
      scrollable: true,
      useMainPadding: false,
      child: (context, constraints) => Column(
        // In a Column so the card wraps its content: as the page's own child
        // it took the scroll view's minimum height and ran to the bottom of
        // the screen (bench, 2026-11-13).
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText.titleMedium(loc(context).guestWifi),
                  AppGap.xl(),
                  LayoutBlock(
                    child: Row(
                      children: [
                        Expanded(
                          child: AppText.labelLarge(loc(context).guestNetwork),
                        ),
                        AppGap.md(),
                        AppSwitch(
                          value: draft.enabled,
                          identifier: 'pnp-guest-enabled',
                          onChanged: edit.setEnabled,
                        ),
                      ],
                    ),
                  ),
                  if (draft.enabled) ...[
                    AppGap.md(),
                    if (draft.splitMode)
                      for (final (i, band) in draft.bands.indexed) ...[
                        if (i > 0) AppGap.md(),
                        PnpWifiFields(
                          guest: true,
                          band: band,
                          ssidController: _bandSsid[band.ssidInstancePath]!,
                          passwordController:
                              _bandPassword[band.ssidInstancePath]!,
                          onSsidChanged: (v) =>
                              edit.setBandSsid(band.ssidInstancePath, v),
                          onPasswordChanged: (v) {
                            edit.setBandPassword(band.ssidInstancePath, v);
                            setState(() {}); // the rule indicators
                          },
                        ),
                      ]
                    else
                      PnpWifiFields(
                        guest: true,
                        ssidController: _ssid,
                        passwordController: _password,
                        onSsidChanged: edit.setSsid,
                        onPasswordChanged: (v) {
                          edit.setPassword(v);
                          setState(() {}); // the rule indicators
                        },
                      ),
                  ],
                  AppGap.xxxl(),
                  PnpStepFooter(
                    stepId: PnpGuestStepView.stepId,
                    canContinue: valid,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
