import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/semantic.dart';
import 'package:privacy_gui/utils.dart';
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
  final String _tag = 'static-routing-list';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staticRoutingProvider);
    return StyledAppPageView(
      title: loc(context).staticRouting,
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppGap.large2(),
          AppListCard(
            padding: const EdgeInsets.all(Spacing.large2),
            title: AppText.labelLarge(
              loc(context).addStaticRoute,
              identifier:
                  semanticIdentifier(tag: _tag, description: 'addStaticRoute'),
            ),
            identifier:
                semanticIdentifier(tag: _tag, description: 'addStaticRoute'),
            semanticLabel: loc(context).addStaticRoute,
            trailing: Semantics(
                identifier: semanticIdentifier(
                    tag: _tag, description: 'addStaticRoute-icon'),
                label: '${loc(context).addStaticRoute} icon',
                child: const Icon(LinksysIcons.add)),
            onTap: () {
              context.pushNamed(RouteNamed.settingsStaticRoutingDetail);
            },
          ),
          const AppGap.large2(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelLarge(
                loc(context).staticRoute,
                identifier:
                    semanticIdentifier(tag: _tag, description: 'staticRoute'),
              ),
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
                      child: AppText.bodyLarge(
                        loc(context).noStaticRoutes,
                        identifier: semanticIdentifier(
                            tag: _tag, description: 'noStaticRoutes'),
                      ),
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

  Widget editingSection(NamedStaticRouteEntry setting) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        AppText.bodyLarge(
          setting.settings.interface,
          identifier: semanticIdentifier(tag: _tag, description: 'interface'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.medium),
          child: Semantics(
              identifier:
                  semanticIdentifier(tag: _tag, description: 'ethernet-icon'),
              label: 'ethernet icon',
              child: const Icon(LinksysIcons.ethernet)),
        ),
        AppIconButton.noPadding(
          identifier: semanticIdentifier(tag: _tag, description: 'edit'),
          semanticLabel: 'edit',
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
    );
  }

  Widget infoSection(NamedStaticRouteEntry setting) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge(
          setting.name,
          identifier: semanticIdentifier(tag: _tag, description: 'name'),
        ),
        AppText.bodyMedium(
          getInterfaceTitle(setting.settings.interface),
          identifier: semanticIdentifier(tag: _tag, description: 'interface'),
        ),
        Wrap(
          spacing: Spacing.small3,
          children: [
            AppText.labelLarge(
              loc(context).destinationIPAddress,
              identifier: semanticIdentifier(
                  tag: _tag, description: 'destinationIPAddress'),
            ),
            AppText.bodyMedium(
              setting.settings.destinationLAN,
              identifier:
                  semanticIdentifier(tag: _tag, description: 'destination-lan'),
            ),
          ],
        ),
        Wrap(
          spacing: Spacing.small3,
          children: [
            AppText.labelLarge(
              loc(context).subnetMask,
              identifier: semanticIdentifier(
                  tag: _tag, description: 'subnetMask'),
            ),
            AppText.bodyMedium(
              NetworkUtils.prefixLengthToSubnetMask(
                  setting.settings.networkPrefixLength),
              identifier: semanticIdentifier(
                  tag: _tag, description: 'subnetMask-value'),
            ),
          ],
        ),
        Wrap(
          spacing: Spacing.small3,
          children: [
            AppText.labelLarge(
              loc(context).gateway,
              identifier: semanticIdentifier(
                  tag: _tag, description: 'gateway'),
            ),
            AppText.bodyMedium(
              setting.settings.gateway ?? '',
              identifier: semanticIdentifier(
                  tag: _tag, description: 'gateway-value'),
            ),
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
      _ => loc(context).lanWireless,
    };
  }
}
