import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:privacy_gui/util/export_selector/export_selector.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A card widget displaying WiFi network information with toggle and share.
class WiFiCard extends ConsumerStatefulWidget {
  final DashboardWiFiUIModel item;
  final int index;
  final bool canBeDisabled;
  final bool tooltipVisible;
  final ValueChanged<bool>? onTooltipVisibilityChanged;

  const WiFiCard({
    super.key,
    required this.item,
    required this.index,
    required this.canBeDisabled,
    this.tooltipVisible = false,
    this.padding,
    this.onTooltipVisibilityChanged,
  });

  final EdgeInsetsGeometry? padding;

  @override
  ConsumerState<WiFiCard> createState() => _WiFiCardState();
}

class _WiFiCardState extends ConsumerState<WiFiCard> {
  final qrBtnKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      return AppCard(
        padding: widget.padding ??
            const EdgeInsets.symmetric(
                vertical: AppSpacing.xxl, horizontal: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            AppGap.sm(),
            _buildSSID(),
            AppGap.sm(),
            _buildFooter(context),
          ],
        ),
        onTap: () {
          context.pushNamed(RouteNamed.menuIncredibleWiFi,
              extra: {'wifiIndex': widget.index, 'guest': widget.item.isGuest});
        },
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: AppText.bodyMedium(
            widget.item.isGuest
                ? loc(context).guestWifi
                : loc(context).wifiBand(widget.item.radios
                    .map((e) => e.replaceAll('RADIO_', ''))
                    .join('/')),
          ),
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
    );
  }

  Widget _buildSSID() {
    return FittedBox(
      child: AppText.titleMedium(widget.item.ssid),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            children: [
              AppIcon.font(AppFontIcons.devices),
              AppGap.sm(),
              Flexible(
                child: AppText.labelLarge(
                  loc(context).nDevices(widget.item.numOfConnectedDevices),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _buildTooltip(context),
        ),
      ],
    );
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
                  onTap: () => _showWiFiShareModal(context),
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
      if (!mounted) return;
      showSpinnerDialog(context);
      final wifiProvider = ref.read(wifiBundleProvider.notifier);
      await wifiProvider.fetch();

      if (widget.item.isGuest) {
        await _saveGuestWifi(wifiProvider, value);
      } else {
        await _saveMainWifi(wifiProvider, value);
      }
    }
  }

  Future<void> _saveGuestWifi(
      WifiBundleNotifier wifiProvider, bool value) async {
    wifiProvider.setWiFiEnabled(value);
    await wifiProvider.save().then((_) {
      if (mounted) context.pop();
    }).catchError((error, stackTrace) {
      if (!mounted) return;
      showRouterNotFoundAlert(context, ref, onComplete: () => context.pop());
    }, test: (error) => error is ServiceSideEffectError).onError((error, _) {
      if (mounted) context.pop();
    });
  }

  Future<void> _saveMainWifi(
      WifiBundleNotifier wifiProvider, bool value) async {
    await wifiProvider
        .saveToggleEnabled(radios: widget.item.radios, enabled: value)
        .then((_) {
      if (mounted) context.pop();
    }).catchError((error, stackTrace) {
      if (!mounted) return;
      showRouterNotFoundAlert(context, ref, onComplete: () => context.pop());
    }, test: (error) => error is ServiceSideEffectError).onError((error, _) {
      if (mounted) context.pop();
    });
  }

  Future<bool> showSwitchWifiDialog() async {
    return await showSimpleAppDialog(
      context,
      title: loc(context).wifiListSaveModalTitle,
      scrollable: true,
      content: Column(
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
      actions: [
        AppButton.text(label: loc(context).cancel, onTap: () => context.pop()),
        AppButton.text(label: loc(context).ok, onTap: () => context.pop(true)),
      ],
    );
  }

  List<Widget> _disableGuestBandWarning() {
    final guestWifiItem =
        ref.read(dashboardHomeProvider).wifis.firstWhere((e) => e.isGuest);
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
    showSimpleAppDialog(
      context,
      title: loc(context).shareWiFi,
      scrollable: true,
      content: WiFiShareDetailView(
        ssid: widget.item.ssid,
        password: widget.item.password,
      ),
      actions: [
        AppButton.text(label: loc(context).close, onTap: () => context.pop()),
        AppButton.text(
          label: loc(context).downloadQR,
          onTap: () async {
            createWiFiQRCode(WiFiCredential(
              ssid: widget.item.ssid,
              password: widget.item.password,
              type: SecurityType.wpa,
            )).then((imageBytes) {
              exportFileFromBytes(
                fileName: 'share_wifi_${widget.item.ssid}.png',
                utf8Bytes: imageBytes,
              );
            });
          },
        ),
      ],
    );
  }
}
