import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/usp_dashboard/views/dialogs/dhcp_reservation_dialog.dart';
import 'package:privacy_gui/page/usp_dashboard/views/dialogs/port_forwarding_dialog.dart';
import 'package:privacy_gui/page/usp_dashboard/views/dialogs/time_settings_dialog.dart';
import 'package:privacy_gui/page/usp_dashboard/views/dialogs/wifi_channel_dialog.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/page/usp_dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/page/usp_dashboard/providers/usp_dashboard_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Standalone USP Dashboard — displays device info fetched directly via USP.
///
/// This page is completely independent of JNAP polling. It is used as the
/// landing page when USP is the only viable protocol (e.g. JNAP disabled
/// on the router firmware).
class UspDashboardView extends ConsumerWidget {
  const UspDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspDashboardProvider);

    return Scaffold(
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildError(context, ref, error),
          data: (state) => _buildContent(context, ref, state),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium('Unable to load USP data'),
          AppGap.md(),
          AppText.bodyMedium(error.toString()),
          AppGap.xxl(),
          AppButton(
            label: 'Retry',
            onTap: () => ref.invalidate(uspDashboardProvider),
          ),
          AppGap.md(),
          AppButton.text(
            label: 'Logout',
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, UspDashboardState state) {
    final info = state.systemInfo;
    final devices = state.connectedDevices.items;
    final activeDevices = devices.where((d) => d.isActive).toList();
    final inactiveDevices = devices.where((d) => !d.isActive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: SizedBox(
          width: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.headlineSmall('USP Dashboard'),
                  Row(
                    children: [
                      AppIconButton(
                        icon: AppIcon.font(Icons.refresh),
                        onTap: () => ref.invalidate(uspDashboardProvider),
                      ),
                      AppGap.md(),
                      AppButton.text(
                        label: 'Logout',
                        onTap: () => _logout(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
              AppGap.xxl(),

              // Connection status
              AppCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: Theme.of(context)
                              .extension<AppColorScheme>()
                              ?.semanticSuccess ??
                          Colors.green,
                      size: 12,
                    ),
                    AppGap.sm(),
                    AppText.titleSmall('USP Connected'),
                    const Spacer(),
                    AppText.bodyMedium(
                      '${activeDevices.length} device${activeDevices.length != 1 ? 's' : ''} online',
                    ),
                  ],
                ),
              ),
              AppGap.xl(),

              // Device info card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium('Device Information'),
                    AppGap.xl(),
                    _infoRow('Manufacturer', info.manufacturer),
                    _infoRow('Model', info.modelName),
                    _infoRow('Serial Number', info.serialNumber),
                    _infoRow('Hardware Version', info.hardwareVersion),
                    _infoRow('Firmware Version', info.softwareVersion),
                  ],
                ),
              ),
              AppGap.xl(),

              // System stats card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium('System Status'),
                    AppGap.xl(),
                    _infoRow('Uptime', _formatUptime(info.uptime)),
                    _infoRow('CPU Usage', '${info.cpuUsage}%'),
                    _infoRow(
                      'Memory',
                      '${info.freeMemory} / ${info.totalMemory} KB free',
                    ),
                  ],
                ),
              ),
              AppGap.xl(),

              // Connected devices card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.titleMedium('Connected Devices'),
                        AppText.labelLarge(
                          '${activeDevices.length} / ${devices.length}',
                        ),
                      ],
                    ),
                    AppGap.xl(),
                    if (devices.isEmpty)
                      AppText.bodyMedium('No devices found')
                    else ...[
                      // Active devices
                      if (activeDevices.isNotEmpty) ...[
                        AppText.labelLarge('Online'),
                        AppGap.sm(),
                        ...activeDevices.map((d) => _deviceRow(context, d)),
                      ],
                      // Inactive devices
                      if (inactiveDevices.isNotEmpty) ...[
                        if (activeDevices.isNotEmpty) AppGap.lg(),
                        AppText.labelLarge('Offline'),
                        AppGap.sm(),
                        ...inactiveDevices.map((d) => _deviceRow(context, d)),
                      ],
                    ],
                  ],
                ),
              ),
              AppGap.xl(),

              // WiFi Status card
              _buildWifiCard(context, ref, state),
              AppGap.xl(),

              // Time Settings card
              _buildTimeCard(context, ref, state),
              AppGap.xl(),

              // DHCP Reservations card
              _buildDhcpCard(context, ref, state),
              AppGap.xl(),

              // Port Forwarding card
              _buildPortForwardingCard(context, ref, state),
              AppGap.xl(),

              // Protocol info card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium('Protocol'),
                    AppGap.xl(),
                    _infoRow('Transport', 'USP (TR-369 over WebSocket)'),
                    _infoRow('Data Model', 'TR-181 Device:2'),
                    _infoRow('JNAP', 'Unavailable'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WiFi Status card
  // ---------------------------------------------------------------------------

  Widget _buildWifiCard(
      BuildContext context, WidgetRef ref, UspDashboardState state) {
    final radios = state.wifiRadios.items;
    final ssids = state.wifiSsids.items;
    final aps = state.wifiAccessPoints.items;
    final enabledRadios = radios.where((r) => r.enable).length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('WiFi Status'),
              AppText.labelLarge(
                '$enabledRadios / ${radios.length} radios',
              ),
            ],
          ),
          AppGap.xl(),
          // Per-radio sections
          ...radios.map((radio) => _buildRadioSection(context, ref, radio)),
          // Access Points with SSID cross-reference
          if (aps.isNotEmpty) ...[
            AppText.labelLarge('Access Points'),
            AppGap.sm(),
            ...aps.asMap().entries.map(
                  (entry) =>
                      _buildApRow(context, entry.key + 1, entry.value, ssids),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadioSection(
      BuildContext context, WidgetRef ref, WiFiRadio radio) {
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'wifi';
    final successColor =
        Theme.of(context).extension<AppColorScheme>()?.semanticSuccess ??
            Colors.green;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle,
                  size: 8,
                  color: radio.enable
                      ? successColor
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest),
              AppGap.sm(),
              AppText.labelLarge(
                  'Radio: ${radio.operatingFrequencyBand}'),
              const Spacer(),
              AppSwitch(
                value: radio.enable,
                onChanged: isLoading
                    ? null
                    : (value) async {
                        ref.read(uspMutationLoadingProvider.notifier).state =
                            'wifi';
                        try {
                          await ref
                              .read(uspDashboardProvider.notifier)
                              .toggleWifiRadio(radio.instancePath, value);
                        } catch (e) {
                          if (context.mounted) {
                            showFailedSnackBar(context, 'Error: $e');
                          }
                        } finally {
                          ref
                              .read(uspMutationLoadingProvider.notifier)
                              .state = null;
                        }
                      },
              ),
            ],
          ),
          AppGap.sm(),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: AppText.labelLarge('Channel'),
              ),
              Expanded(
                child: AppText.bodyMedium(
                  '${radio.channel}${radio.autoChannelEnable ? ' (Auto)' : ''}',
                ),
              ),
              AppIconButton(
                icon: AppIcon.font(Icons.edit, size: 18),
                onTap: isLoading
                    ? null
                    : () => _showWifiChannelDialog(context, ref, radio),
              ),
            ],
          ),
          _infoRow('Bandwidth', radio.operatingChannelBandwidth),
          _infoRow('Max Bit Rate', '${radio.maxBitRate} Mbps'),
          _infoRow('Standards', radio.supportedStandards),
          _infoRow('Tx Power',
              radio.transmitPower == -1 ? 'Max' : '${radio.transmitPower}'),
        ],
      ),
    );
  }

  Future<void> _showWifiChannelDialog(
      BuildContext context, WidgetRef ref, WiFiRadio radio) async {
    final result = await showDialog<({int channel, bool autoChannel})>(
      context: context,
      builder: (_) => WifiChannelDialog(radio: radio),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspMutationLoadingProvider.notifier).state = 'wifi';
    try {
      await ref.read(uspDashboardProvider.notifier).updateWifiRadioChannel(
            radio.instancePath,
            result.channel,
            result.autoChannel,
          );
      if (context.mounted) showSuccessSnackBar(context, 'Channel updated');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    } finally {
      ref.read(uspMutationLoadingProvider.notifier).state = null;
    }
  }

  Widget _buildApRow(BuildContext context, int index, WiFiAccessPoint ap,
      List<WiFiSsid> ssids) {
    // Cross-reference AP → SSID via ssidReference path
    final ssidName = _resolveSsidName(ap.ssidReference, ssids);
    final label = ssidName ?? 'AP $index';
    final successColor =
        Theme.of(context).extension<AppColorScheme>()?.semanticSuccess ??
            Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: ap.enable
                ? successColor
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          AppGap.sm(),
          Expanded(child: AppText.bodyMedium(label)),
          SizedBox(
            width: 160,
            child: AppText.bodySmall(
              ap.securityModeEnabled,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(
            width: 60,
            child: AppText.bodySmall(
              ap.encryptionMode,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Resolve SSID name from AP's ssidReference path.
  /// ssidReference may or may not have trailing dot — normalize for comparison.
  String? _resolveSsidName(String ssidReference, List<WiFiSsid> ssids) {
    if (ssidReference.isEmpty) return null;
    final normalizedRef = ssidReference.endsWith('.')
        ? ssidReference
        : '$ssidReference.';
    for (final ssid in ssids) {
      if (ssid.instancePath == normalizedRef) {
        return ssid.ssid.isNotEmpty ? ssid.ssid : null;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Time Settings card
  // ---------------------------------------------------------------------------

  Widget _buildTimeCard(
      BuildContext context, WidgetRef ref, UspDashboardState state) {
    final time = state.timeSettings;
    final isSynced = time.status == 'Synchronized';
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'time';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Time Settings'),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSynced
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: AppText.labelSmall(
                      time.status,
                      color: isSynced ? Colors.green : Colors.orange,
                    ),
                  ),
                  AppGap.sm(),
                  AppIconButton(
                    icon: AppIcon.font(Icons.edit, size: 18),
                    onTap: isLoading
                        ? null
                        : () => _showTimeSettingsDialog(context, ref, time),
                  ),
                ],
              ),
            ],
          ),
          AppGap.xl(),
          _infoRow('Current Time', _formatDateTime(time.currentLocalTime)),
          _infoRow('Timezone', time.localTimeZone),
          _infoRow('NTP Server 1', time.ntpServer1),
          if (time.ntpServer2.isNotEmpty)
            _infoRow('NTP Server 2', time.ntpServer2),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: AppText.labelLarge('Time Client'),
              ),
              Expanded(
                child: AppText.bodyMedium(
                    time.enable ? 'Enabled' : 'Disabled'),
              ),
              AppSwitch(
                value: time.enable,
                scale: 0.8,
                onChanged: isLoading
                    ? null
                    : (value) async {
                        ref.read(uspMutationLoadingProvider.notifier).state =
                            'time';
                        try {
                          await ref
                              .read(uspDashboardProvider.notifier)
                              .updateTimeSettings(enable: value);
                        } catch (e) {
                          if (context.mounted) {
                            showFailedSnackBar(context, 'Error: $e');
                          }
                        } finally {
                          ref
                              .read(uspMutationLoadingProvider.notifier)
                              .state = null;
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showTimeSettingsDialog(
      BuildContext context, WidgetRef ref, TimeSettings settings) async {
    final result = await showDialog<TimeSettingsDialogResult>(
      context: context,
      builder: (_) => TimeSettingsDialog(settings: settings),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspMutationLoadingProvider.notifier).state = 'time';
    try {
      await ref.read(uspDashboardProvider.notifier).updateTimeSettings(
            enable: result.enable,
            ntpServer1: result.ntpServer1,
            ntpServer2: result.ntpServer2,
          );
      if (context.mounted) showSuccessSnackBar(context, 'Time settings saved');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    } finally {
      ref.read(uspMutationLoadingProvider.notifier).state = null;
    }
  }

  // ---------------------------------------------------------------------------
  // DHCP Reservations card
  // ---------------------------------------------------------------------------

  Widget _buildDhcpCard(
      BuildContext context, WidgetRef ref, UspDashboardState state) {
    final reservations = state.dhcpReservations.items;
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'dhcp';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('DHCP Reservations'),
              Row(
                children: [
                  AppText.labelLarge('${reservations.length}'),
                  AppGap.sm(),
                  AppIconButton(
                    icon: AppIcon.font(Icons.add, size: 20),
                    onTap: isLoading
                        ? null
                        : () => _showAddDhcpDialog(context, ref),
                  ),
                ],
              ),
            ],
          ),
          AppGap.xl(),
          if (reservations.isEmpty)
            AppText.bodyMedium('No DHCP reservations configured')
          else
            ...reservations
                .map((r) => _buildReservationRow(context, ref, r, isLoading)),
        ],
      ),
    );
  }

  Widget _buildReservationRow(BuildContext context, WidgetRef ref,
      DhcpReservation reservation, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          AppSwitch(
            value: reservation.enable,
            scale: 0.8,
            onChanged: isLoading
                ? null
                : (value) async {
                    ref.read(uspMutationLoadingProvider.notifier).state = 'dhcp';
                    try {
                      await ref
                          .read(uspDashboardProvider.notifier)
                          .toggleDhcpReservation(
                              reservation.instancePath, value);
                    } catch (e) {
                      if (context.mounted) {
                        showFailedSnackBar(context, 'Error: $e');
                      }
                    } finally {
                      ref.read(uspMutationLoadingProvider.notifier).state = null;
                    }
                  },
          ),
          AppGap.sm(),
          Expanded(child: AppText.bodyMedium(reservation.chaddr)),
          SizedBox(
            width: 130,
            child: AppText.bodySmall(
              reservation.yiaddr,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppIconButton(
            icon: AppIcon.font(Icons.delete_outline, size: 18),
            onTap: isLoading
                ? null
                : () => _confirmDeleteDhcp(context, ref, reservation),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDhcpDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String mac, String ip, bool enable})>(
      context: context,
      builder: (_) => const DhcpReservationDialog(),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspMutationLoadingProvider.notifier).state = 'dhcp';
    try {
      await ref.read(uspDashboardProvider.notifier).addDhcpReservation(
            mac: result.mac,
            ip: result.ip,
            enable: result.enable,
          );
      if (context.mounted) showSuccessSnackBar(context, 'Reservation added');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    } finally {
      ref.read(uspMutationLoadingProvider.notifier).state = null;
    }
  }

  Future<void> _confirmDeleteDhcp(
      BuildContext context, WidgetRef ref, DhcpReservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Reservation'),
        content: Text('Delete reservation for ${reservation.chaddr}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(uspMutationLoadingProvider.notifier).state = 'dhcp';
    try {
      await ref
          .read(uspDashboardProvider.notifier)
          .deleteDhcpReservation(reservation.instancePath);
      if (context.mounted) showSuccessSnackBar(context, 'Reservation deleted');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    } finally {
      ref.read(uspMutationLoadingProvider.notifier).state = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Port Forwarding card
  // ---------------------------------------------------------------------------

  Widget _buildPortForwardingCard(
      BuildContext context, WidgetRef ref, UspDashboardState state) {
    final rules = state.portForwarding.items;
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'portForwarding';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Port Forwarding'),
              Row(
                children: [
                  AppText.labelLarge('${rules.length}'),
                  AppGap.sm(),
                  AppIconButton(
                    icon: AppIcon.font(Icons.add, size: 20),
                    onTap: isLoading
                        ? null
                        : () => _showAddPortForwardingDialog(context, ref),
                  ),
                ],
              ),
            ],
          ),
          AppGap.xl(),
          if (rules.isEmpty)
            AppText.bodyMedium('No port forwarding rules configured')
          else
            ...rules.map(
                (r) => _buildPortForwardingRow(context, ref, r, isLoading)),
        ],
      ),
    );
  }

  Widget _buildPortForwardingRow(BuildContext context, WidgetRef ref,
      PortForwardingRule rule, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          AppSwitch(
            value: rule.enabled,
            scale: 0.8,
            onChanged: isLoading
                ? null
                : (value) async {
                    ref.read(uspMutationLoadingProvider.notifier).state =
                        'portForwarding';
                    try {
                      await ref
                          .read(uspDashboardProvider.notifier)
                          .togglePortForwardingRule(
                              rule.instancePath, value);
                    } catch (e) {
                      if (context.mounted) {
                        showFailedSnackBar(context, 'Error: $e');
                      }
                    } finally {
                      ref.read(uspMutationLoadingProvider.notifier).state =
                          null;
                    }
                  },
          ),
          AppGap.sm(),
          Expanded(
            child: AppText.bodyMedium(
              rule.description.isNotEmpty ? rule.description : 'Unnamed rule',
            ),
          ),
          SizedBox(
            width: 180,
            child: AppText.bodySmall(
              '${rule.externalPort} \u2192 ${rule.internalClient}:${rule.internalPort}',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(
            width: 50,
            child: AppText.bodySmall(
              rule.protocol,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppIconButton(
            icon: AppIcon.font(Icons.edit, size: 18),
            onTap: isLoading
                ? null
                : () => _showEditPortForwardingDialog(context, ref, rule),
          ),
          AppIconButton(
            icon: AppIcon.font(Icons.delete_outline, size: 18),
            onTap: isLoading
                ? null
                : () => _confirmDeletePortForwarding(context, ref, rule),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPortForwardingDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showDialog<PortForwardingDialogResult>(
      context: context,
      builder: (_) => const PortForwardingDialog(),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspMutationLoadingProvider.notifier).state = 'portForwarding';
    try {
      await ref.read(uspDashboardProvider.notifier).addPortForwardingRule(
            externalPort: result.externalPort,
            internalPort: result.internalPort,
            internalClient: result.internalClient,
            protocol: result.protocol,
            description: result.description,
            enabled: result.enabled,
          );
      if (context.mounted) showSuccessSnackBar(context, 'Rule added');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    } finally {
      ref.read(uspMutationLoadingProvider.notifier).state = null;
    }
  }

  Future<void> _showEditPortForwardingDialog(
      BuildContext context, WidgetRef ref, PortForwardingRule rule) async {
    final result = await showDialog<PortForwardingDialogResult>(
      context: context,
      builder: (_) => PortForwardingDialog(rule: rule),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspMutationLoadingProvider.notifier).state = 'portForwarding';
    try {
      await ref
          .read(uspDashboardProvider.notifier)
          .updatePortForwardingRule(PortForwardingRuleUpdate(
            instancePath: rule.instancePath,
            enabled: result.enabled,
            externalPort: result.externalPort,
            internalPort: result.internalPort,
            internalClient: result.internalClient,
            protocol: result.protocol,
            description: result.description,
          ));
      if (context.mounted) showSuccessSnackBar(context, 'Rule updated');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    } finally {
      ref.read(uspMutationLoadingProvider.notifier).state = null;
    }
  }

  Future<void> _confirmDeletePortForwarding(
      BuildContext context, WidgetRef ref, PortForwardingRule rule) async {
    final name =
        rule.description.isNotEmpty ? rule.description : 'this rule';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Rule'),
        content: Text('Delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(uspMutationLoadingProvider.notifier).state = 'portForwarding';
    try {
      await ref
          .read(uspDashboardProvider.notifier)
          .deletePortForwardingRule(rule.instancePath);
      if (context.mounted) showSuccessSnackBar(context, 'Rule deleted');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    } finally {
      ref.read(uspMutationLoadingProvider.notifier).state = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Widget _deviceRow(BuildContext context, ConnectedDevice device) {
    final isActive = device.isActive;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: isActive
                ? (Theme.of(context)
                        .extension<AppColorScheme>()
                        ?.semanticSuccess ??
                    Colors.green)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          AppGap.sm(),
          Expanded(
            child: AppText.bodyMedium(
              device.hostName.isNotEmpty ? device.hostName : device.macAddress,
            ),
          ),
          SizedBox(
            width: 130,
            child: AppText.bodySmall(
              device.ipAddress,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: AppText.labelLarge(label),
          ),
          Expanded(child: AppText.bodyMedium(value)),
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(authProvider.notifier).logout();
    context.goNamed(RouteNamed.home);
  }
}
