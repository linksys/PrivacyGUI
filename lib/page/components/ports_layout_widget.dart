
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:privacy_gui/core/jnap/providers/ethernet_port_connection_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class PortsLayoutWidget extends ConsumerWidget {
  final Axis axis;

  const PortsLayoutWidget({super.key, required this.axis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portState = ref.watch(ethernetPortConnectionProvider);
    final hasLanPort = portState.hasLanPort;
    final isDualWANEnabled = portState.isDualWANEnabled;

    final List<Widget> portWidgets = [
      ...portState.lans.mapIndexed((index, e) => _portWidget(
            context,
            e == 'None' ? null : e,
            loc(context).indexedPort(index + 1),
            false,
            hasLanPort,
          )),
      if (isDualWANEnabled)
        _portWidget(
          context,
          portState.secondaryWAN == 'None' ? null : portState.secondaryWAN,
          loc(context).wan,
          true,
          hasLanPort,
        ),
      _portWidget(
        context,
        portState.primaryWAN == 'None' ? null : portState.primaryWAN,
        loc(context).wan,
        true,
        hasLanPort,
      ),
    ];

    if (axis == Axis.horizontal) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: portWidgets.map((widget) => Expanded(child: widget)).toList(),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: Spacing.large2,
        children: portWidgets,
      );
    }
  }

  Widget _portWidget(BuildContext context, String? connection, String label,
      bool isWan, bool hasLanPorts) {
    final isMobile = ResponsiveLayout.isMobileLayout(context);
    final portLabel = [
      Icon(
        connection == null
            ? LinksysIcons.circle
            : LinksysIcons.checkCircleFilled,
        color: connection == null
            ? Theme.of(context).colorScheme.surfaceVariant
            : Theme.of(context).colorSchemeExt.green,
        semanticLabel: 'port icon',
      ),
      if (hasLanPorts) ...[
        const AppGap.small2(),
        AppText.labelMedium(label),
      ],
    ];

    return hasLanPorts
        ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                // mainAxisSize: MainAxisSize.min,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  isMobile
                      ? Column(
                          children: portLabel,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: portLabel,
                        )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.small2),
                child: SvgPicture(
                  connection == null
                      ? CustomTheme.of(context).images.imgPortOff
                      : CustomTheme.of(context).images.imgPortOn,
                  semanticsLabel: 'port status image',
                  width: 40,
                  height: 40,
                ),
              ),
              if (connection != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LinksysIcons.bidirectional,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        AppText.bodySmall(connection),
                      ],
                    ),
                    AppText.bodySmall(
                      loc(context).connectedSpeed,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              if (isWan && connection != null)
                AppText.labelMedium(loc(context).internet),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Wrap(
                    // mainAxisSize: MainAxisSize.min,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      isMobile
                          ? Column(
                              children: portLabel,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: portLabel,
                            )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Spacing.small2),
                    child: SvgPicture(
                      connection == null
                          ? CustomTheme.of(context).images.imgPortOff
                          : CustomTheme.of(context).images.imgPortOn,
                      semanticsLabel: 'port status image',
                      width: 40,
                      height: 40,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (connection != null)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LinksysIcons.bidirectional,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            AppText.bodyMedium(connection),
                          ],
                        ),
                        AppText.bodySmall(
                          loc(context).connectedSpeed,
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  if (isWan && connection != null)
                    AppText.labelMedium(loc(context).internet),
                ],
              ),
            ],
          );
  }
}
