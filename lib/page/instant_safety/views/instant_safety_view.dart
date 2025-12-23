import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_safety/providers/_providers.dart';
import 'package:ui_kit_library/ui_kit.dart';

class InstantSafetyView extends ArgumentsConsumerStatefulView {
  const InstantSafetyView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<InstantSafetyView> createState() => _InstantSafetyViewState();
}

class _InstantSafetyViewState extends ConsumerState<InstantSafetyView>
    with PageSnackbarMixin {
  late final InstantSafetyNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(instantSafetyProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantSafetyProvider);
    final settings = state.settings.current;
    final status = state.status;

    final bool enableSafeBrowsing =
        settings.safeBrowsingType != InstantSafetyType.off;

    return UiKitPageView.withSliver(
      title: loc(context).instantSafety,
      bottomBar: UiKitBottomBarConfig(
        isPositiveEnabled: state.isDirty,
        onPositiveTap: _showRestartAlert,
      ),
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(loc(context).safeBrowsingDesc),
          AppGap.xxxl(),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText.labelLarge(loc(context).instantSafety),
                    ),
                    AppSwitch(
                      value: enableSafeBrowsing,
                      onChanged: (enable) {
                        _notifier.setSafeBrowsingEnabled(enable);
                      },
                    ),
                  ],
                ),
                if (enableSafeBrowsing) ...[
                  AppGap.lg(),
                  const Divider(height: 1),
                  AppGap.xxl(),
                  AppText.labelLarge(loc(context).provider),
                  AppGap.sm(),
                  ...[
                    AppRadioList<InstantSafetyType>(
                      selected: settings.safeBrowsingType,
                      items: [
                        if (status.hasFortinet)
                          AppRadioListItem<InstantSafetyType>(
                            title: loc(context).fortinetSecureDns,
                            value: InstantSafetyType.fortinet,
                          ),
                        AppRadioListItem<InstantSafetyType>(
                          title: loc(context).openDNS,
                          value: InstantSafetyType.openDNS,
                        ),
                      ],
                      onChanged: (index, value) {
                        if (value != null) {
                          _notifier.setSafeBrowsingProvider(value);
                        }
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRestartAlert() {
    showSimpleAppDialog(
      context,
      title: loc(context).restartWifiAlertTitle,
      content: AppText.bodyMedium(loc(context).restartWifiAlertDesc),
      actions: [
        AppButton.text(
          label: loc(context).cancel,
          onTap: () {
            context.pop();
          },
        ),
        AppButton.text(
          label: loc(context).restart,
          onTap: () {
            context.pop(); // Close the dialog first
            _saveSettings();
          },
        ),
      ],
    );
  }

  void _saveSettings() {
    doSomethingWithSpinner(
      context,
      messages: [loc(context).restartingWifi],
      _notifier.save().then((_) {
        showChangesSavedSnackBar();
      }),
    ).catchError((error, stackTrace) {
      if (!mounted) return;
      if (error is JNAPSideEffectError) {
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          await _notifier.fetch(forceRemote: true);
          if (!mounted) return;
          showChangesSavedSnackBar();
        });
      } else if (error is UnexpectedError) {
        showFailedSnackBar(error.message ?? 'Unknown error');
      } else {
        showFailedSnackBar('Unknown error');
      }
    });
  }
}
