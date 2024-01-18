import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/wifi.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/provider/devices/external_device_detail_provider.dart';
import 'package:linksys_app/provider/devices/external_device_detail_state.dart';
import 'package:linksys_app/provider/devices/topology_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/avatars/device_avatar.dart';

import 'package:linksys_widgets/widgets/page/layout/profile_header_layout.dart';

class DeviceDetailView extends ArgumentsConsumerStatefulView {
  const DeviceDetailView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<DeviceDetailView> createState() => _DeviceDetailViewState();
}

class _DeviceDetailViewState extends ConsumerState<DeviceDetailView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(externalDeviceDetailProvider);
    return LayoutBuilder(
      builder: (context, constraint) {
        return AppProfileHeaderLayout(
          expandedHeight: constraint.maxHeight / 3,
          collaspeTitle: state.item.name,
          onCollaspeBackTap: () {
            context.pop();
          },
          background: Theme.of(context).colorScheme.background,
          header: Column(
            children: [
              LinksysAppBar(
                leading: AppIconButton(
                  icon: getCharactersIcons(context).arrowLeft,
                  onTap: () {
                    context.pop();
                  },
                ),
              ),
              const Spacer(),
              _header(state),
            ],
          ),
          body: Column(
            children: [
              _content(state),
            ],
          ),
        );
      },
    );
  }

  Widget _header(ExternalDeviceDetailState state) {
    return Container(
      alignment: Alignment.center,
      decoration:
          BoxDecoration(color: Theme.of(context).colorScheme.background),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final result = await context
                  .pushNamed<String?>(RouteNamed.changeDeviceAvatar);
              if (result != null) {
                // update property
              }
            },
            child: _deviceAvatar(state.item.icon),
          ),
          const AppGap.regular(),
          // const AppGap.extraBig(),
          // _deviceStatus(state),
          const AppGap.semiSmall(),
        ],
      ),
    );
  }

  Widget _deviceAvatar(String iconName) {
    return AppDeviceAvatar.extraLarge(
      borderColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      image: CustomTheme.of(context).images.devices.getByName(iconName),
    );
  }

  Widget _deviceStatus(ExternalDeviceDetailState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Container(
              height: Spacing.extraBig,
              width: Spacing.extraBig,
              alignment: Alignment.center,
              child: Image(
                image: CustomTheme.of(context).images.devices.getByName(
                      state.item.upstreamIcon,
                    ),
                height: 120 * 0.75,
                width: 120 * 0.75,
              ),
            ),
            AppText.labelLarge(
              state.item.upstreamDevice,
            ),
          ],
        ),
        InkWell(
          onTap: () {
            context.pushNamed(
              RouteNamed.settingsNodes,
              extra: {
                'selectedDeviceId': state.item.deviceId,
              },
            );
          },
          child: Column(
            children: [
              Container(
                height: Spacing.extraBig,
                width: Spacing.extraBig,
                alignment: Alignment.center,
                child: AppIcon.big(
                  icon: getWifiSignalIconData(
                    context,
                    state.item.isWired ? null : state.item.signalStrength,
                  ),
                ),
              ),
              AppText.labelLarge(
                getWifiSignalLevel(
                        state.item.isWired ? null : state.item.signalStrength)
                    .displayTitle,
              ),
            ],
          ),
        ),
        const Center(),
      ],
    );
  }

  Widget _content(ExternalDeviceDetailState state) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, viewportConstraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.semiBig,
                      ),
                      child: Column(
                        children: [
                          _generalSection(state),
                          const AppGap.big(),
                          _wifiSection(state),
                          const AppGap.big(),
                          _detailSection(state),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _generalSection(ExternalDeviceDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.big(),
        AppSimplePanel(
          title: getAppLocalizations(context).device_name,
          description: state.item.name,
          onTap: () {
            context.pushNamed(RouteNamed.changeDeviceName);
          },
        ),
        const Divider(height: 8),
        AppSimplePanel(
          title: getAppLocalizations(context).node_detail_label_connected_to,
          description:
              '${state.item.upstreamDevice} [${state.item.signalStrength}]',
          onTap: () {
            ref.read(topologySelectedIdProvider.notifier).state =
                state.item.deviceId;
            context.pushNamed(RouteNamed.settingsNodes);
          },
        ),
      ],
    );
  }

  Widget _wifiSection(ExternalDeviceDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelSmall(
          getAppLocalizations(context).wifi_all_capital,
        ),
        const AppGap.small(),
        AppSimplePanel(
          title: getAppLocalizations(context).ip_address,
          description: state.item.ipv4Address,
        ),
        const Divider(height: 8),
        AppSimplePanel(
          title: getAppLocalizations(context).mac_address,
          description: state.item.macAddress,
        ),
        const Divider(height: 8),
        if (state.item.ipv6Address.isNotEmpty) ...[
          AppSimplePanel(
            title: getAppLocalizations(context).ipv6_address,
            description: state.item.ipv6Address,
          ),
          const Divider(height: 8),
        ],
      ],
    );
  }

  Widget _detailSection(ExternalDeviceDetailState state) {
    final model = state.item.model;
    final manufacturer = state.item.manufacturer;
    final operatingSystem = state.item.operatingSystem;
    if ('$model$manufacturer$operatingSystem'.isEmpty) {
      return const Center();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.semiSmall(),
        AppText.labelSmall(
          getAppLocalizations(context).details_all_capital,
        ),
        if (manufacturer.isNotEmpty) ...[
          AppSimplePanel(
            title: getAppLocalizations(context).manufacturer,
            description: manufacturer,
          ),
          const Divider(height: 8),
        ],
        if (model.isNotEmpty) ...[
          AppSimplePanel(
            title: getAppLocalizations(context).model,
            description: model,
          ),
          const Divider(height: 8),
        ],
        if (operatingSystem.isNotEmpty) ...[
          AppSimplePanel(
            title: getAppLocalizations(context).operating_system,
            description: operatingSystem,
          ),
          const Divider(height: 8),
        ],
      ],
    );
  }
}
