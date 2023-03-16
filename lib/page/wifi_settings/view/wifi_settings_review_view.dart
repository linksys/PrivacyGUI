import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/wifi_setting/_wifi_setting.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/wifi_settings_path.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class WifiSettingsReviewView extends ArgumentsStatefulView {
  const WifiSettingsReviewView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  State<WifiSettingsReviewView> createState() => _WifiSettingsReviewViewState();
}

class _WifiSettingsReviewViewState extends State<WifiSettingsReviewView> {
  bool isLoading = false;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? LinksysFullScreenSpinner(text: getAppLocalizations(context).processing)
        : BlocBuilder<WifiSettingCubit, WifiSettingState>(
            builder: (context, state) => StyledLinksysPageView(
              title: state.selectedWifiItem.ssid,
              child: LinksysBasicLayout(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LinksysText.descriptionMain(
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
                    const LinksysText.descriptionSub(
                      'Where most of your devices connect.',
                    ),
                    AppPadding(
                      padding: const LinksysEdgeInsets.only(
                          top: AppGapSize.small, bottom: AppGapSize.regular),
                      child: LinksysText.descriptionSub(
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
              padding: const LinksysEdgeInsets.symmetric(
                  vertical: AppGapSize.regular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinksysText.descriptionSub(
                    currentOption.displayTitle,
                  ),
                  const LinksysGap.small(),
                  LinksysText.descriptionSub(
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
        NavigationCubit.of(context).push(EditWifiNamePasswordPath());
        break;
      case WifiSettingOption.securityType6G:
      case WifiSettingOption.securityTypeBelow6G:
      case WifiSettingOption.securityType:
        NavigationCubit.of(context).pushAndWait(EditWifiSecurityPath()
          ..args = {'wifiSettingOption': currentOption});
        break;
      case WifiSettingOption.mode:
        NavigationCubit.of(context).push(EditWifiModePath());
        break;
    }
  }
}
