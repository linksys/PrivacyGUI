import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// PnP setup complete — shows new WiFi credentials and navigates to dashboard.
class PnpCompleteView extends StatelessWidget {
  final String ssid;
  final String password;

  const PnpCompleteView({
    super.key,
    required this.ssid,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              AppGap.lg(),
              AppText.headlineSmall(loc(context).pnpWiFiReady(ssid)),
              AppGap.xl(),
              if (ssid.isNotEmpty) ...[
                AppText.bodyMedium('${loc(context).wifiName}: $ssid'),
                AppGap.sm(),
              ],
              AppGap.xxxl(),
              AppButton(
                label: loc(context).done,
                onTap: () => context.go(RoutePath.uspDashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
