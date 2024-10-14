import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_safety/providers/_providers.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
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

class _InstantSafetyViewState extends ConsumerState<InstantSafetyView> {
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
      bottomBar: PageBottomBar(
        isPositiveEnabled: _edited(state.safeBrowsingType),
        onPositiveTap: _showRestartAlert,
      ),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyLarge(loc(context).safeBrowsingDesc),
            const AppGap.large3(),
            AppSettingCard(
              title: loc(context).safeBrowsing,
              trailing: AppSwitch(
                semanticLabel: 'safe browsing',
                value: enableSafeBrowsing,
                onChanged: (enable) {
                  setState(() {
                    enableSafeBrowsing = enable;
                  });
                },
              ),
            ),
            const AppGap.small2(),
            Opacity(
              opacity: enableSafeBrowsing ? 1 : 0.5,
              child: AppSettingCard(
                title: loc(context).provider,
                description:
                    _getTextFormSafeBrowsingType(currentSafeBrowsingType),
                trailing: AppIconButton(
                  icon: LinksysIcons.edit,
                  semanticLabel: 'edit',
                  onTap: enableSafeBrowsing
                      ? () {
                          _showProviderSelector(state.hasFortinet);
                        }
                      : null,
                ),
                onTap: enableSafeBrowsing
                    ? () {
                        _showProviderSelector(state.hasFortinet);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _showProviderSelector(bool hasFortinet) {
    InstantSafetyType type = currentSafeBrowsingType;
    showDialog<InstantSafetyType?>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.titleLarge(loc(context).provider),
            content: AppRadioList(
              initial: type,
              mainAxisSize: MainAxisSize.min,
              itemHeight: 56,
              items: [
                if (hasFortinet)
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
                    type = selectedType;
                  }
                });
              },
            ),
            actions: [
              AppTextButton(
                loc(context).cancel,
                color: Theme.of(context).colorScheme.onSurface,
                onTap: () {
                  context.pop();
                },
              ),
              AppTextButton(
                loc(context).save,
                onTap: () {
                  context.pop(type);
                },
              ),
            ],
          );
        }).then((value) {
      setState(() {
        if (value != null) {
          currentSafeBrowsingType = value;
        }
      });
    });
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

  String _getTextFormSafeBrowsingType(InstantSafetyType type) {
    return switch (type) {
      InstantSafetyType.fortinet => loc(context).fortinetSecureDns,
      InstantSafetyType.openDNS => loc(context).openDNS,
      InstantSafetyType.off => loc(context).off,
    };
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
        showSuccessSnackBar(
          context,
          loc(context).settingsSaved,
        );
      }),
    ).catchError((error) {
      logger.d('[XXXXX] Router not found!!!');
      showRouterNotFoundAlert(context, ref);
    }, test: (error) => error is JNAPSideEffectError).onError(
        (error, stackTrace) {
      logger.d('[XXXXX] error: $error');

      final errorMsg = switch (error) {
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
