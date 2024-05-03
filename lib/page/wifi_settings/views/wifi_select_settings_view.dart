import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/administration/mac_filtering/views/mac_filtering_view.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/wifi_settings/_wifi_settings.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

enum _WiFiSubMenus {
  wifi,
  guest,
  advanced,
  filtering,
  ;
}

class WifiSelectSettingsView extends ConsumerStatefulWidget {
  const WifiSelectSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<WifiSelectSettingsView> createState() =>
      _WifiSelectSettingsViewState();
}

class _WifiSelectSettingsViewState
    extends ConsumerState<WifiSelectSettingsView> {
  int _selectMenuIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
        title: _subMenuLabel(_WiFiSubMenus.values[_selectMenuIndex]),
        menuWidget: ListView.builder(
            shrinkWrap: true,
            itemCount: _WiFiSubMenus.values.length,
            itemBuilder: (context, index) {
              return AppCard(
                showBorder: false,
                onTap: () {
                  setState(() {
                    _selectMenuIndex = index;
                  });
                },
                child: AppText.labelLarge(
                  _subMenuLabel(_WiFiSubMenus.values[index]),
                  color: index == _selectMenuIndex
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              );
            }),
        child: _content(_WiFiSubMenus.values[_selectMenuIndex]));
  }

  String _subMenuLabel(_WiFiSubMenus sub) => switch (sub) {
        _WiFiSubMenus.wifi => loc(context).wifi,
        _WiFiSubMenus.guest => loc(context).guestWifi,
        _WiFiSubMenus.advanced => loc(context).advanced,
        _WiFiSubMenus.filtering => loc(context).macFiltering,
      };

  Widget _content(_WiFiSubMenus sub) => switch (sub) {
        _WiFiSubMenus.wifi => _wifiContent(),
        _WiFiSubMenus.guest => Center(),
        _WiFiSubMenus.advanced => const WifiAdvancedSettingsView(),
        _WiFiSubMenus.filtering => const MacFilteringView(),
      };

  Widget _wifiContent() {
    final state = ref.watch(wifiListProvider);

    return AppBasicLayout(
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
                            getWifiTypeTitle(context, state[index].wifiType),
                          ),
                        ),
                        Row(
                          children: [
                            AppText.bodyMedium(
                              state[index].ssid,
                            ),
                            const Spacer(),
                            AppText.bodyMedium(
                              state[index].isEnabled
                                  ? getAppLocalizations(context)
                                      .on
                                      .toUpperCase()
                                  : getAppLocalizations(context)
                                      .off
                                      .toUpperCase(),
                            ),
                            const AppGap.regular(),
                            const Icon(
                              LinksysIcons.chevronRight,
                            ),
                          ],
                        ),
                        const AppGap.regular(),
                      ],
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: Spacing.big),
                    child: InkWell(
                      onTap: null,
                      child: AppText.labelLarge(
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
    );
  }
}
