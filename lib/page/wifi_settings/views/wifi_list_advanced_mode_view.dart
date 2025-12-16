import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/guest_wifi_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/main_wifi_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

class AdvancedModeView extends ConsumerStatefulWidget {
  const AdvancedModeView({
    super.key,
  });

  @override
  ConsumerState<AdvancedModeView> createState() => _AdvancedModeViewState();
}

class _AdvancedModeViewState extends ConsumerState<AdvancedModeView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiBundleProvider);

    return _wifiContentView(state);
  }

  Widget _wifiContentView(WifiBundleState state) {
    // Use UI Kit responsive layout logic - simplified version based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = context.isMobileLayout;

    final columnCount = screenWidth > 1200
        ? 4
        : screenWidth > 900
            ? 3
            : isMobile
                ? 2
                : 3;

    final fixedWidth = screenWidth > 1200
        ? context.colWidth(3)
        : screenWidth > 900
            ? context.colWidth(4)
            : isMobile
                ? context.colWidth(2)
                : context.colWidth(4);

    // Calculate column widths with spacing
    final spacing = screenWidth > 900 ? AppSpacing.xxl : AppSpacing.lg;

    final enabledWiFiCount = state.settings.current.wifiList.mainWiFi
        .where((e) => e.isEnabled)
        .length;
    final canDisableAllMainWiFi = state.status.wifiList.canDisableMainWiFi;
    final canBeDisabled = enabledWiFiCount > 1 || canDisableAllMainWiFi;

    // Create all items to layout
    final allWifiItems = state.settings.current.wifiList.mainWiFi
        .map((e) => MainWiFiCard(
              radio: e,
              canBeDisable: canBeDisabled,
              lastInRow: false, // Will be calculated below
            ))
        .toList();

    final guestWifiCard = GuestWiFiCard(
      state: state.settings.current.wifiList.guestWiFi,
      lastInRow: false, // Will be calculated below
    );

    final allCards = [...allWifiItems, guestWifiCard];

    // Use Wrap with proper width calculation to allow flexible heights
    // This maintains the grid behavior but allows cards to have different heights
    return Wrap(
      spacing: spacing,
      runSpacing: AppSpacing.lg,
      children: allCards.mapIndexed((index, card) {
        // Calculate if this card is the last in its row
        final isLastInRow =
            (index + 1) % columnCount == 0 || index == allCards.length - 1;

        return SizedBox(
          width: fixedWidth,
          child: card is MainWiFiCard
              ? MainWiFiCard(
                  radio: card.radio,
                  canBeDisable: card.canBeDisable,
                  lastInRow: isLastInRow,
                )
              : GuestWiFiCard(
                  state: (card as GuestWiFiCard).state,
                  lastInRow: isLastInRow,
                ),
        );
      }).toList(),
    );
  }
}
