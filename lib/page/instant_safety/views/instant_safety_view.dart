import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_safety/providers/_providers.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_expand_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';

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

    final bool enableSafeBrowsing = settings.safeBrowsingType != InstantSafetyType.off;

    return StyledAppPageView(
      scrollable: true,
      title: loc(context).instantSafety,
      bottomBar: PageBottomBar(
        isPositiveEnabled: state.isDirty,
        onPositiveTap: _showRestartAlert,
      ),
      child: (context, constraints) => AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyLarge(loc(context).safeBrowsingDesc),
            const AppGap.large3(),
            AppListExpandCard(
              title: AppText.labelLarge(loc(context).instantSafety),
              trailing: AppSwitch(
                semanticLabel: 'instant safety',
                value: enableSafeBrowsing,
                onChanged: (enable) {
                  _notifier.setSafeBrowsingEnabled(enable);
                },
              ),
              description: enableSafeBrowsing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppGap.medium(),
                        const Divider(
                          height: 1,
                        ),
                        const AppGap.large2(),
                        AppText.labelLarge(loc(context).provider),
                        AppRadioList(
                          initial: settings.safeBrowsingType,
                          mainAxisSize: MainAxisSize.min,
                          itemHeight: 56,
                          items: [
                            if (status.hasFortinet)
                              AppRadioListItem(
                                title: loc(context).fortinetSecureDns,
                                value: InstantSafetyType.fortinet,
                              ),
                            AppRadioListItem(
                              title: loc(context).openDNS,
                              value: InstantSafetyType.openDNS,
                            ),
                          ],
                          onChanged: (index, selectedType) {
                            if (selectedType != null) {
                              _notifier.setSafeBrowsingProvider(selectedType);
                            }
                          },
                        ),
                      ],
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showRestartAlert() {
    showSimpleAppDialog(
      context,
      title: loc(context).restartWifiAlertTitle,
      content: AppText.bodyMedium(loc(context).restartWifiAlertDesc),
      actions: [
        AppTextButton(
          loc(context).cancel,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            context.pop();
          },
        ),
        AppTextButton(
          loc(context).restart,
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
      if (error is JNAPSideEffectError) {
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          await _notifier.fetchLANSettings(fetchRemote: true);
          showChangesSavedSnackBar();
        });
      } else {
         showFailedSnackBar((error as SafeBrowsingError?)?.message ?? 'Unknown error');
      }
    });
  }
}
