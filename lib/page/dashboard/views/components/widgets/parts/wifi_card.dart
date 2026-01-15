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
import 'package:collection/collection.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_device_category.dart';
import 'package:privacy_gui/page/instant_device/extensions/icon_device_category_ext.dart';

/// A card widget displaying WiFi network information with toggle and share.
class WiFiCard extends ConsumerStatefulWidget {
  final DashboardWiFiUIModel item;
  final int index;
  final bool canBeDisabled;
  final bool tooltipVisible;
  final ValueChanged<bool>? onTooltipVisibilityChanged;
  final EdgeInsetsGeometry? padding;
  final bool isCompact;

  const WiFiCard({
    super.key,
    required this.item,
    required this.index,
    required this.canBeDisabled,
    this.tooltipVisible = false,
    this.padding,
    this.onTooltipVisibilityChanged,
    this.isCompact = false,
    this.isExpanded = false,
  });

  final bool isExpanded;

  @override
  ConsumerState<WiFiCard> createState() => _WiFiCardState();
}

class _WiFiCardState extends ConsumerState<WiFiCard> {
  final qrBtnKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactCard(context);
    }

    return LayoutBuilder(builder: (context, constraint) {
      if (widget.isExpanded) {
        return _buildExpandedCard(context);
      }
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

  Widget _buildCompactCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      onTap: () {
        context.pushNamed(RouteNamed.menuIncredibleWiFi,
            extra: {'wifiIndex': widget.index, 'guest': widget.item.isGuest});
      },
      child: Row(
        children: [
          // Band Icon
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi,
                size: 16, color: Theme.of(context).colorScheme.primary),
          ),
          AppGap.sm(),
          // Band Name
          Expanded(
            child: AppText.labelMedium(
              widget.item.isGuest
                  ? loc(context).guestWifi
                  : widget.item.radios
                      .map((e) => e.replaceAll('RADIO_', ''))
                      .join('/'),
            ),
          ),
          // Switch
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
    );
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

  Widget _buildExpandedCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      onTap: () {
        context.pushNamed(RouteNamed.menuIncredibleWiFi,
            extra: {'wifiIndex': widget.index, 'guest': widget.item.isGuest});
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: SSID + Toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleLarge(
                      widget.item.ssid,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppGap.xs(),
                    AppText.labelMedium(
                      widget.item.isGuest
                          ? loc(context).guestWifi
                          : loc(context).wifiBand(widget.item.radios
                              .map((e) => e.replaceAll('RADIO_', ''))
                              .join('/')),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              AppGap.md(),
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
          const Spacer(),

          // Middle: Password + Device Preview
          if (widget.item.isEnabled) ...[
            _ExpandedPasswordSection(
              password: widget.item.password,
              onShare: () => _showWiFiShareModal(context),
            ),
            const Spacer(),
            _ExpandedDevicePreview(item: widget.item),
          ],
        ],
      ),
    );
  }
}

class _ExpandedPasswordSection extends StatefulWidget {
  final String password;
  final VoidCallback onShare;

  const _ExpandedPasswordSection({
    required this.password,
    required this.onShare,
  });

  @override
  State<_ExpandedPasswordSection> createState() =>
      _ExpandedPasswordSectionState();
}

class _ExpandedPasswordSectionState extends State<_ExpandedPasswordSection> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.key,
              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          AppGap.sm(),
          Expanded(
            child: AppText.bodyMedium(
              _isVisible ? widget.password : '••••••••',
              // TextStyle support removed from AppText, using default bodyMedium style
            ),
          ),
          AppIconButton.small(
            styleVariant: ButtonStyleVariant.text,
            icon: Icon(_isVisible ? Icons.visibility_off : Icons.visibility,
                size: 18),
            onTap: () => setState(() => _isVisible = !_isVisible),
          ),
          AppIconButton.small(
            styleVariant: ButtonStyleVariant.text,
            icon: const Icon(Icons.copy, size: 18),
            onTap: () {
              // Copy to clipboard
              // Clipboard.setData(ClipboardData(text: widget.password));
              // TODO: Add toast
            },
          ),
          Container(
            height: 20,
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
          AppIconButton.small(
            styleVariant: ButtonStyleVariant.text,
            icon: const Icon(Icons.qr_code, size: 18),
            onTap: widget.onShare,
          ),
        ],
      ),
    );
  }
}

class _ExpandedDevicePreview extends ConsumerWidget {
  final DashboardWiFiUIModel item;

  const _ExpandedDevicePreview({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.numOfConnectedDevices == 0) {
      return Row(
        children: [
          Icon(Icons.devices,
              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          AppGap.sm(),
          AppText.bodySmall(
            'No devices connected',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      );
    }

    // Get devices for this network
    final devices = ref
        .watch(deviceManagerProvider)
        .externalDevices
        .where((d) {
          if (!d.isOnline()) return false;

          final isCorrectNetwork = item.isGuest
              ? d.connectedWifiType == WifiConnectionType.guest
              : d.connectedWifiType == WifiConnectionType.main;

          if (!isCorrectNetwork) return false;

          if (item.isGuest) return true;

          // Filter by band matching item.radios
          return d.connections.any((conn) {
            final interface = d.knownInterfaces
                ?.firstWhereOrNull((i) => i.macAddress == conn.macAddress);
            final band = interface?.band;
            if (band == null) return false;

            return item.radios.any((r) {
              if (r.contains('2.4') && band.contains('2.4')) return true;
              if (r.contains('5') && band.contains('5')) return true;
              if (r.contains('6') && band.contains('6')) return true;
              return false;
            });
          });
        })
        .take(3)
        .toList();

    return Row(
      children: [
        Icon(Icons.devices,
            size: 16, color: Theme.of(context).colorScheme.primary),
        AppGap.sm(),
        AppText.labelMedium(
          loc(context).nDevices(item.numOfConnectedDevices),
          color: Theme.of(context).colorScheme.primary,
        ),
        AppGap.md(),
        Expanded(
          child: SizedBox(
            height: 24,
            child: Stack(
              children: [
                for (var i = 0; i < devices.length; i++)
                  Positioned(
                    left: i * 16.0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Center(
                          child: Icon(
                        devices[i].iconData,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                    ),
                  ),
                if (item.numOfConnectedDevices > 3)
                  Positioned(
                    left: 3 * 16.0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: AppText.labelSmall(
                          '+${item.numOfConnectedDevices - 3}',
                          // style: const TextStyle(fontSize: 10), // removed style
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

extension LinksysDeviceIconExt on LinksysDevice {
  IconData get iconData {
    final userDeviceType = properties
        .firstWhereOrNull((p) => p.name == 'userDeviceType' || p.name == 'icon')
        ?.value;

    if (userDeviceType != null) {
      return IconDeviceCategoryExt.resolveByName(userDeviceType);
    }

    // Check if it is a phone
    if (friendlyName?.toLowerCase().contains('phone') ?? false) {
      return AppFontIcons.smartPhone;
    }

    return AppFontIcons.genericDevice;
  }
}
