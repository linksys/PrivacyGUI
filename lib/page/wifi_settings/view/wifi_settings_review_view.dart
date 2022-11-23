import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/wifi_setting/_wifi_setting.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/wifi_settings_path.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

class WifiSettingsReviewView extends ArgumentsStatefulView {
  const WifiSettingsReviewView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _WifiSettingsReviewViewState createState() => _WifiSettingsReviewViewState();
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
        ? FullScreenSpinner(text: getAppLocalizations(context).processing)
        : BlocBuilder<WifiSettingCubit, WifiSettingState>(
            builder: (context, state) => BasePageView(
              child: BasicLayout(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          state.selectedWifiItem.wifiType.displayTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headline3
                              ?.copyWith(
                                  color: Theme.of(context).colorScheme.surface),
                        ),
                        const Spacer(),
                        Switch.adaptive(
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
                    Text(
                      'Where most of your devices connect.',
                      style: Theme.of(context).textTheme.headline4?.copyWith(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      child: Text(
                        '6 GHz, 5 GHz, 2.4 GHz',
                        //TODO: Remove the dummy recent bands
                        style: Theme.of(context).textTheme.headline4?.copyWith(
                            color: Theme.of(context).colorScheme.surface),
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
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentOption.displayTitle,
                    style: Theme.of(context).textTheme.headline3?.copyWith(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                        color: Theme.of(context).colorScheme.surface),
                  ),
                ],
              )),
          const Spacer(),
          Image.asset(
            'assets/images/arrow_point_to_right.png',
            height: 12,
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
