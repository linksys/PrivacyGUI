import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/qr_code.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacy_gui/util/export_selector/export_base.dart'
    if (dart.library.io) 'package:privacy_gui/util/export_selector/export_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/export_selector/export_web.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';
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
      child: isLoading
          ? AppCard(padding: EdgeInsets.zero, child: LoadingTile())
          : GridView.builder(
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
                createWiFiCard() {
                  final item = items[index];
                  final controllerKey =
                      '${item.ssid}${item.radios.join()}${item.isGuest}';

                  SuperTooltipController? controller;
                  controller = toolTipControllers[controllerKey] ??
                      SuperTooltipController();
                  toolTipControllers[controllerKey] = controller;
                  return WiFiCard(
                    toolTipController: controller,
                    item: item,
                    index: index,
                    canBeDisabled: canBeDisabled,
                    beforeShowWiFiTip: () async {
                      for (var ctrl in toolTipControllers.values) {
                        if (ctrl.isVisible) {
                          await ctrl.hideTooltip();
                        }
                      }
                    },
                  );
                }

                return SizedBox(
                    height: itemHeight,
                    child: isLoading
                        ? AppCard(child: LoadingTile())
                        : createWiFiCard());
              },
            ),
    );
  }
}

class WiFiCard extends ConsumerStatefulWidget {
  final DashboardWiFiItem item;
  final int index;
  final bool canBeDisabled;
  final Future<void> Function()? beforeShowWiFiTip;
  final SuperTooltipController? toolTipController;

  const WiFiCard({
    Key? key,
    required this.item,
    required this.index,
    required this.canBeDisabled,
    this.beforeShowWiFiTip,
    this.toolTipController,
  }) : super(key: key);

  @override
  ConsumerState<WiFiCard> createState() => _WiFiCardState();
}

class _WiFiCardState extends ConsumerState<WiFiCard> {
  SuperTooltipController? _toolTipController;
  final qrBtnKey = GlobalKey();
  Completer? _completer;

  @override
  void initState() {
    super.initState();
    _toolTipController = widget.toolTipController;
  }

  @override
  void dispose() {
    // _toolTipController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
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
                  widget.item.isGuest
                      ? loc(context).guestWifi
                      : loc(context).wifiBand(widget.item.radios
                          .map((e) => e.replaceAll('RADIO_', ''))
                          .join('/')),
                ),
                AppSwitch(
                  semanticLabel: widget.item.isGuest
                      ? 'guest'
                      : widget.item.radios
                          .map((e) => e.replaceAll('RADIO_', ''))
                          .join('/'),
                  value: widget.item.isEnabled,
                  onChanged: widget.item.isGuest ||
                          !widget.item.isEnabled ||
                          widget.canBeDisabled
                      ? (value) => _handleWifiToggled(value)
                      : null,
                ),
              ],
            ),
            const AppGap.small2(),
            FittedBox(
              child: AppText.titleMedium(
                widget.item.ssid,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const AppGap.small2(),
            Stack(
              alignment: Alignment.center,
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    children: [
                      const Icon(
                        LinksysIcons.devices,
                        semanticLabel: 'devices',
                      ),
                      const AppGap.small2(),
                      AppText.labelLarge(
                        loc(context)
                            .nDevices(widget.item.numOfConnectedDevices),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _buildTooltip(context)),
              ],
            )
          ],
        ),
        onTap: () {
          context.pushNamed(RouteNamed.menuIncredibleWiFi,
              extra: {'wifiIndex': widget.index, 'guest': widget.item.isGuest});
        },
      );
    });
  }

  Widget _buildTooltip(BuildContext context) {
    return SuperTooltip(
      arrowTipDistance: 0,
      popupDirection: TooltipDirection.left,
      overlayDimensions: EdgeInsets.zero,
      bubbleDimensions: EdgeInsets.zero,
      showBarrier: false,
      controller: _toolTipController,
      content: Container(
        color: Colors.white,
        height: 200,
        width: 200,
        child: QrImageView(
          data: WiFiCredential(
            ssid: widget.item.ssid,
            password: widget.item.password,
            type: SecurityType.wpa,
          ).generate(),
        ),
      ),
      child: MouseRegion(
        onHover: (e) async {
          if (!widget.item.isEnabled) {
            return;
          }
          await _completer?.future;
          final widgetPosition = _getWidgetPosition();
          final rect = Rect.fromCenter(
              center: widgetPosition + const Offset(20, 20),
              width: 40,
              height: 40);

          if (_toolTipController?.isVisible == false &&
              rect.contains(e.position)) {
            _completer = Completer();
            await widget.beforeShowWiFiTip?.call();
            await _toolTipController?.showTooltip();
            _completer?.complete();
          }
        },
        onExit: (e) async {
          await _completer?.future;
          if (_toolTipController?.isVisible == true) {
            await _toolTipController?.hideTooltip();
          }
        },
        child: SizedBox(
          width: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                child: AppIconButton(
                  key: qrBtnKey,
                  icon: LinksysIcons.qrCode,
                  semanticLabel: 'share',
                  onTap: () {
                    _showWiFiShareModal(context);
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleWifiToggled(bool value) async {
    showSpinnerDialog(context);
    final wifiProvider = ref.read(wifiListProvider.notifier);
    await wifiProvider.fetch();
    if (widget.item.isGuest) {
      wifiProvider.setWiFiEnabled(value);
      await wifiProvider.save().then((value) => context.pop()).catchError(
          (error, stackTrace) {
        // Show RouterNotFound alert for the JNAP side effect error
        showRouterNotFoundAlert(context, ref, onComplete: () => context.pop());
      }, test: (error) => error is JNAPSideEffectError).onError(
          (error, statckTrace) {
        // Just dismiss the spinner for other unexpected errors
        context.pop();
      });
    } else {
      await wifiProvider
          .saveToggleEnabled(radios: widget.item.radios, enabled: value)
          .then((value) => context.pop())
          .catchError((error, stackTrace) {
        // Show RouterNotFound alert for the JNAP side effect error
        showRouterNotFoundAlert(context, ref, onComplete: () => context.pop());
      }, test: (error) => error is JNAPSideEffectError).onError(
              (error, statckTrace) {
        // Just dismiss the spinner for other unexpected errors
        context.pop();
      });
    }
  }

  void _showWiFiShareModal(BuildContext context) {
    showSimpleAppDialog(context,
        title: loc(context).shareWiFi,
        content: SingleChildScrollView(
          child: WiFiShareDetailView(
            ssid: widget.item.ssid,
            password: widget.item.password,
          ),
        ),
        actions: [
          AppTextButton(loc(context).close, onTap: () {
            context.pop();
          }, color: Theme.of(context).colorScheme.onSurface),
          AppTextButton(loc(context).downloadQR, onTap: () async {
            createWiFiQRCode(WiFiCredential(
                    ssid: widget.item.ssid,
                    password: widget.item.password,
                    type: SecurityType.wpa))
                .then((imageBytes) {
              exportFileFromBytes(
                  fileName: 'share_wifi_${widget.item.ssid}.png',
                  utf8Bytes: imageBytes);
            });
          }),
        ]);
  }

  Offset _getWidgetPosition() {
    final RenderBox renderBox =
        qrBtnKey.currentContext?.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(Offset.zero);
  }
}
