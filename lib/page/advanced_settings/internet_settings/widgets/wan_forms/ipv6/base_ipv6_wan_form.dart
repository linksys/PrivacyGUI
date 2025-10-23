import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/utils/wan_type_helper.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/base_widgets_mixin.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

/// A base widget for all IPv6 WAN form types.
///
/// This widget provides a common structure and helper methods for all IPv6 WAN form types.
/// Subclasses should implement [buildForm] to provide the specific form fields.
abstract class BaseIPv6WanForm extends ConsumerStatefulWidget {
  final bool isEditing;

  const BaseIPv6WanForm({
    Key? key,
    required this.isEditing,
  }) : super(key: key);
}

abstract class BaseIPv6WanFormState<T extends BaseIPv6WanForm>
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
                  key: const ValueKey('ipv6ConnectionDropdown'),
                  selected:
                      state.settings.current.ipv6Setting.ipv6ConnectionType,
                  items: state.status.supportedIPv6ConnectionType,
                  label: (item) => getWanConnectedTypeText(context, item),
                  onChanged: (value) {
                    notifier.updateIpv6Settings(
                        state.settings.current.ipv6Setting.copyWith(
                      ipv6ConnectionType: value,
                    ));
                  },
                ),
              )
            : buildInfoCard(
                loc(context).connectionType,
                getWanConnectedTypeText(context,
                    state.settings.current.ipv6Setting.ipv6ConnectionType),
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
