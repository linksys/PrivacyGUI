import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/bloc/wifi_setting/_wifi_setting.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class WifiSettingsReviewView extends ArgumentsConsumerStatefulView {
  const WifiSettingsReviewView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<WifiSettingsReviewView> createState() =>
      _WifiSettingsReviewViewState();
}

class _WifiSettingsReviewViewState
    extends ConsumerState<WifiSettingsReviewView> {
  bool isLoading = false;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? AppFullScreenSpinner(text: getAppLocalizations(context).processing)
        : BlocBuilder<WifiSettingCubit, WifiSettingState>(
            builder: (context, state) => StyledAppPageView(
              title: state.selectedWifiItem.ssid,
              child: AppBasicLayout(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppText.descriptionMain(
                          state.selectedWifiItem.wifiType.displayTitle,
                        ),
                        const Spacer(),
                        AppSwitch(
                            value: state.selectedWifiItem.isWifiEnabled,
                            onChanged: (enabled) {
                              setState(() {
                                isLoading = true;
                              });
                              final wifiType = context
                                  .read<WifiSettingCubit>()
                                  .state
                                  .selectedWifiItem
                                  .wifiType;
                              context
                                  .read<WifiSettingCubit>()
                                  .enableWifi(enabled, wifiType)
                                  .then((value) {
                                setState(() {
                                  isLoading = false;
                                });
                              });
                            })
                      ],
                    ),
                    const AppText.descriptionSub(
                      'Where most of your devices connect.',
                    ),
                    const AppPadding(
                      padding: AppEdgeInsets.only(
                          top: AppGapSize.small, bottom: AppGapSize.regular),
                      child: AppText.descriptionSub(
                        '6 GHz, 5 GHz, 2.4 GHz',
                        //TODO: Remove the dummy recent bands
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        itemCount: state
                            .selectedWifiItem.wifiType.settingOptions.length,
                        itemBuilder: (context, index) =>
                            _buildListCell(index, state.selectedWifiItem),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildListCell(int index, WifiListItem wifiItem) {
    String content;

    final currentOption = wifiItem.wifiType.settingOptions[index];
    switch (currentOption) {
      case WifiSettingOption.nameAndPassword:
        content = wifiItem.ssid;
        break;
      case WifiSettingOption.securityType6G:
        content = wifiItem.security6GType?.displayTitle ??
            wifiItem.securityType.displayTitle;
        break;
      case WifiSettingOption.securityTypeBelow6G:
        content = wifiItem.securityType.displayTitle;
        break;
      case WifiSettingOption.securityType:
        content = wifiItem.securityType.displayTitle;
        break;
      case WifiSettingOption.mode:
        content = wifiItem.mode.value;
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _onSettingTap(index, wifiItem),
      child: Row(
        children: [
          AppPadding(
              padding:
                  const AppEdgeInsets.symmetric(vertical: AppGapSize.regular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.descriptionSub(
                    currentOption.displayTitle,
                  ),
                  const AppGap.small(),
                  AppText.descriptionSub(
                    content,
                  ),
                ],
              )),
          const Spacer(),
          AppIcon(
            icon: getCharactersIcons(context).chevronRight,
          ),
        ],
      ),
    );
  }

  void _onSettingTap(int index, WifiListItem wifiItem) {
    final currentOption = wifiItem.wifiType.settingOptions[index];
    switch (currentOption) {
      case WifiSettingOption.nameAndPassword:
        // ref.read(navigationsProvider.notifier).push(EditWifiNamePasswordPath());
        context.pushNamed(RouteNamed.wifiEditSSID);
        break;
      case WifiSettingOption.securityType6G:
      case WifiSettingOption.securityTypeBelow6G:
      case WifiSettingOption.securityType:
        // ref.read(navigationsProvider.notifier).pushAndWait(
        //     EditWifiSecurityPath()
        //       ..args = {'wifiSettingOption': currentOption});
        context.pushNamed(RouteNamed.wifiEditSecurity, queryParameters: {
          'wifiSettingOption': currentOption.name,
        });

        break;
      case WifiSettingOption.mode:
        // ref.read(navigationsProvider.notifier).push(EditWifiModePath());
        context.pushNamed(RouteNamed.wifiEditMode);

        break;
    }
  }
}
