import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class StaticRoutingListView extends ArgumentsConsumerStatefulView {
  const StaticRoutingListView({
    super.key,
    super.args,
  });

  @override
  ConsumerState<StaticRoutingListView> createState() =>
      _StaticRoutingListViewState();
}

class _StaticRoutingListViewState extends ConsumerState<StaticRoutingListView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staticRoutingProvider);
    return StyledAppPageView(
      title: 'Static Routing',
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppGap.large2(),
          AppListCard(
            padding: const EdgeInsets.all(Spacing.large2),
            title: AppText.labelLarge(
              'Add static route',
            ),
            trailing: const Icon(LinksysIcons.add),
            onTap: () {
              context.pushNamed(RouteNamed.settingsStaticRoutingDetail);
            },
          ),
          const AppGap.large2(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelLarge('Static Route/s'),
              const AppGap.medium(),
              if (state.setting.entries.isNotEmpty)
                ...state.setting.entries.map(
                  (entry) => buildStaticRouteCard(entry),
                )
              else
                AppCard(
                  child: SizedBox(
                    height: 180,
                    child: Center(
                      child: AppText.bodyLarge('You have no Static Route/s'),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildStaticRouteCard(NamedStaticRouteEntry setting) {
    return AppCard(
      showBorder: true,
      padding: const EdgeInsets.all(Spacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelLarge(setting.name),
              AppText.bodyMedium(setting.settings.interface),
              AppText.bodyMedium(
                  'Destination IP address: ${setting.settings.destinationLAN}'),
              AppText.bodyMedium(
                  'Subnet mask: ${NetworkUtils.prefixLengthToSubnetMask(setting.settings.networkPrefixLength)}'),
              AppText.bodyMedium('Gateway: ${setting.settings.gateway ?? ''}'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.bodyLarge(setting.settings.interface),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Spacing.medium),
                child: Icon(LinksysIcons.ethernet),
              ),
              AppIconButton.noPadding(
                icon: LinksysIcons.edit,
                onTap: () {
                  context.pushNamed(
                    RouteNamed.settingsStaticRoutingDetail,
                    extra: {
                      'currentSetting': setting,
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}