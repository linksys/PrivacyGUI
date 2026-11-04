import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_device/providers/client_access_policy_provider.dart';
import 'package:privacy_gui/page/instant_device/views/client_action_menu.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class RestrictedDevicesView extends ConsumerWidget {
  const RestrictedDevicesView({super.key, required this.onShowFilters});
  final VoidCallback onShowFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(restrictedDevicesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
              child: AppText.titleSmall(loc(context).blockedRemovedDevices)),
          if (ResponsiveLayout.isMobileLayout(context))
            AppTextButton.noPadding(loc(context).filters, onTap: onShowFilters),
        ]),
        const AppGap.medium(),
        AppText.bodyMedium(loc(context).restrictedDevicesDescription),
        if (ref
                .watch(clientAccessPolicyProvider)
                .valueOrNull
                ?.macFilterMode
                .toLowerCase() ==
            'allow') ...[
          const AppGap.small2(),
          AppText.bodyMedium(loc(context).restrictedDevicesAllowDescription),
        ],
        const AppGap.medium(),
        devices.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Column(children: [
            Text(loc(context).restrictedDevicesLoadFailed),
            AppTextButton(loc(context).refresh,
                onTap: () => ref.invalidate(clientAccessPolicyProvider)),
          ]),
          data: (items) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc(context).nDevices(items.length)),
              const AppGap.small2(),
              if (items.isEmpty) Text(loc(context).noRestrictedDevices),
              for (final device in items) ...[
                AppCard(
                    child: Row(children: [
                  const Icon(Icons.wifi_off),
                  const AppGap.medium(),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.name),
                      Text(device.macAddress),
                      Text(loc(context).removedClientStatus),
                    ],
                  )),
                  ClientActionMenu(device: device, restricted: true),
                ])),
                const AppGap.small2(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
