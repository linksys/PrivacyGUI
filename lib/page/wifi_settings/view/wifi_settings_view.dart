import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/provider/wifi_setting/_wifi_setting.dart';
import 'package:linksys_app/route/constants.dart';
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

    ref.read(wifiSettingProvider.notifier).fetchAllRadioInfo();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiSettingProvider);

    return StyledAppPageView(
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
                        ref
                            .read(wifiSettingProvider.notifier)
                            .selectWifi(state.wifiList[index]);
                        context.pushNamed(RouteNamed.wifiSettingsReview);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppPadding(
                            padding: const AppEdgeInsets.symmetric(
                                vertical: AppGapSize.regular),
                            child: AppText.titleMedium(
                              state.wifiList[index].wifiType.displayTitle,
                            ),
                          ),
                          Row(
                            children: [
                              AppIcon.regular(
                                icon: getCharactersIcons(context).wifiDefault,
                              ),
                              const AppGap.semiSmall(),
                              AppText.bodyMedium(
                                state.wifiList[index].ssid,
                              ),
                              const Spacer(),
                              AppText.bodyMedium(
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
                                icon: getCharactersIcons(context).chevronRight,
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
                        child: const AppText.labelLarge(
                          'Learn more about WiFi networks and settings',
                        ),
                      ),
                    );
            },
            separatorBuilder: (context, index) {
              return const Divider(
                thickness: 1,
                height: 1,
              );
            },
          ),
        ),
      ),
    );
  }
}
