import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/demo/providers/demo_pnp.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Demo-only landing page for PnP flow path selection.
///
/// Displays a grid of cards, each representing a different PnP entry point.
/// Tapping a card picks the [PnpPhase] the next run starts at and navigates
/// into the flow, whose entry applies it (`demoPnpStartPhaseProvider`), so
/// testers can jump directly to any stage.
///
/// The launcher never touches `pnpProvider` itself (#1511 P3): it is
/// `autoDispose` and held by the PnP shell, so from out here there is no flow
/// to set a phase on.
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
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.headlineSmall('PnP Demo Launcher'),
            AppGap.sm(),
            AppText.bodyMedium(
              'Select a PnP path to demo. Each card jumps directly to that stage.',
            ),
            AppGap.lg(),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
          ],
        ),
      ),
    );
  }

  /// The troubleshooting tree's caller, for the three entries into it (#1511 P1).
  /// Nothing else to set up: the tree has state of its own, which starts on the
  /// hub's "no internet" and reads the WAN for its forms itself.
  static const _asPnp = {
    TroubleshootingCaller.param: TroubleshootingCaller.pnp
  };

  List<_DemoEntry> _buildEntries(BuildContext context, WidgetRef ref) {
    /// Starts the next run at [phase] and enters the flow at [location]. The
    /// wizard's own screens are all drawn by the wizard page, so a phase past
    /// the form enters there directly; the form itself enters at `/pnp`, whose
    /// shell opens the wizard when the flow reaches it.
    void startAt(PnpPhase phase, String location) {
      ref.read(demoPnpStartPhaseProvider.notifier).state = phase;
      context.go(location);
    }

    const wizard = '${RoutePath.pnp}/${RoutePath.pnpConfig}';

    return [
      _DemoEntry(
        icon: Icons.dashboard,
        title: 'USP Dashboard',
        subtitle: 'Skip PnP, go directly to dashboard (Mascot)',
        onTap: () {
          context.go(RoutePath.uspDashboard);
        },
      ),
      _DemoEntry(
        icon: Icons.play_arrow_rounded,
        title: 'Full Flow',
        subtitle: 'Start from internet check (assumes logged in)',
        // The entry starts the flow, as it does after a real login.
        onTap: () => context.go(RoutePath.pnp),
      ),
      _DemoEntry(
        icon: Icons.wifi,
        title: 'WiFi Wizard',
        subtitle: 'WiFi name & password setup',
        onTap: () => startAt(
          const WizardConfiguring(wifiConfig: _mockWifiConfig),
          RoutePath.pnp,
        ),
      ),
      _DemoEntry(
        icon: Icons.qr_code,
        title: 'WiFi Ready (QR)',
        subtitle: 'Completion page + QR code',
        onTap: () => startAt(
          WizardWifiReady(
            ssid: _mockWifiConfig.ssid,
            password: _mockWifiConfig.password,
          ),
          wizard,
        ),
      ),
      _DemoEntry(
        icon: Icons.wifi_off,
        title: 'No Internet',
        subtitle: 'Troubleshooter hub',
        onTap: () => context.goNamed(
          RouteNamed.pnpNoInternetConnection,
          pathParameters: _asPnp,
        ),
      ),
      _DemoEntry(
        icon: Icons.power_off,
        title: 'Modem Restart',
        // Three-step sequence, not a two-part mapping, so MapsToRow does not
        // fit; U+2013 is covered by every font in the declared set.
        subtitle: 'Unplug – Lights off – Wait',
        onTap: () => context.goNamed(
          RouteNamed.pnpUnplugModem,
          pathParameters: _asPnp,
        ),
      ),
      _DemoEntry(
        icon: Icons.settings_ethernet,
        title: 'ISP Settings',
        subtitle: 'DHCP / PPPoE / Static IP',
        onTap: () => context.goNamed(
          RouteNamed.pnpIspTypeSelection,
          pathParameters: _asPnp,
        ),
      ),
      _DemoEntry(
        icon: Icons.sync,
        title: 'Reconnect',
        subtitle: 'WiFi reconnection waiting',
        onTap: () => startAt(
          WizardNeedsReconnect(
            newSsid: _mockWifiConfig.ssid,
            newPassword: _mockWifiConfig.password,
          ),
          wizard,
        ),
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
