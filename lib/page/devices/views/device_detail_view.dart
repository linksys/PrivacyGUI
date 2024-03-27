import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/utils/wifi.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/page/devices/extensions/icon_device_category_ext.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/card/device_info_card.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

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
          title: loc(context).devices,
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
              _extraInfoSection(state),
            ],
          ),
        ),
        const AppGap.regular(),
        Expanded(child: _detailSection(state))
      ],
    );
  }

  Widget _mobileLayout(ExternalDeviceDetailState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _avatarCard(state),
        _detailSection(state),
        _extraInfoSection(state),
      ],
    );
  }

  Widget _avatarCard(ExternalDeviceDetailState state) {
    return AppCard(
      padding: const EdgeInsets.all(Spacing.semiSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 120,
            child: Icon(
              IconDeviceCategoryExt.resloveByName(state.item.icon),
              size: 40,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
            child: Row(
              children: [
                AppText.labelLarge(state.item.name),
                const Spacer(),
                AppIconButton(
                  icon: LinksysIcons.edit,
                  onTap: () {},
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodySmall(loc(context).connectTo),
                const AppGap.small(),
                AppText.labelLarge(state.item.upstreamDevice),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodySmall(loc(context).signalStrength),
                    const AppGap.small(),
                    AppText.labelLarge(
                      _formatEmptyValue('${state.item.signalStrength} dBM'),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(getWifiSignalIconData(
                  context,
                  state.item.isWired ? null : state.item.signalStrength,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(ExternalDeviceDetailState state) {
    return Column(
      children: [
        AppDeviceInfoCard(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.semiBig,
            vertical: Spacing.regular,
          ),
          title: loc(context).wifi,
          description:
              _formatEmptyValue('${state.item.ssid} (${state.item.band})'),
        ),
        AppDeviceInfoCard(
          padding: const EdgeInsets.fromLTRB(
            Spacing.semiBig,
            Spacing.regular,
            Spacing.small,
            Spacing.regular,
          ),
          title: loc(context).ipAddress,
          description: _formatEmptyValue(state.item.ipv4Address),
          trailing: AppTextButton(
            loc(context).reserveDHCP,
            onTap: () {},
          ),
        ),
        AppDeviceInfoCard(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.semiBig,
            vertical: Spacing.regular,
          ),
          title: loc(context).macAddress,
          description: _formatEmptyValue(state.item.macAddress),
        ),
        AppDeviceInfoCard(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.semiBig,
            vertical: Spacing.regular,
          ),
          title: loc(context).ipv6Address,
          description: _formatEmptyValue(state.item.ipv6Address),
        ),
      ],
    );
  }

  Widget _extraInfoSection(ExternalDeviceDetailState state) {
    return AppCard(
        child: Column(
      // crossAxisAlignment: CrossAxisAlignment.start,
      // mainAxisSize: MainAxisSize.min,
      children: [
        AppDeviceInfoCard(
          showBorder: false,
          padding: const EdgeInsets.fromLTRB(
            Spacing.semiSmall,
            0,
            Spacing.semiSmall,
            Spacing.semiSmall,
          ),
          title: loc(context).manufacturer,
          description: _formatEmptyValue(state.item.manufacturer),
        ),
        const Divider(
          height: 8,
          thickness: 1,
        ),
        AppDeviceInfoCard(
          showBorder: false,
          padding: const EdgeInsets.fromLTRB(
            Spacing.semiSmall,
            Spacing.semiSmall,
            Spacing.semiSmall,
            0,
          ),
          title: loc(context).device,
          description: state.item.model,
        ),
      ],
    ));
  }

  String _formatEmptyValue(String? value) {
    return (value == null || value.isEmpty) ? '--' : value;
  }
}
