import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/qr_code.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';

import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/util/export_selector/export_base.dart'
    if (dart.library.io) 'package:privacy_gui/util/export_selector/export_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/export_selector/export_web.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DashboardWiFiGrid extends ConsumerStatefulWidget {
  const DashboardWiFiGrid({super.key});

  @override
  ConsumerState<DashboardWiFiGrid> createState() => _DashboardWiFiGridState();
}

class _DashboardWiFiGridState extends ConsumerState<DashboardWiFiGrid> {
  Map<String, bool> toolTipVisible = {};

  @override
  Widget build(BuildContext context) {
    final items =
        ref.watch(dashboardHomeProvider.select((value) => value.wifis));
    final isLoading =
        (ref.watch(pollingProvider).value?.isReady ?? false) == false;
    final crossAxisCount = context.isMobileLayout ? 1 : 2;
    const mainSpacing = AppSpacing.lg;
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
                mainAxisSpacing: AppSpacing.lg,
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
                  final visibilityKey =
                      '${item.ssid}${item.radios.join()}${item.isGuest}';

                  final isVisible = toolTipVisible[visibilityKey] ?? false;
                  return WiFiCard(
                    tooltipVisible: isVisible,
                    item: item,
                    index: index,
                    canBeDisabled: canBeDisabled,
                    onTooltipVisibilityChanged: (visible) {
                      setState(() {
                        // Hide all other tooltips when showing one
                        if (visible) {
                          for (var key in toolTipVisible.keys) {
                            toolTipVisible[key] = false;
                          }
                        }
                        toolTipVisible[visibilityKey] = visible;
                      });
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
  final DashboardWiFiUIModel item;
  final int index;
  final bool canBeDisabled;
  final bool tooltipVisible;
  final ValueChanged<bool>? onTooltipVisibilityChanged;

  const WiFiCard({
    Key? key,
    required this.item,
    required this.index,
    required this.canBeDisabled,
    this.tooltipVisible = false,
    this.onTooltipVisibilityChanged,
  }) : super(key: key);

  @override
  ConsumerState<WiFiCard> createState() => _WiFiCardState();
}

class _WiFiCardState extends ConsumerState<WiFiCard> {
  final qrBtnKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      return AppCard(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xxl, horizontal: AppSpacing.xxl),
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
                  value: widget.item.isEnabled,
                  onChanged: widget.item.isGuest ||
                          !widget.item.isEnabled ||
                          widget.canBeDisabled
                      ? (value) => _handleWifiToggled(value)
                      : null,
                ),
              ],
            ),
            AppGap.sm(),
            FittedBox(
              child: AppText.titleMedium(
                widget.item.ssid,
              ),
            ),
            AppGap.sm(),
            Stack(
              alignment: Alignment.center,
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    children: [
                      AppIcon.font(
                        AppFontIcons.devices,
                      ),
                      AppGap.sm(),
                      AppText.labelLarge(
                        loc(context)
                            .nDevices(widget.item.numOfConnectedDevices),
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
    return AppTooltip(
      position: AxisDirection.left,
      visible: widget.item.isEnabled ? widget.tooltipVisible : false,
      maxWidth: 200,
      maxHeight: 200,
      padding: EdgeInsets.zero,
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
        onEnter: widget.item.isEnabled
            ? (_) => widget.onTooltipVisibilityChanged?.call(true)
            : null,
        onExit: (_) => widget.onTooltipVisibilityChanged?.call(false),
        child: SizedBox(
          width: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                child: AppIconButton.small(
                  key: qrBtnKey,
                  styleVariant: ButtonStyleVariant.text,
                  icon: AppIcon.font(AppFontIcons.qrCode),
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
    final result = await showSwitchWifiDialog();
    if (result) {
      // If the widget is already disposed, do nothing even if the user has confirmed the change
      if (!mounted) return;
      showSpinnerDialog(context);
      final wifiProvider = ref.read(wifiBundleProvider.notifier);
      await wifiProvider.fetch();
      if (widget.item.isGuest) {
        wifiProvider.setWiFiEnabled(value);
        await wifiProvider.save().then((value) {
          if (mounted) {
            context.pop();
          }
        }).catchError((error, stackTrace) {
          if (!mounted) return;
          // Show RouterNotFound alert for the JNAP side effect error
          showRouterNotFoundAlert(
            context,
            ref,
            onComplete: () => context.pop(),
          );
        }, test: (error) => error is ServiceSideEffectError).onError(
            (error, statckTrace) {
          if (mounted) {
            // Just dismiss the spinner for other unexpected errors
            context.pop();
          }
        });
      } else {
        await wifiProvider
            .saveToggleEnabled(radios: widget.item.radios, enabled: value)
            .then((value) {
          if (mounted) {
            context.pop();
          }
        }).catchError((error, stackTrace) {
          if (!mounted) return;
          // Show RouterNotFound alert for the JNAP side effect error
          showRouterNotFoundAlert(
            context,
            ref,
            onComplete: () => context.pop(),
          );
        }, test: (error) => error is ServiceSideEffectError).onError(
                (error, statckTrace) {
          if (mounted) {
            // Just dismiss the spinner for other unexpected errors
            context.pop();
          }
        });
      }
    }
  }

  Future<bool> showSwitchWifiDialog() async {
    return await showSimpleAppDialog(
      context,
      title: loc(context).wifiListSaveModalTitle,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium(loc(context).wifiListSaveModalDesc),
            if (!widget.item.isGuest && widget.item.isEnabled)
              ..._disableGuestBandWarning(),
            AppGap.lg(),
            AppText.bodyMedium(loc(context).doYouWantToContinue),
          ],
        ),
      ),
      actions: [
        AppButton.text(label: loc(context).cancel, onTap: () => context.pop()),
        AppButton.text(label: loc(context).ok, onTap: () => context.pop(true)),
      ],
    );
  }

  List<Widget> _disableGuestBandWarning() {
    final guestWifiItem =
        ref.read(dashboardHomeProvider).wifis.firstWhere((e) => e.isGuest);
    // There will be only one radio item for each wifi card
    final currentRadio = widget.item.radios.first;
    return guestWifiItem.isEnabled
        ? [
            AppGap.sm(),
            AppText.labelMedium(
              loc(context).disableBandWarning(
                  WifiRadioBand.getByValue(currentRadio).bandName),
            )
          ]
        : [];
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
          AppButton.text(
              label: loc(context).close,
              onTap: () {
                context.pop();
              }),
          AppButton.text(
              label: loc(context).downloadQR,
              onTap: () async {
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
}
