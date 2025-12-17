import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_route_entry_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
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
    return StyledAppPageView.withSliver(
      title: loc(context).staticRouting,
      scrollable: true,
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppGap.large2(),
          AppListCard(
            padding: const EdgeInsets.all(Spacing.large2),
            title: AppText.labelLarge(
              loc(context).addStaticRoute,
            ),
            trailing: const Icon(
              LinksysIcons.add,
              semanticLabel: 'add',
            ),
            onTap: () {
              context.pushNamed(RouteNamed.settingsStaticRoutingRule);
            },
          ),
          const AppGap.large2(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelLarge(loc(context).staticRoute),
              const AppGap.medium(),
              if (state.current.entries.isNotEmpty)
                ...state.current.entries.map(
                  (entry) => buildStaticRouteCard(entry),
                )
              else
                AppCard(
                  child: SizedBox(
                    height: 180,
                    child: Center(
                      child: AppText.bodyLarge(loc(context).noStaticRoutes),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildStaticRouteCard(StaticRouteEntryUIModel setting) {
    return AppCard(
      showBorder: true,
      padding: const EdgeInsets.all(Spacing.medium),
      margin: const EdgeInsets.only(bottom: Spacing.small2),
      child: ResponsiveLayout.isMobileLayout(context)
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoSection(setting),
                const AppGap.small2(),
                editingSection(setting),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                infoSection(setting),
                editingSection(setting),
              ],
            ),
    );
  }

  Widget editingSection(StaticRouteEntryUIModel setting) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        AppText.bodyLarge(getInterfaceTitle(setting.interface)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Spacing.medium),
          child: Icon(
            LinksysIcons.ethernet,
            semanticLabel: 'ethernet',
          ),
        ),
        AppIconButton.noPadding(
          icon: LinksysIcons.edit,
          onTap: () {
            context.pushNamed(
              RouteNamed.settingsStaticRoutingRule,
              extra: {
                'edit': setting,
              },
            );
          },
        ),
      ],
    );
  }

  Widget infoSection(StaticRouteEntryUIModel setting) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge(setting.name),
        AppText.bodyMedium(getInterfaceTitle(setting.interface)),
        Wrap(
          spacing: Spacing.small3,
          children: [
            AppText.labelLarge(loc(context).destinationIPAddress),
            AppText.bodyMedium(setting.destinationIP),
          ],
        ),
        Wrap(
          spacing: Spacing.small3,
          children: [
            AppText.labelLarge(loc(context).subnetMask),
            AppText.bodyMedium(setting.subnetMask),
          ],
        ),
        Wrap(
          spacing: Spacing.small3,
          children: [
            AppText.labelLarge(loc(context).gateway),
            AppText.bodyMedium(
                setting.gateway.isEmpty ? '--' : setting.gateway),
          ],
        ),
      ],
    );
  }

  String getInterfaceTitle(String interface) {
    final resolved = RoutingSettingInterface.resolve(interface);
    return switch (resolved) {
      RoutingSettingInterface.lan => loc(context).lanWireless,
      RoutingSettingInterface.internet =>
        RoutingSettingInterface.internet.value,
    };
  }
}
