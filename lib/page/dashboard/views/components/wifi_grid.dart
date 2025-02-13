import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/qr_code.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacy_gui/util/export_selector/export_base.dart'
    if (dart.library.io) 'package:privacy_gui/util/export_selector/export_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/export_selector/export_web.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:super_tooltip/super_tooltip.dart';

class DashboardWiFiGrid extends ConsumerStatefulWidget {
  const DashboardWiFiGrid({super.key});

  @override
  ConsumerState<DashboardWiFiGrid> createState() => _DashboardWiFiGridState();
}

class _DashboardWiFiGridState extends ConsumerState<DashboardWiFiGrid> {
  Map<String, SuperTooltipController> toolTipControllers = {};

  @override 
  void dispose() {
    toolTipControllers.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final items =
        ref.watch(dashboardHomeProvider.select((value) => value.wifis));
    final isLoading = ref.watch(deviceManagerProvider).deviceList.isEmpty;

    final crossAxisCount = ResponsiveLayout.isMobileLayout(context) ? 1 : 2;
    final mainSpacing = ResponsiveLayout.columnPadding(context);
    const itemHeight = 176.0;
    final mainAxisCount = (items.length / crossAxisCount);

    final enabledWiFiCount =
        items.where((e) => !e.isGuest && e.isEnabled).length;
    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;
    final canBeDisabled = enabledWiFiCount > 1 || hasLanPort;

    return SizedBox(
      height: isLoading
          ? itemHeight * 2 + mainSpacing * 1
          : mainAxisCount * itemHeight +
              ((mainAxisCount == 0 ? 1 : mainAxisCount) - 1) * mainSpacing +
              100,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: Spacing.medium,
          crossAxisSpacing: mainSpacing,
          // childAspectRatio: (3 / 2),
          mainAxisExtent: itemHeight,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: isLoading ? 4 : items.length,
        itemBuilder: (context, index) {
          final item = isLoading ? null : items[index];
          return SizedBox(
              height: itemHeight,
              child: _wifiCard(
                  context,
                  ref,
                  item ??
                      DashboardWiFiItem(
                          ssid: 'ssid',
                          password: 'password',
                          radios: const ['6GHz'],
                          isGuest: false,
                          isEnabled: true,
                          numOfConnectedDevices: 7),
                  index,
                  canBeDisabled));
        },
      ),
    );
  }

  Widget _wifiCard(BuildContext context, WidgetRef ref, DashboardWiFiItem item,
      int index, bool canBeDisabled) {
    final controller = toolTipControllers[
            '${item.ssid}${item.radios.join()}${item.isGuest}'] ??
        SuperTooltipController();
    toolTipControllers['${item.ssid}${item.radios.join()}${item.isGuest}'] =
        controller;
    return AppCard(
      padding: const EdgeInsets.symmetric(
          vertical: Spacing.large2, horizontal: Spacing.large2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium(
                item.isGuest
                    ? loc(context).guestWifi
                    : loc(context).wifiBand(item.radios
                        .map((e) => e.replaceAll('RADIO_', ''))
                        .join('/')),
              ),
              AppSwitch(
                semanticLabel: item.isGuest
                    ? 'guest'
                    : item.radios
                        .map((e) => e.replaceAll('RADIO_', ''))
                        .join('/'),
                value: item.isEnabled,
                onChanged: item.isGuest || !item.isEnabled || canBeDisabled
                    ? (value) async {
                        if (item.isGuest) {
                          showSpinnerDialog(context);
                          final wifiProvider =
                              ref.read(wifiListProvider.notifier);
                          await wifiProvider.fetch();
                          wifiProvider.setWiFiEnabled(value);
                          await wifiProvider
                              .save()
                              .then((value) => context.pop());
                        } else {
                          showSpinnerDialog(context);
                          final wifiProvider =
                              ref.read(wifiListProvider.notifier);
                          await wifiProvider.fetch();
                          await wifiProvider
                              .saveToggleEnabled(
                                  radios: item.radios, enabled: value)
                              .then((value) => context.pop());
                        }
                      }
                    : null,
              ),
            ],
          ),
          const AppGap.medium(),
          AppText.titleMedium(
            item.ssid,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const AppGap.medium(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LinksysIcons.devices,
                    semanticLabel: 'devices',
                  ),
                  const AppGap.medium(),
                  AppText.labelLarge(
                    loc(context).nDevices(item.numOfConnectedDevices),
                  ),
                ],
              ),
              SuperTooltip(
                hideTooltipOnTap: true,
                minimumOutsideMargin: 8,
                popupDirection: TooltipDirection.up,
                showBarrier: false,
                controller: controller,
                bottom: 200,
                content: SizedBox(
                  width: 200,
                  child: MouseRegion(
                    onExit: (e) async {
                      if (controller.isVisible) {
                        await controller.hideTooltip();
                      }
                    },
                    child: Container(
                      color: Colors.white,
                      height: 200,
                      width: 200,
                      child: QrImageView(
                        data: WiFiCredential(
                          ssid: item.ssid,
                          password: item.password,
                          type: SecurityType
                              .wpa, //TODO: The security type is fixed for now
                        ).generate(),
                      ),
                    ),
                  ),
                ),
                child: MouseRegion(
                  onEnter: (e) async {
                    await controller.showTooltip();
                  },
                  onExit: (e) async {
                    if (controller.isVisible) {
                      await controller.hideTooltip();
                    }
                  },
                  child: AppIconButton.noPadding(
                      icon: LinksysIcons.qrCode,
                      semanticLabel: 'share',
                      onTap: () {
                        _showWiFiShareModal(context, item);
                      }),
                ),
              )
            ],
          )
        ],
      ),
      onTap: () {
        context.pushNamed(RouteNamed.menuIncredibleWiFi,
            extra: {'wifiIndex': index, 'guest': item.isGuest});
      },
    );
  }

  _showWiFiShareModal(BuildContext context, DashboardWiFiItem item) {
    showSimpleAppDialog(context,
        title: loc(context).shareWiFi,
        content: SingleChildScrollView(
          child: WiFiShareDetailView(
            ssid: item.ssid,
            password: item.password,
          ),
        ),
        actions: [
          AppTextButton(loc(context).close, onTap: () {
            context.pop();
          }, color: Theme.of(context).colorScheme.onSurface),
          AppTextButton(loc(context).downloadQR, onTap: () async {
            createWiFiQRCode(WiFiCredential(
                    ssid: item.ssid,
                    password: item.password,
                    type: SecurityType.wpa))
                .then((imageBytes) {
              exportFileFromBytes(
                  fileName: 'share_wifi_${item.ssid}.png',
                  utf8Bytes: imageBytes);
            });
          }),
        ]);
  }
}
