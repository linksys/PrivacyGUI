import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/wifi.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/page/devices/extensions/icon_device_category_ext.dart';
import 'package:linksys_app/page/topology/_topology.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/card/device_info_card.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import 'package:material_symbols_icons/symbols.dart';

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
        return StyledAppPageView(
          padding: const EdgeInsets.only(),
          title: 'Devices',
          scrollable: true,
          child: AppBasicLayout(
            content: ResponsiveLayout(
                desktop: _desktopLayout(state), mobile: _mobileLayout(state)),
          ),
        );
      },
    );
  }

  Widget _desktopLayout(ExternalDeviceDetailState state) {
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatarCard(state),
              const AppGap.regular(),
              _connectionCard(state),
              const AppGap.regular(),
              _unitCard(state),
              const Spacer(),
            ],
          ),
        ),
        const AppGap.regular(),
        Expanded(child: _detailCard(state))
      ],
    );
  }

  Widget _mobileLayout(ExternalDeviceDetailState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _avatarCard(state),
        _detailCard(state),
        _connectionCard(state),
        _unitCard(state),
      ],
    );
  }

  Widget _avatarCard(ExternalDeviceDetailState state) {
    return AppCard(
      child: SizedBox(
        height: 160,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AppIconButton(
                icon: Symbols.edit,
                onTap: () {},
              ),
            ),
            Expanded(
              child: Icon(
                IconDeviceCategoryExt.resloveByName(state.item.icon),
                size: 40,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _connectionCard(ExternalDeviceDetailState state) {
    return AppCard(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppDeviceInfoCard(
          title: 'Connected to',
          description: state.item.upstreamDevice,
          showBorder: false,
          padding: const EdgeInsets.symmetric(vertical: Spacing.semiSmall),
        ),
        const Divider(
          height: 8,
          thickness: 1,
        ),
        AppDeviceInfoCard(
          title: 'Signal Strength',
          description: '${state.item.signalStrength} dBM',
          showBorder: false,
          padding: const EdgeInsets.symmetric(vertical: Spacing.semiSmall),
          trailing: Icon(getWifiSignalIconData(
            context,
            state.item.isWired ? null : state.item.signalStrength,
          )),
        ),
      ],
    ));
  }

  Widget _unitCard(ExternalDeviceDetailState state) {
    return AppCard(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppDeviceInfoCard(
          showBorder: false,
          padding: const EdgeInsets.symmetric(vertical: Spacing.semiSmall),
          title: 'Manufacturer',
          description: state.item.manufacturer,
        ),
      ],
    ));
  }

  Widget _detailCard(ExternalDeviceDetailState state) {
    return Column(
      children: [
        AppDeviceInfoCard(
          title: 'Device Name',
          description: state.item.name,
          trailing: AppIconButton(
            icon: Symbols.edit,
            onTap: () {},
          ),
        ),
        AppDeviceInfoCard(
          title: 'IP Address',
          description: state.item.ipv4Address,
          trailing: AppTextButton(
            'Reserve DHCP',
            onTap: () {},
          ),
        ),
        AppDeviceInfoCard(
          title: 'MAC Address',
          description: state.item.macAddress,
        ),
        AppDeviceInfoCard(
          title: 'IPv6 Address',
          description: state.item.ipv6Address,
        ),
      ],
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
    return Icon(
      IconDeviceCategoryExt.resloveByName(iconName),
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
        AppDeviceInfoCard(
          title: getAppLocalizations(context).device_name,
          description: state.item.name,
          onTap: () {
            context.pushNamed(RouteNamed.changeDeviceName);
          },
        ),
        const Divider(height: 8),
        AppSimplePanel(
          title: getAppLocalizations(context).node_detail_label_connected_to,
          description: state.item.isOnline
              ? '${state.item.upstreamDevice} [${state.item.signalStrength}]'
              : getAppLocalizations(context).offline,
          onTap: state.item.isOnline
              ? () {
                  ref.read(topologySelectedIdProvider.notifier).state =
                      state.item.deviceId;
                  context.pushNamed(RouteNamed.settingsNodes);
                }
              : null,
        ),
      ],
    );
  }

  Widget _wifiSection(ExternalDeviceDetailState state) {
    return state.item.isOnline
        ? Column(
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
          )
        : const Center();
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
