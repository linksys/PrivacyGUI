import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/wifi_setting/_wifi_setting.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/route/model/wifi_settings_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class WifiSettingsView extends ConsumerStatefulWidget {
  const WifiSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<WifiSettingsView> createState() => _WifiSettingsViewState();
}

class _WifiSettingsViewState extends ConsumerState<WifiSettingsView> {
  @override
  void initState() {
    super.initState();

    context.read<WifiSettingCubit>().fetchAllRadioInfo();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WifiSettingCubit, WifiSettingState>(
      builder: (context, state) => StyledAppPageView(
        child: AppBasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          content: Visibility(
            visible: state.wifiList.isNotEmpty,
            replacement: const AppFullScreenSpinner(),
            child: ListView.separated(
              physics: const ClampingScrollPhysics(),
              itemCount: state.wifiList.length + 1,
              itemBuilder: (context, index) {
                return index != state.wifiList.length
                    ? GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          context
                              .read<WifiSettingCubit>()
                              .selectWifi(state.wifiList[index]);
                          ref
                              .read(navigationsProvider.notifier)
                              .push(WifiSettingsReviewPath());
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppPadding(
                              padding: const AppEdgeInsets.symmetric(
                                  vertical: AppGapSize.regular),
                              child: AppText.tags(
                                state.wifiList[index].wifiType.displayTitle,
                              ),
                            ),
                            Row(
                              children: [
                                AppIcon.regular(
                                  icon: getCharactersIcons(context).wifiDefault,
                                ),
                                const AppGap.semiSmall(),
                                AppText.descriptionSub(
                                  state.wifiList[index].ssid,
                                ),
                                const Spacer(),
                                AppText.descriptionSub(
                                  state.wifiList[index].isWifiEnabled
                                      ? getAppLocalizations(context)
                                          .on
                                          .toUpperCase()
                                      : getAppLocalizations(context)
                                          .off
                                          .toUpperCase(),
                                ),
                                const AppGap.regular(),
                                AppIcon(
                                  icon:
                                      getCharactersIcons(context).chevronRight,
                                ),
                              ],
                            ),
                            const AppGap.regular(),
                          ],
                        ),
                      )
                    : AppPadding(
                        padding: const AppEdgeInsets.symmetric(
                            vertical: AppGapSize.big),
                        child: InkWell(
                          onTap: () {
                            //TODO: Go to next
                          },
                          child: const AppText.textLinkSmall(
                            'Learn more about WiFi networks and settings',
                          ),
                        ),
                      );
              },
              separatorBuilder: (context, index) {
                return const Divider(
                  thickness: 1,
                  height: 1,
                  color: ConstantColors.basePrimaryGray,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
