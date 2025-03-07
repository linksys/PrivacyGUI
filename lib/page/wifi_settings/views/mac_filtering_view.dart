import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/mixin/preserved_state_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/displayed_mac_filtering_devices_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/info_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class MacFilteringView extends ArgumentsConsumerStatefulView {
  const MacFilteringView({
    super.key,
    super.args,
  });

  @override
  ConsumerState<MacFilteringView> createState() => _MacFilteringViewState();
}

class _MacFilteringViewState extends ConsumerState<MacFilteringView>
    with
        PreservedStateMixin<InstantPrivacyState, MacFilteringView>,
        PageSnackbarMixin {
  late final InstantPrivacyNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(instantPrivacyProvider.notifier);
    doSomethingWithSpinner(
      context,
      _notifier.fetch().then((value) async {
        await _notifier.doPolling();
        preservedState = value;
        ref
            .read(wifiViewProvider.notifier)
            .setMacFilteringViewChanged(value != preservedState);
      }),
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantPrivacyProvider);
    final displayDevices = ref.watch(macFilteringDeviceListProvider);
    ref.listen(instantPrivacyProvider, (prev, next) {
      if (preservedState != null) {
        ref
            .read(wifiViewProvider.notifier)
            .setMacFilteringViewChanged(next != preservedState);
      }
    });
    return StyledAppPageView(
      scrollable: true,
      hideTopbar: true,
      appBarStyle: AppBarStyle.none,
      useMainPadding: true,
      bottomBar: PageBottomBar(
          isPositiveEnabled: state.mode == MacFilterMode.deny
              ? isStateChanged(state)
              : state.mode != preservedState?.mode,
          onPositiveTap: () {
            _showEnableDialog(state.mode != MacFilterMode.disabled);
          }),
      child: (context, constraints, scrollController) =>ResponsiveLayout(
        desktop: _desktopLayout(state, displayDevices),
        mobile: _mobileLayout(state, displayDevices),
      ),
    );
  }

  Widget _desktopLayout(
      InstantPrivacyState state, List<DeviceListItem> deviceList) {
    return AppBasicLayout(
      content: SizedBox(
        width: 9.col,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (preservedState?.mode == MacFilterMode.allow) ...[
              _warningCard(),
              const AppGap.small2(),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _enableTile(state),
                      const AppGap.small2(),
                      _infoCard(
                          state.mode == MacFilterMode.deny, deviceList.length),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileLayout(
      InstantPrivacyState state, List<DeviceListItem> deviceList) {
    return AppBasicLayout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (preservedState?.mode == MacFilterMode.allow) ...[
            _warningCard(),
            const AppGap.small2(),
          ],
          _enableTile(state),
          const AppGap.small2(),
          _infoCard(state.mode == MacFilterMode.deny, deviceList.length),
          const AppGap.large2(),
        ],
      ),
    );
  }

  Widget _warningCard() {
    return AppSettingCard(
      title: loc(context).instantPrivacyDisableWarning,
      leading: Icon(
        LinksysIcons.infoCircle,
        color: Theme.of(context).colorScheme.error,
      ),
      borderColor: Theme.of(context).colorScheme.error,
    );
  }

  Widget _infoCard(bool enabled, int length) {
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: AppInfoCard(
        padding: const EdgeInsets.all(Spacing.medium),
        onTap: enabled
            ? () {
                context.pushNamed(RouteNamed.macFilteringInput);
              }
            : null,
        title: loc(context).nDevices(length).capitalizeWords(),
        description: loc(context).denyAccessDesc,
        trailing: Icon(LinksysIcons.chevronRight),
      ),
    );
  }

  Widget _enableTile(InstantPrivacyState state) {
    return AppCard(
        child: Row(
      children: [
        Expanded(child: AppText.labelLarge(loc(context).wifiMacFiltering)),
        AppSwitch(
          semanticLabel: 'wifi mac filtering',
          value: state.mode == MacFilterMode.deny,
          onChanged: (value) {
            _notifier.setAccess(value
                ? MacFilterMode.deny
                : preservedState?.mode == MacFilterMode.deny
                    ? MacFilterMode.disabled
                    : preservedState?.mode ?? MacFilterMode.disabled);
          },
        )
      ],
    ));
  }

  void _showEnableDialog(bool enable) {
    showMacFilteringConfirmDialog(context, enable).then((value) {
      if (value != true) {
        return;
      }
      if (enable) {
        final macAddressList = ref
            .read(macFilteringDeviceListProvider)
            .map((e) => e.macAddress.toUpperCase())
            .toList();
        _notifier.setMacAddressList(macAddressList);
      }
      doSomethingWithSpinner(
        context,
        _notifier.save(),
      ).then((state) {
        preservedState = state;
        ref.read(wifiViewProvider.notifier).setMacFilteringViewChanged(false);
        showChangesSavedSnackBar();
      }).onError((error, stackTrace) {
        showErrorMessageSnackBar(error);
      });
    });
  }
}
