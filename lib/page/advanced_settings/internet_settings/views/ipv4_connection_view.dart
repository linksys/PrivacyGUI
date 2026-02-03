import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/optional_settings_form.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/wan_form_factory.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

class Ipv4ConnectionView extends ConsumerWidget {
  final bool isEditing;
  final bool isBridgeMode;
  final InternetSettingsState internetSettingsState;
  final InternetSettingsNotifier notifier;
  final VoidCallback onEditToggle;

  const Ipv4ConnectionView({
    Key? key,
    required this.isEditing,
    required this.isBridgeMode,
    required this.internetSettingsState,
    required this.notifier,
    required this.onEditToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.isMobileLayout ? 16.0 : 40.0),
        child: context.isMobileLayout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _infoCard(context, ref),
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
                    child: _infoCard(context, ref),
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

  Widget _infoCard(BuildContext context, WidgetRef ref) {
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
                _editButton(context, ref),
              ],
            ),
          ),
          infoCards,
        ],
      ),
    );
  }

  Widget _editButton(BuildContext context, WidgetRef ref) {
    final isRemoteReadOnly = ref.watch(
      remoteAccessProvider.select((state) => state.isRemoteReadOnly),
    );
    return Tooltip(
        message:
            isRemoteReadOnly ? loc(context).featureUnavailableInRemoteMode : '',
        child: AppIconButton(
          key: const Key('ipv4EditButton'),
          icon: Icon(
            isEditing ? AppFontIcons.close : AppFontIcons.edit,
          ),
          onTap: isRemoteReadOnly ? null : onEditToggle,
        ));
  }

  Widget _buildInfoCards(BuildContext context) {
    final wanType = WanType.resolve(
        internetSettingsState.current.ipv4Setting.ipv4ConnectionType);

    return wanType != null
        ? WanFormFactory.create(
            type: wanType,
            isEditing: isEditing,
          )
        : const SizedBox.shrink();
  }
}
