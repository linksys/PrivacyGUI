import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

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
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Visibility(
                visible: isFirstPolling,
                child: AnimatedOpacity(
                  opacity: isFirstPolling ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: isFirstPolling ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 500),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: isOnline
                              ? Theme.of(context).colorSchemeExt.green
                              : Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        const AppGap.medium(),
                        AppText.titleMedium(
                          isOnline
                              ? loc(context).internetOnline
                              : loc(context).internetOffline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
