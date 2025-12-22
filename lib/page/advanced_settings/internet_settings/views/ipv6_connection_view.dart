import 'package:flutter/material.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/optional_settings_form.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/ipv6/ipv6_wan_form_factory.dart';
import 'package:ui_kit_library/ui_kit.dart';

class Ipv6ConnectionView extends StatelessWidget {
  final bool isEditing;
  final bool isBridgeMode;
  final InternetSettingsState internetSettingsState;
  final InternetSettingsNotifier notifier;
  final VoidCallback onEditToggle;

  const Ipv6ConnectionView({
    Key? key,
    required this.isEditing,
    required this.isBridgeMode,
    required this.internetSettingsState,
    required this.notifier,
    required this.onEditToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.isMobileLayout ? 16.0 : 40.0),
        child: context.isMobileLayout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _infoCard(context),
                  AppGap.xl(),
                  OptionalSettingsForm(
                    isEditing: isEditing,
                    isBridgeMode: isBridgeMode,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: _infoCard(context),
                  ),
                  AppGap.gutter(),
                  Expanded(
                    child: OptionalSettingsForm(
                      isEditing: isEditing,
                      isBridgeMode: isBridgeMode,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _infoCard(BuildContext context) {
    final infoCards = _buildInfoCards(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                AppText.titleMedium(
                    loc(context).internetConnectionType.capitalizeWords()),
                const Spacer(),
                _editButton(context),
              ],
            ),
          ),
          infoCards,
        ],
      ),
    );
  }

  Widget _editButton(BuildContext context) {
    final isRemote = BuildConfig.isRemote();
    return Tooltip(
        message: isRemote ? loc(context).featureUnavailableInRemoteMode : '',
        child: AppIconButton(
          key: const Key('ipv6EditButton'),
          icon: Icon(
            isEditing ? AppFontIcons.close : AppFontIcons.edit,
            color: isEditing ? null : Theme.of(context).colorScheme.primary,
          ),
          onTap: isRemote ? null : onEditToggle,
        ));
  }

  Widget _buildInfoCards(BuildContext context) {
    final wanType = WanIPv6Type.resolve(
        internetSettingsState.current.ipv6Setting.ipv6ConnectionType);
    return wanType != null
        ? IPv6WanFormFactory.create(
            type: wanType,
            isEditing: isEditing,
          )
        : SizedBox.shrink();
  }
}
