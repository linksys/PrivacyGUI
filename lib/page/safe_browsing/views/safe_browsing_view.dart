import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/responsive/responsive_bottom_button.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/safe_browsing/providers/_providers.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/setting_card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:linksys_widgets/widgets/radios/radio_list.dart';

class SafeBrowsingView extends ArgumentsConsumerStatefulView {
  const SafeBrowsingView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<SafeBrowsingView> createState() => _SafeBrowsingViewState();
}

class _SafeBrowsingViewState extends ConsumerState<SafeBrowsingView> {
  late final SafeBrowsingNotifier _notifier;
  bool isLoading = true;
  bool enableSafeBrowsing = false;
  SafeBrowsingType currentSafeBrowsingType = SafeBrowsingType.fortinet;
  String loadingDesc = '';

  @override
  void initState() {
    _notifier = ref.read(safeBrowsingProvider.notifier);
    _fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(safeBrowsingProvider);
    return isLoading
        ? AppFullScreenSpinner(
            title: loc(context).safeBrowsing,
            text: loadingDesc,
          )
        : StyledAppPageView(
            scrollable: true,
            title: loc(context).safeBrowsing,
            child: AppBasicLayout(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyLarge(loc(context).safeBrowsingDesc),
                  const AppGap.big(),
                  AppSettingCard(
                    title: loc(context).safeBrowsing,
                    trailing: AppSwitch(
                      value: enableSafeBrowsing,
                      onChanged: (enable) {
                        setState(() {
                          enableSafeBrowsing = enable;
                        });
                      },
                    ),
                  ),
                  const AppGap.semiSmall(),
                  Opacity(
                    opacity: enableSafeBrowsing ? 1 : 0.5,
                    child: AppSettingCard(
                      title: loc(context).provider,
                      description:
                          _getTextFormSafeBrowsingType(currentSafeBrowsingType),
                      trailing: AppIconButton(
                        icon: Icons.edit,
                        onTap: enableSafeBrowsing
                            ? () {
                                _showProviderSelector(state.hasFortinet);
                              }
                            : null,
                      ),
                    ),
                  ),
                  responsiveGap(context),
                  responsiveBottomButton(
                    context: context,
                    title: loc(context).save,
                    onTap: _edited(state.safeBrowsingType)
                        ? _showRestartAlert
                        : null,
                  ),
                ],
              ),
            ),
          );
  }

  _showProviderSelector(bool hasFortinet) {
    SafeBrowsingType type = currentSafeBrowsingType;
    showDialog<SafeBrowsingType?>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.titleLarge(loc(context).provider),
            content: AppRadioList(
              initial: type,
              mainAxisSize: MainAxisSize.min,
              items: [
                if (hasFortinet)
                  AppRadioListItem(
                    title: loc(context).fortinetSecureDns,
                    value: SafeBrowsingType.fortinet,
                  ),
                AppRadioListItem(
                  title: loc(context).openDNS,
                  value: SafeBrowsingType.openDNS,
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
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.titleLarge(loc(context).restartWifiAlertTitle),
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
        });
  }

  String _getTextFormSafeBrowsingType(SafeBrowsingType type) {
    return switch (type) {
      SafeBrowsingType.fortinet => loc(context).fortinetSecureDns,
      SafeBrowsingType.openDNS => loc(context).openDNS,
      SafeBrowsingType.off => loc(context).off,
    };
  }

  void _setSafeBrowsing() {
    setState(() {
      isLoading = true;
      loadingDesc = loc(context).restartingWifi;
    });
    _notifier
        .setSafeBrowsing(
            enableSafeBrowsing ? currentSafeBrowsingType : SafeBrowsingType.off)
        .then((_) {
      _initCurrentState();
      showSuccessSnackBar(
        context,
        loc(context).settingsSaved,
      );
    }).onError((error, stackTrace) {
      final errorMsg = switch (error) {
        SafeBrowsingError => (error as SafeBrowsingError).message,
        _ => 'Unknown error',
      };
      showFailedSnackBar(
        context,
        errorMsg ?? '',
      );
    }).whenComplete(() {
      setState(() {
        isLoading = false;
        loadingDesc = '';
      });
    });
  }

  Future _fetchData() async {
    _notifier.fetchLANSettings().then((_) {
      _initCurrentState();
    }).whenComplete(() {
      setState(() {
        isLoading = false;
      });
    });
  }

  _initCurrentState() {
    setState(() {
      final stateSafeBrowsingType =
          ref.read(safeBrowsingProvider).safeBrowsingType;
      enableSafeBrowsing = !(stateSafeBrowsingType == SafeBrowsingType.off);
      if (stateSafeBrowsingType == SafeBrowsingType.off) {
        currentSafeBrowsingType = ref.read(safeBrowsingProvider).hasFortinet
            ? SafeBrowsingType.fortinet
            : SafeBrowsingType.openDNS;
      } else {
        currentSafeBrowsingType = stateSafeBrowsingType;
      }
    });
  }

  bool _edited(SafeBrowsingType stateSafeBrowsingType) {
    if (stateSafeBrowsingType == SafeBrowsingType.off) {
      return enableSafeBrowsing;
    } else {
      return !enableSafeBrowsing ||
          (stateSafeBrowsingType != currentSafeBrowsingType);
    }
  }
}
