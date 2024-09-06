import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  late final SafeBrowsingNotifier _notifier;
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
    SafeBrowsingType type = currentSafeBrowsingType;
    showDialog<SafeBrowsingType?>(
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

  String _getTextFormSafeBrowsingType(SafeBrowsingType type) {
    return switch (type) {
      SafeBrowsingType.fortinet => loc(context).fortinetSecureDns,
      SafeBrowsingType.openDNS => loc(context).openDNS,
      SafeBrowsingType.off => loc(context).off,
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
              : SafeBrowsingType.off)
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
      }).whenComplete(
        () {
          setState(() {
            loadingDesc = '';
          });
        },
      ),
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
