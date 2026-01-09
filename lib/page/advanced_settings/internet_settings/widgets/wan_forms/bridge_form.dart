import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/base_wan_form.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart';

class BridgeForm extends BaseWanForm {
  const BridgeForm({
    Key? key,
    required super.isEditing,
  }) : super(key: key);

  @override
  ConsumerState<BridgeForm> createState() => _BridgeFormState();
}

class _BridgeFormState extends BaseWanFormState<BridgeForm> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget buildDisplayFields(BuildContext context) {
    final ipv4Setting =
        ref.watch(internetSettingsProvider).settings.current.ipv4Setting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildInfoCard(
          loc(context).vlanIdOptional,
          (ipv4Setting.wanTaggingSettingsEnable ?? false)
              ? ipv4Setting.vlanId?.toString() ?? '-'
              : '-',
        ),
      ],
    );
  }

  @override
  Widget buildEditableFields(BuildContext context) {
    final state = ref.watch(internetSettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildDisplayFields(context), // Display same info as in display mode
        AppGap.md(),
        AppGap.md(),
        AppStyledText(
          text: loc(context).toLogInLocallyWhileInBridgeMode,
          key: const ValueKey('toLogInLocallyWhileInBridgeMode'),
        ),
        AppGap.sm(),
        Row(
          children: [
            Icon(Icons.open_in_new,
                size: 16, color: Theme.of(context).colorScheme.primary),
            AppGap.xs(),
            AppButton.text(
              label: 'http://${state.status.hostname}.local',
              key: const ValueKey('bridgeModeLocalUrl'),
              onTap: () {
                openUrl('http://${state.status.hostname}.local');
              },
            ),
          ],
        ),
      ],
    );
  }
}
