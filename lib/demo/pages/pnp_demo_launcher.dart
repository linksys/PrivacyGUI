import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Demo-only landing page for PnP flow path selection.
///
/// Displays a grid of cards, each representing a different PnP entry point.
/// Tapping a card sets the appropriate [PnpPhase] and navigates to the
/// corresponding route so testers can jump directly to any stage.
class PnpDemoLauncher extends ConsumerWidget {
  const PnpDemoLauncher({super.key});

  static const _mockWifiConfig = PnpWifiConfig(
    ssid: 'Linksys-Demo',
    password: 'DemoPass123',
    originalSsid: 'Linksys00166',
    originalPassword: 'factory-pw',
    ssidInstancePaths: ['Device.WiFi.SSID.1'],
    accessPointInstancePaths: ['Device.WiFi.AccessPoint.1'],
    guestSsidInstancePaths: ['Device.WiFi.SSID.3'],
    guestAccessPointInstancePaths: ['Device.WiFi.AccessPoint.3'],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = _buildEntries(context, ref);

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      title: 'PnP Demo Launcher',
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.headlineSmall('PnP Demo Launcher'),
            AppGap.sm(),
            AppText.bodyMedium(
              'Select a PnP path to demo. Each card jumps directly to that stage.',
            ),
            AppGap.lg(),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 160,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final e = entries[index];
                  return _DemoCard(
                    icon: e.icon,
                    title: e.title,
                    subtitle: e.subtitle,
                    onTap: e.onTap,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_DemoEntry> _buildEntries(BuildContext context, WidgetRef ref) {
    return [
      _DemoEntry(
        icon: Icons.play_arrow_rounded,
        title: 'Full Flow',
        subtitle: 'Start from internet check (assumes logged in)',
        onTap: () {
          ref.invalidate(pnpProvider);
          ref.read(pnpProvider.notifier).startPostLoginFlow();
          context.go(RoutePath.pnp);
        },
      ),
      _DemoEntry(
        icon: Icons.wifi,
        title: 'WiFi Wizard',
        subtitle: 'WiFi name & password setup',
        onTap: () {
          ref.invalidate(pnpProvider);
          ref.read(pnpProvider.notifier).setDemoPhase(
                WizardConfiguring(wifiConfig: _mockWifiConfig),
              );
          context.go('${RoutePath.pnp}/${RoutePath.pnpConfig}');
        },
      ),
      _DemoEntry(
        icon: Icons.qr_code,
        title: 'WiFi Ready (QR)',
        subtitle: 'Completion page + QR code',
        onTap: () {
          ref.invalidate(pnpProvider);
          ref.read(pnpProvider.notifier).setDemoPhase(
                WizardWifiReady(
                  ssid: _mockWifiConfig.ssid,
                  password: _mockWifiConfig.password,
                ),
              );
          context.go('${RoutePath.pnp}/${RoutePath.pnpConfig}');
        },
      ),
      _DemoEntry(
        icon: Icons.wifi_off,
        title: 'No Internet',
        subtitle: 'Troubleshooter hub',
        onTap: () {
          ref.invalidate(pnpProvider);
          ref.read(pnpProvider.notifier).setDemoPhase(
                const NoInternet(ssid: 'Linksys-Demo'),
              );
          context.go(RoutePath.pnpNoInternetConnection);
        },
      ),
      _DemoEntry(
        icon: Icons.power_off,
        title: 'Modem Restart',
        subtitle: 'Unplug → Lights off → Wait',
        onTap: () {
          ref.invalidate(pnpProvider);
          ref.read(pnpProvider.notifier).setDemoPhase(
                const NoInternet(),
              );
          context.go(
            '${RoutePath.pnpNoInternetConnection}/${RoutePath.pnpUnplugModem}',
          );
        },
      ),
      _DemoEntry(
        icon: Icons.settings_ethernet,
        title: 'ISP Settings',
        subtitle: 'DHCP / PPPoE / Static IP',
        onTap: () {
          ref.invalidate(pnpProvider);
          ref.read(pnpProvider.notifier).setDemoPhase(
                const NoInternet(),
              );
          context.go(
            '${RoutePath.pnpNoInternetConnection}/${RoutePath.pnpIspTypeSelection}',
          );
        },
      ),
      _DemoEntry(
        icon: Icons.sync,
        title: 'Reconnect',
        subtitle: 'WiFi reconnection waiting',
        onTap: () {
          ref.invalidate(pnpProvider);
          ref.read(pnpProvider.notifier).setDemoPhase(
                WizardNeedsReconnect(
                  newSsid: _mockWifiConfig.ssid,
                  newPassword: _mockWifiConfig.password,
                ),
              );
          context.go('${RoutePath.pnp}/${RoutePath.pnpConfig}');
        },
      ),
    ];
  }
}

class _DemoEntry {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DemoEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _DemoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DemoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon.font(icon,
                  size: 28, color: Theme.of(context).colorScheme.primary),
              AppGap.sm(),
              AppText.titleSmall(title),
              AppGap.xs(),
              AppText.bodySmall(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
