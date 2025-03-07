import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
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
  bool enableSafeBrowsing = false;
  InstantSafetyType currentSafeBrowsingType = InstantSafetyType.fortinet;
  String loadingDesc = '';

  @override
  void initState() {
    _notifier = ref.read(instantSafetyProvider.notifier);

    _fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantSafetyProvider);

    return StyledAppPageView(
      scrollable: true,
      title: loc(context).instantSafety,
      onBackTap: _edited(state.safeBrowsingType)
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                context.pop();
              }
            }
          : null,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _edited(state.safeBrowsingType),
        onPositiveTap: _showRestartAlert,
      ),
      child: (context, constraints, scrollController) =>AppBasicLayout(
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
                  setState(() {
                    enableSafeBrowsing = enable;
                  });
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
                          initial: currentSafeBrowsingType,
                          mainAxisSize: MainAxisSize.min,
                          itemHeight: 56,
                          items: [
                            if (state.hasFortinet)
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
                            setState(() {
                              if (selectedType != null) {
                                currentSafeBrowsingType = selectedType;
                              }
                            });
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
            _setSafeBrowsing();
            context.pop();
          },
        ),
      ],
    );
  }

  void _setSafeBrowsing() {
    setState(() {
      loadingDesc = loc(context).restartingWifi;
    });
    doSomethingWithSpinner(
      context,
      messages: [loadingDesc],
      _notifier
          .setSafeBrowsing(enableSafeBrowsing
              ? currentSafeBrowsingType
              : InstantSafetyType.off)
          .then((_) {
        _initCurrentState();
        showChangesSavedSnackBar();
      }),
    ).catchError((error) {
      showRouterNotFoundAlert(context, ref, onComplete: () async {
        await ref
            .read(instantSafetyProvider.notifier)
            .fetchLANSettings(fetchRemote: true);
        _initCurrentState();
        showChangesSavedSnackBar();
      });
    }, test: (error) => error is JNAPSideEffectError).onError(
        (error, stackTrace) {
      final errorMsg = switch (error.runtimeType) {
        SafeBrowsingError => (error as SafeBrowsingError).message,
        _ => 'Unknown error',
      };
      showFailedSnackBar(
        context,
        errorMsg ?? '',
      );
    }).whenComplete(
      () {
        setState(() {
          loadingDesc = '';
        });
      },
    );
  }

  Future _fetchData() async {
    doSomethingWithSpinner(
      context,
      _notifier.fetchLANSettings().then(
        (_) {
          _initCurrentState();
        },
      ),
    );
  }

  _initCurrentState() {
    setState(() {
      final stateSafeBrowsingType =
          ref.read(instantSafetyProvider).safeBrowsingType;
      enableSafeBrowsing = !(stateSafeBrowsingType == InstantSafetyType.off);
      if (stateSafeBrowsingType == InstantSafetyType.off) {
        currentSafeBrowsingType = ref.read(instantSafetyProvider).hasFortinet
            ? InstantSafetyType.fortinet
            : InstantSafetyType.openDNS;
      } else {
        currentSafeBrowsingType = stateSafeBrowsingType;
      }
    });
  }

  bool _edited(InstantSafetyType stateSafeBrowsingType) {
    if (stateSafeBrowsingType == InstantSafetyType.off) {
      return enableSafeBrowsing;
    } else {
      return !enableSafeBrowsing ||
          (stateSafeBrowsingType != currentSafeBrowsingType);
    }
  }
}
