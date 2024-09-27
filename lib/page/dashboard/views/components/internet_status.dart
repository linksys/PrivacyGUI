import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/shimmer.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class InternetConnectionWidget extends ConsumerStatefulWidget {
  const InternetConnectionWidget({super.key});

  @override
  ConsumerState<InternetConnectionWidget> createState() =>
      _InternetConnectionWidgetState();
}

class _InternetConnectionWidgetState
    extends ConsumerState<InternetConnectionWidget> {
  @override
  Widget build(BuildContext context) {
    final isFirstPolling = ref
        .watch(dashboardHomeProvider.select((value) => value.isFirstPolling));
    final wanStatus = ref.watch(nodeWanStatusProvider);
    final isOnline = wanStatus == NodeWANStatus.online;

    final isLoading = ref
        .watch(deviceManagerProvider.select((value) => value.deviceList))
        .isEmpty;
    final geolocationState = ref.watch(geolocationProvider);
    return ShimmerContainer(
      isLoading: isLoading,
      child: AppCard(
        child: Stack(
          children: [
            Visibility(
              visible: isFirstPolling,
              child: AnimatedOpacity(
                opacity: isFirstPolling ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    semanticsLabel: 'internet status spinner',
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: isFirstPolling ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    color: isOnline
                        ? Theme.of(context).colorSchemeExt.green
                        : Theme.of(context).colorScheme.surfaceVariant,
                    size: 16.0,
                  ),
                  const AppGap.small2(),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.titleSmall(
                          isOnline
                              ? loc(context).internetOnline
                              : loc(context).internetOffline,
                        ),
                        if (geolocationState.value?.name.isNotEmpty ==
                            true) ...[
                          const AppGap.small2(),
                          SharedWidgets.geolocationWidget(
                              context,
                              geolocationState.value?.name ?? '',
                              geolocationState.value?.region ?? '',
                              geolocationState.value?.countryCode ?? ''),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
