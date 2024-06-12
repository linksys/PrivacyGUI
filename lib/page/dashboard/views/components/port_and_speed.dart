import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/shimmer.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

class DashboardHomePortAndSpeed extends ConsumerWidget {
  const DashboardHomePortAndSpeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final isLoading = ref
        .watch(deviceManagerProvider.select((value) => value.deviceList))
        .isEmpty;
    final horizontalLayout =
        ref.watch(dashboardHomeProvider).isHorizontalLayout;

    return horizontalLayout
        ? Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 150),
            child: ShimmerContainer(
              isLoading: isLoading,
              child: AppCard(
                  child: Column(
                children: [
                  Row(
                    // mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...state.lanPortConnections
                          .mapIndexed((index, e) => Expanded(
                                child: _portWidget(
                                    context,
                                    e == 'None' ? null : e,
                                    loc(context).indexedPort(index + 1),
                                    false),
                              ))
                          .toList(),
                      Expanded(
                        child: _portWidget(context, state.wanPortConnection,
                            loc(context).wan, true),
                      )
                    ],
                  )
                ],
              )),
            ),
          )
        : Container(
            constraints: const BoxConstraints(minWidth: 150),
            child: ShimmerContainer(
              isLoading: isLoading,
              child: AppCard(
                  child: Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...state.lanPortConnections
                          .mapIndexed((index, e) => Padding(
                                padding: const EdgeInsets.only(bottom: 60.0),
                                child: _portWidget(
                                    context,
                                    e == 'None' ? null : e,
                                    loc(context).indexedPort(index + 1),
                                    false),
                              ))
                          .toList(),
                      _portWidget(context, state.wanPortConnection,
                          loc(context).wan, true)
                    ],
                  )
                ],
              )),
            ),
          );
  }

  Widget _portWidget(
      BuildContext context, String? connection, String label, bool isWan) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              connection == null ? Icons.circle : Icons.check_circle,
              color: connection == null
                  ? Theme.of(context).colorScheme.surfaceVariant
                  : Theme.of(context).colorSchemeExt.green,
            ),
            const AppGap.semiSmall(),
            AppText.labelMedium(label),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture(
            connection == null
                ? CustomTheme.of(context).images.imgPortOff
                : CustomTheme.of(context).images.imgPortOn,
            width: 40,
            height: 40,
          ),
        ),
        if (connection != null) AppText.bodySmall(connection),
        if (isWan) AppText.labelMedium(loc(context).internet),
        Container(
          constraints: const BoxConstraints(maxWidth: 120),
          child: isWan
              ? Divider(
                  height: 8,
                  indent: 24,
                  endIndent: 24,
                  color: Theme.of(context).colorSchemeExt.orange)
              : null,
        ),
      ],
    );
  }
}
