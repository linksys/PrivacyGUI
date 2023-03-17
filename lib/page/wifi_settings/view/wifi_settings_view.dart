import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/wifi_setting/_wifi_setting.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/route/model/wifi_settings_path.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class WifiSettingsView extends StatefulWidget {
  const WifiSettingsView({Key? key}) : super(key: key);

  @override
  State<WifiSettingsView> createState() => _WifiSettingsViewState();
}

class _WifiSettingsViewState extends State<WifiSettingsView> {
  @override
  void initState() {
    super.initState();

    context.read<WifiSettingCubit>().fetchAllRadioInfo();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WifiSettingCubit, WifiSettingState>(
      builder: (context, state) => StyledLinksysPageView(
        child: LinksysBasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          content: Visibility(
            visible: state.wifiList.isNotEmpty,
            replacement: const LinksysFullScreenSpinner(),
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
                          NavigationCubit.of(context)
                              .push(WifiSettingsReviewPath());
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppPadding(
                              padding: const LinksysEdgeInsets.symmetric(
                                  vertical: AppGapSize.regular),
                              child: LinksysText.tags(
                                state.wifiList[index].wifiType.displayTitle,
                              ),
                            ),
                            Row(
                              children: [
                                AppIcon.regular(
                                  icon: AppTheme.of(context)
                                      .icons
                                      .characters
                                      .wifiDefault,
                                ),
                                const LinksysGap.semiSmall(),
                                LinksysText.descriptionSub(
                                  state.wifiList[index].ssid,
                                ),
                                const Spacer(),
                                LinksysText.descriptionSub(
                                  state.wifiList[index].isWifiEnabled
                                      ? getAppLocalizations(context)
                                          .on
                                          .toUpperCase()
                                      : getAppLocalizations(context)
                                          .off
                                          .toUpperCase(),
                                ),
                                const LinksysGap.regular(),
                                AppIcon(
                                  icon: AppTheme.of(context)
                                      .icons
                                      .characters
                                      .chevronRight,
                                ),
                              ],
                            ),
                            const LinksysGap.regular(),
                          ],
                        ),
                      )
                    : AppPadding(
                        padding: LinksysEdgeInsets.symmetric(
                            vertical: AppGapSize.big),
                        child: InkWell(
                          onTap: () {
                            //TODO: Go to next
                          },
                          child: LinksysText.textLinkSmall(
                            'Learn more about WiFi networks and settings',
                          ),
                        ),
                      );
              },
              separatorBuilder: (context, index) {
                return const Divider(
                    thickness: 1, height: 1, color: MoabColor.dividerGrey);
              },
            ),
          ),
        ),
      ),
    );
  }
}
