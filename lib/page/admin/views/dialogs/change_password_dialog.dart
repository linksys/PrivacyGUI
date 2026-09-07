import 'package:flutter/material.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shows a password change dialog following the same pattern as
/// `instant_admin_view.dart` — `_showRouterPasswordModal()`.
///
/// Returns `true` if the password was successfully submitted.
Future<bool?> showChangePasswordDialog(
  BuildContext context, {
  required Future<void> Function(String newPassword) onSave,
}) {
  final controller = TextEditingController();
  final confirmController = TextEditingController();
  bool isPasswordValid = false;

  List<AppPasswordRule> rules(TextEditingController confirm) => [
        AppPasswordRule(
          label: loc(context).routerPasswordRuleTenChars,
          validate: (text) => LengthRule().validate(text),
        ),
        AppPasswordRule(
          label: loc(context).routerPasswordRuleUpperLower,
          validate: (text) => HybridCaseRule().validate(text),
        ),
        AppPasswordRule(
          label: loc(context).atLeastOneNumber,
          validate: (text) => DigitalCheckRule().validate(text),
        ),
        AppPasswordRule(
          label: loc(context).routerPasswordRuleOneSpecial,
          validate: (text) => SpecialCharCheckRule().validate(text),
        ),
        AppPasswordRule(
          label: loc(context).noLeadingTrailingSpaces,
          validate: (text) => NoSurroundWhitespaceRule().validate(text),
        ),
        AppPasswordRule(
          label: loc(context).routerPasswordRuleNoConsecutive,
          validate: (text) => !ConsecutiveCharRule().validate(text),
        ),
        AppPasswordRule(
          label: loc(context).passwordsMustMatch,
          validate: (text) => confirm.text == text,
        ),
      ];

  return showSubmitAppDialog<bool>(
    context,
    scrollable: true,
    useRootNavigator: false,
    title: loc(context).changeRouterPassword,
    contentBuilder: (context, setState, onSubmit) {
      final passwordRules = rules(confirmController);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPasswordInput(
            key: const Key('newPasswordField'),
            identifier: 'admin-new-password',
            controller: controller,
            label: loc(context).newPassword,
            rules: passwordRules,
            onChanged: (value) {
              setState(() {
                isPasswordValid =
                    !passwordRules.any((r) => !r.validate(controller.text));
              });
            },
          ),
          AppGap.lg(),
          AppPasswordInput(
            key: const Key('confirmPasswordField'),
            identifier: 'admin-confirm-password',
            controller: confirmController,
            label: loc(context).confirmPassword,
            onChanged: (value) {
              setState(() {
                isPasswordValid = !rules(confirmController)
                    .any((r) => !r.validate(controller.text));
              });
            },
          ),
        ],
      );
    },
    event: () async {
      await onSave(controller.text);
      return true;
    },
    checkPositiveEnabled: () => isPasswordValid,
  );
}
