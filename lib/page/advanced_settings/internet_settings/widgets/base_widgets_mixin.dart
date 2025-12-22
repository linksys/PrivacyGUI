import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/utils/validation_error.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.md,
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
    Key? key,
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enable = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge(label),
        AppGap.xs(),
        AppTextField(
          key: key,
          controller: controller,
          onChanged: onChanged,
          errorText: errorText,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: !enable,
        ),
      ],
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
    return AppIpv4TextField(
      key: key,
      label: header,
      controller: controller,
      onChanged: onChanged,
      errorText: errorText,
      enabled: enable,
    );
  }
}
