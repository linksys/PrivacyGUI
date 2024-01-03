import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/provider/wifi_setting/_wifi_setting.dart';
import 'package:linksys_app/provider/wifi_setting/wifi_list_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiListProvider);

    return StyledAppPageView(
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Visibility(
          visible: state.isNotEmpty,
          replacement: const AppFullScreenSpinner(),
          child: ListView.separated(
            physics: const ClampingScrollPhysics(),
            itemCount: state.length,
            itemBuilder: (context, index) {
              return index != state.length
                  ? GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        ref
                            .read(wifiSettingProvider.notifier)
                            .selectWifi(state[index]);
                        context.pushNamed(RouteNamed.wifiSettingsReview);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: Spacing.regular),
                            child: AppText.titleMedium(
                              state[index].wifiType.displayTitle,
                            ),
                          ),
                          Row(
                            children: [
                              AppIcon.regular(
                                icon: getCharactersIcons(context).wifiDefault,
                              ),
                              const AppGap.semiSmall(),
                              AppText.bodyMedium(
                                state[index].ssid,
                              ),
                              const Spacer(),
                              AppText.bodyMedium(
                                state[index].isWifiEnabled
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
                  : Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: Spacing.big),
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
