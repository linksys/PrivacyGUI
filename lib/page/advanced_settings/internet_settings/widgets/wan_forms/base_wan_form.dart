import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/utils/wan_type_helper.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/base_widgets_mixin.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';


abstract class BaseWanForm extends ConsumerStatefulWidget {
  final bool isEditing;

  const BaseWanForm({
    Key? key,
    required this.isEditing,
  }) : super(key: key);
}

abstract class BaseWanFormState<T extends BaseWanForm>
    extends ConsumerState<T> with BaseWidgetsMixin {

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(internetSettingsProvider);
    final notifier = ref.read(internetSettingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.isEditing
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
                child: AppDropdownButton<String>(
                  key: const ValueKey('ipv4ConnectionDropdown'),
                  selected:
                      state.settings.current.ipv4Setting.ipv4ConnectionType,
                  items: state.status.supportedIPv4ConnectionType,
                  label: (item) => getWanConnectedTypeText(context, item),
                  onChanged: (value) {
                    notifier.updateIpv4Settings(
                        state.settings.current.ipv4Setting.copyWith(
                      ipv4ConnectionType: value,
                      mtu: state.settings.current.ipv4Setting.mtu,
                    ));
                    final selectedType = WanType.resolve(value);
                    if (selectedType == null) {
                      return;
                    }
                    if (selectedType == WanType.bridge) {
                      notifier.setSettingsDefaultOnBrigdeMode();
                    }
                  },
                ),
              )
            : buildInfoCard(
                loc(context).connectionType,
                getWanConnectedTypeText(context,
                    state.settings.current.ipv4Setting.ipv4ConnectionType),
              ),
        widget.isEditing
            ? buildEditableFields(context)
            : buildDisplayFields(context),
      ],
    );
  }

  @protected
  Widget buildEditableFields(BuildContext context);

  @protected
  Widget buildDisplayFields(BuildContext context);
}
