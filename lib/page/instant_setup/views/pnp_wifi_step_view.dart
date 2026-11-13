import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_wifi_drafts.dart';
import 'package:privacy_gui/page/instant_setup/views/components/pnp_step_footer.dart';
import 'package:privacy_gui/page/instant_setup/views/components/pnp_wifi_fields.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The PnP wizard's Wi-Fi step: the main network's name and password
/// (#1511 P4).
///
/// A page of its own under `/pnp/pnpConfig/wifi`, inside the PnP shell, which
/// draws the top bar and the stepper around it. What the user types goes to
/// the step's draft ([pnpMainWifiDraftProvider]), which outlives this page:
/// pressing Next unmounts it, and coming Back seeds the fields from the draft.
class PnpWifiStepView extends ConsumerStatefulWidget {
  const PnpWifiStepView({super.key});

  /// This step's id in the plan.
  static const stepId = 'wifi';

  @override
  ConsumerState<PnpWifiStepView> createState() => _PnpWifiStepViewState();
}

class _PnpWifiStepViewState extends ConsumerState<PnpWifiStepView> {
  late final TextEditingController _ssid;
  late final TextEditingController _password;
  final Map<String, TextEditingController> _bandSsid = {};
  final Map<String, TextEditingController> _bandPassword = {};

  @override
  void initState() {
    super.initState();
    final draft = ref.read(pnpMainWifiDraftProvider).current;
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
    final draft = ref.watch(pnpMainWifiDraftProvider).current;
    final edit = ref.read(pnpMainWifiDraftProvider.notifier);
    final valid = draft.splitMode
        ? _bandPassword.values
            .every((c) => pnpWifiPasswordValid(context, c.text))
        : pnpWifiPasswordValid(context, _password.text);

    return UiKitPageView.innerPage(
      scrollable: true,
      useMainPadding: false,
      child: (context, constraints) => AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText.titleMedium(loc(context).pnpPersonalizeWiFiTitle),
              AppGap.sm(),
              AppText.bodyMedium(loc(context).pnpPersonalizeInfo),
              AppGap.xl(),
              if (draft.splitMode)
                for (final (i, band) in draft.bands.indexed) ...[
                  if (i > 0) AppGap.md(),
                  PnpWifiFields(
                    bandName: band.bandName,
                    ssidController: _bandSsid[band.ssidInstancePath]!,
                    passwordController: _bandPassword[band.ssidInstancePath]!,
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
                  ssidController: _ssid,
                  passwordController: _password,
                  onSsidChanged: edit.setSsid,
                  onPasswordChanged: (v) {
                    edit.setPassword(v);
                    setState(() {}); // the rule indicators
                  },
                ),
              AppGap.xxxl(),
              PnpStepFooter(
                stepId: PnpWifiStepView.stepId,
                canContinue: valid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
