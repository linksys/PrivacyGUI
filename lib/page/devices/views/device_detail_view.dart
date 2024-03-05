import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/utils/wifi.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/page/devices/extensions/icon_device_category_ext.dart';
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
          title: loc(context).connectTo,
          description: _checkEmptyValue(state.item.upstreamDevice),
          showBorder: false,
          padding: const EdgeInsets.symmetric(vertical: Spacing.semiSmall),
        ),
        const Divider(
          height: 8,
          thickness: 1,
        ),
        AppDeviceInfoCard(
          title: loc(context).wifi,
          description:
              _checkEmptyValue('${state.item.ssid} (${state.item.band})'),
          showBorder: false,
          padding: const EdgeInsets.symmetric(vertical: Spacing.semiSmall),
        ),
        const Divider(
          height: 8,
          thickness: 1,
        ),
        AppDeviceInfoCard(
          title: loc(context).signalStrength,
          description: _checkEmptyValue('${state.item.signalStrength} dBM'),
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
          title: loc(context).manufacturer,
          description: _checkEmptyValue(state.item.manufacturer),
        ),
      ],
    ));
  }

  Widget _detailCard(ExternalDeviceDetailState state) {
    return Column(
      children: [
        AppDeviceInfoCard(
          title: loc(context).deviceName,
          description: _checkEmptyValue(state.item.name),
          trailing: AppIconButton(
            icon: Symbols.edit,
            onTap: () {},
          ),
        ),
        AppDeviceInfoCard(
          title: loc(context).ipAddress,
          description: _checkEmptyValue(state.item.ipv4Address),
          trailing: AppTextButton(
            loc(context).reserveDHCP,
            onTap: () {},
          ),
        ),
        AppDeviceInfoCard(
          title: loc(context).macAddress,
          description: _checkEmptyValue(state.item.macAddress),
        ),
        AppDeviceInfoCard(
          title: loc(context).ipv6Address,
          description: _checkEmptyValue(state.item.ipv6Address),
        ),
      ],
    );
  }

  String _checkEmptyValue(String? value) {
    if (value == null) {
      return '--';
    }
    if (value.isEmpty) {
      return '--';
    }
    return value;
  }
}
