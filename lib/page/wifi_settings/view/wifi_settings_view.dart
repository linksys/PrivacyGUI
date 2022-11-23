import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/wifi_setting/_wifi_setting.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/wifi_settings_path.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';
import 'package:linksys_moab/util/logger.dart';

class WifiSettingsView extends StatefulWidget {
  const WifiSettingsView({Key? key}) : super(key: key);

  @override
  _WifiSettingsViewState createState() => _WifiSettingsViewState();
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
      builder: (context, state) => BasePageView(
        child: BasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          content: ListView.separated(
            physics: const ClampingScrollPhysics(),
            itemCount: state.wifiList.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  context
                      .read<WifiSettingCubit>()
                      .selectWifi(state.wifiList[index]);
                  NavigationCubit.of(context).push(WifiSettingsReviewPath());
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      child: Text(
                        state.wifiList[index].wifiType.displayTitle,
                        style: Theme.of(context).textTheme.headline4?.copyWith(
                            color: Theme.of(context).colorScheme.surface),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          state.wifiList[index].ssid,
                          style: Theme.of(context)
                              .textTheme
                              .headline2
                              ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary),
                        ),
                        const Spacer(),
                        Text(
                          state.wifiList[index].isWifiEnabled
                              ? getAppLocalizations(context).on.toUpperCase()
                              : getAppLocalizations(context).off.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .headline2
                              ?.copyWith(
                                  color: Theme.of(context).colorScheme.surface),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Image.asset(
                          'assets/images/arrow_point_to_right.png',
                          height: 12,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) {
              return const Divider(
                  thickness: 1, height: 1, color: MoabColor.dividerGrey);
            },
          ),
          footer: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: SimpleTextButton(
              text: 'Learn more about WiFi networks and settings',
              onPressed: () {
                //TODO: Go to next
              },
            ),
          ),
        ),
      ),
    );
  }
}
