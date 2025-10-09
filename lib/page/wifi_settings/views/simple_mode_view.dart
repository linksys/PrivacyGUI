import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_view.dart';
import 'package:collection/collection.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';

class SimpleModeView extends ConsumerStatefulWidget {
  const SimpleModeView({
    super.key,
    required this.simpleWifiNameController,
    required this.simpleWifiPasswordController,
    required this.simpleSecurityType,
    required this.onSecurityTypeChanged,
    required this.guestWiFiCard,
  });

  final TextEditingController simpleWifiNameController;
  final TextEditingController simpleWifiPasswordController;
  final WifiSecurityType? simpleSecurityType;
  final Function(WifiSecurityType) onSecurityTypeChanged;
  final Widget Function(GuestWiFiItem, {bool lastInRow}) guestWiFiCard;

  @override
  ConsumerState<SimpleModeView> createState() => _SimpleModeViewState();
}

class _SimpleModeViewState extends ConsumerState<SimpleModeView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiListProvider);
    final firstActiveWifi = state.mainWiFi.firstWhereOrNull((e) => e.isEnabled);
    if (firstActiveWifi == null) {
      return const SizedBox.shrink();
    }

    Set<WifiSecurityType> securityTypeSet =
        state.mainWiFi.first.availableSecurityTypes.toSet();
    for (var e in state.mainWiFi) {
      final availableSecurityTypesSet = e.availableSecurityTypes.toSet();
      securityTypeSet = securityTypeSet.intersection(availableSecurityTypesSet);
    }
    final securityTypeList = securityTypeSet.toList();

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.titleLarge(loc(context).mainNetwork),
              const AppGap.medium(),
              AppText.labelMedium(loc(context).networkName),
              const AppGap.small1(),
              AppTextField(
                controller: widget.simpleWifiNameController,
                border: const OutlineInputBorder(),
              ),
              const AppGap.medium(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelMedium(loc(context).password),
                        const AppGap.small1(),
                        AppPasswordField(
                          controller: widget.simpleWifiPasswordController,
                          border: const OutlineInputBorder(),
                        ),
                      ],
                    ),
                  ),
                  const AppGap.medium(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelMedium(loc(context).encryption),
                        const AppGap.small1(),
                        AppDropdownButton<WifiSecurityType>(
                          initial: widget.simpleSecurityType,
                          items: securityTypeList,
                          label: (e) => getWifiSecurityTypeTitle(context, e),
                          onChanged: (value) {
                            widget.onSecurityTypeChanged(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const AppGap.medium(),
              AppText.bodySmall(loc(context).simpleModeDescription),
            ],
          ),
        ),
        const AppGap.medium(),
        widget.guestWiFiCard(state.guestWiFi),
      ],
    );
  }
}