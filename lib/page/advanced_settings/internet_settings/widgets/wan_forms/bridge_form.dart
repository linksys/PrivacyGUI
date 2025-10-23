import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/base_wan_form.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/text/app_styled_text.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:privacy_gui/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/url_helper/url_helper_web.dart';

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
    final ipv4Setting = ref.watch(internetSettingsProvider).settings.current.ipv4Setting;
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
        const AppGap.small3(),
        AppStyledText.bold(
          loc(context).toLogInLocallyWhileInBridgeMode,
          defaultTextStyle: Theme.of(context).textTheme.bodyLarge!,
          tags: const ['b'],
        ),
        const AppGap.small2(),
        AppTextButton.noPadding(
          'http://${state.status.hostname}.local',
          icon: Icons.open_in_new,
          onTap: () {
            openUrl('http://${state.status.hostname}.local');
          },
        ),
      ],
    );
  }
}
