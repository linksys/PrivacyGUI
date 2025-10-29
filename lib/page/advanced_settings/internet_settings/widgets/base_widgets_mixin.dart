import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/utils/validation_error.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

mixin BaseWidgetsMixin {

  @protected
  String? getLocalizedErrorText(BuildContext context, ValidationError? error) {
    if (error == null) return null;
    switch (error) {
      case ValidationError.invalidIpAddress:
        return loc(context).invalidIpAddress;
      case ValidationError.invalidMACAddress:
        return loc(context).invalidMACAddress;
      case ValidationError.invalidSubnetMask:
        return loc(context).invalidSubnetMask;
      default:
        return loc(context).generalError;
    }
  }

  Widget buildInfoCard(String title, String description) {
    return AppCard(
      showBorder: false,
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText.titleMedium(title.capitalizeWords()),
              ),
            ],
          ),
          AppText.bodyMedium(description),
        ],
      ),
    );
  }

  @protected
  Widget buildEditableField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enable = true,
  }) {
    return AppTextField(
      border: const OutlineInputBorder(),
      headerText: label,
      controller: controller,
      onChanged: onChanged,
      errorText: errorText,
      inputType: keyboardType,
      enable: enable,
    );
  }

  @protected
  Widget buildIpFormField({
    Key? key,
    required String semanticLabel,
    required String header,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? errorText,
    bool enable = true,
  }) {
    return AppIPFormField(
      key: key,
      semanticLabel: semanticLabel,
      header: AppText.bodySmall(header),
      controller: controller,
      border: const OutlineInputBorder(),
      onChanged: onChanged,
      errorText: errorText,
      enable: enable,
    );
  }
}
