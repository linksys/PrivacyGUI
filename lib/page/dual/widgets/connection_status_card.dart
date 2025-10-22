import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dual/models/port_type.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_settings_provider.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/information_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ConnectionStatusCard extends ConsumerWidget {
  const ConnectionStatusCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus =
        ref.watch(dualWANSettingsProvider).status.connectionStatus;
    final ports = ref.watch(dualWANSettingsProvider).status.ports;
    
    return AppInformationCard(
      headerIcon: const Icon(Icons.show_chart),
      title: loc(context).connectionStatus,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: Spacing.small2,
        children: [
          AppCard(
            showBorder: false,
            color: Theme.of(context).colorScheme.primary.withAlpha(0x10),
            child: Row(
              children: [
                const Icon(LinksysIcons.check),
                const AppGap.small2(),
                AppText.bodyMedium(loc(context).primaryWan),
                const Spacer(),
                _wanConnectionLabel(connectionStatus.primaryStatus.toDisplayString(context), context),
              ],
            ),
          ),
          AppCard(
            showBorder: false,
            color: Theme.of(context).colorSchemeExt.green?.withAlpha(0x10),
            child: Row(
              children: [
                const Icon(LinksysIcons.check),
                const AppGap.small2(),
                AppText.bodyMedium(loc(context).secondaryWan),
                const Spacer(),
                _wanConnectionLabel(connectionStatus.secondaryStatus.toDisplayString(context), context),
              ],
            ),
          ),
          const Divider(height: 24),
          if (ports.isNotEmpty) ...[
            AppText.bodyMedium(loc(context).routerPortLayout),
            AppCard(
                showBorder: false,
                color: Theme.of(context).colorSchemeExt.surfaceContainerLow,
                child: Column(
                  children: [
                    AppText.bodyMedium(loc(context).backOfRouter),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: Spacing.small2,
                        children: ports
                            .map((port) => _portWidget(
                                port.speed, port.type, port.portNumber, context))
                            .toList()),
                  ],
                )),
            const AppGap.medium(),
          ],
          if (connectionStatus.primaryUptime != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText.bodyMedium(loc(context).primaryWanUptime),
                AppText.bodyMedium(DateFormatUtils.formatDuration(
                    Duration(seconds: connectionStatus.primaryUptime!), null)),
              ],
            ),
          if (connectionStatus.secondaryUptime != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText.bodyMedium(loc(context).secondaryWanUptime),
                AppText.bodyMedium(DateFormatUtils.formatDuration(
                    Duration(seconds: connectionStatus.secondaryUptime!),
                    null)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _portWidget(String? connection, PortType portType, int? lanIndex, BuildContext context) {
    final hasConnection = connection != null && connection != 'None';
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(Spacing.small2),
          child: SvgPicture(
            hasConnection
                ? CustomTheme.of(context).images.imgPortOff
                : CustomTheme.of(context).images.imgPortOn,
            semanticsLabel: 'port status image',
            width: 40,
            height: 40,
            colorFilter: ColorFilter.mode(
              portType.getDisplayColor(context),
              BlendMode.srcIn,
            ),
          ),
        ),
        AppText.labelMedium('${portType.toDisplayString()}${lanIndex ?? ''}',
            color: portType.getDisplayColor(context)),
        if (hasConnection)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LinksysIcons.bidirectional,
                color: portType.getDisplayColor(context),
                size: 16,
              ),
              AppText.bodySmall(connection,
                  color: portType.getDisplayColor(context)),
            ],
          ),
      ],
    );
  }
  
  Widget _wanConnectionLabel(String status, BuildContext context) {
    final theme = Theme.of(context);
    final color = status == 'Connected' 
        ? theme.colorSchemeExt.green 
        : status == 'Disconnected' 
            ? theme.colorScheme.error 
            : theme.colorScheme.onSurfaceVariant;
            
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
