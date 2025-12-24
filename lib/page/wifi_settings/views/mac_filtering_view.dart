import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/displayed_mac_filtering_devices_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

class MacFilteringView extends ConsumerWidget {
  const MacFilteringView({
    super.key,
    this.args,
  });

  final Map<String, dynamic>? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyState = ref.watch(
        wifiBundleProvider.select((state) => state.settings.current.privacy));
    final originalPrivacyState = ref.watch(
        wifiBundleProvider.select((state) => state.settings.original.privacy));

    final displayDevices = ref.watch(macFilteringDeviceListProvider);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: AppResponsiveLayout(
          desktop: (ctx) => _desktopLayout(
              context, ref, privacyState, originalPrivacyState, displayDevices),
          mobile: (ctx) => _mobileLayout(
              context, ref, privacyState, originalPrivacyState, displayDevices),
        ),
      ),
    );
  }

  Widget _desktopLayout(
      BuildContext context,
      WidgetRef ref,
      InstantPrivacySettings state,
      InstantPrivacySettings originalState,
      List<DeviceListItem> deviceList) {
    return SizedBox(
      width: context.colWidth(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (originalState.mode == MacFilterMode.allow) ...[
            _warningCard(context),
            AppGap.sm(),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _enableTile(context, ref, state),
                    AppGap.sm(),
                    _infoCard(context, state.mode == MacFilterMode.deny,
                        deviceList.length),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout(
      BuildContext context,
      WidgetRef ref,
      InstantPrivacySettings state,
      InstantPrivacySettings originalState,
      List<DeviceListItem> deviceList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (originalState.mode == MacFilterMode.allow) ...[
          _warningCard(context),
          AppGap.sm(),
        ],
        _enableTile(context, ref, state),
        AppGap.sm(),
        _infoCard(context, state.mode == MacFilterMode.deny, deviceList.length),
        AppGap.xl(),
      ],
    );
  }

  Widget _warningCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.error),
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            AppIcon.font(
              AppFontIcons.infoCircle,
              color: Theme.of(context).colorScheme.error,
            ),
            AppGap.lg(),
            Expanded(
              child:
                  AppText.bodyMedium(loc(context).instantPrivacyDisableWarning),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, bool enabled, int length) {
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        onTap: enabled
            ? () {
                context.pushNamed(RouteNamed.macFilteringInput);
              }
            : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(
                      loc(context).nDevices(length).capitalizeWords()),
                  AppGap.xs(),
                  AppText.bodyMedium(loc(context).denyAccessDesc),
                ],
              ),
            ),
            AppIcon.font(AppFontIcons.chevronRight),
          ],
        ),
      ),
    );
  }

  Widget _enableTile(
      BuildContext context, WidgetRef ref, InstantPrivacySettings state) {
    final notifier = ref.read(wifiBundleProvider.notifier);
    return AppCard(
      key: const Key('macFilteringEnableTile'),
      child: Row(
        children: [
          Expanded(child: AppText.labelLarge(loc(context).wifiMacFiltering)),
          AppSwitch(
            key: const Key('macFilteringEnableSwitch'),
            value: state.mode == MacFilterMode.deny,
            onChanged: (value) {
              notifier.setMacFilterMode(
                  value ? MacFilterMode.deny : MacFilterMode.disabled);
            },
          )
        ],
      ),
    );
  }
}
