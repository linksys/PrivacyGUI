import 'package:flutter/material.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
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
          label: 'At least 10 characters',
          validate: (text) => LengthRule().validate(text),
        ),
        AppPasswordRule(
          label: 'Upper and lower case letters',
          validate: (text) => HybridCaseRule().validate(text),
        ),
        AppPasswordRule(
          label: 'At least one number',
          validate: (text) => DigitalCheckRule().validate(text),
        ),
        AppPasswordRule(
          label: 'At least one special character',
          validate: (text) => SpecialCharCheckRule().validate(text),
        ),
        AppPasswordRule(
          label: 'No leading or trailing spaces',
          validate: (text) => NoSurroundWhitespaceRule().validate(text),
        ),
        AppPasswordRule(
          label: 'No consecutive identical characters',
          validate: (text) => !ConsecutiveCharRule().validate(text),
        ),
        AppPasswordRule(
          label: 'Passwords must match',
          validate: (text) => confirm.text == text,
        ),
      ];

  return showSubmitAppDialog<bool>(
    context,
    scrollable: true,
    useRootNavigator: false,
    title: 'Change Router Password',
    contentBuilder: (context, setState, onSubmit) {
      final passwordRules = rules(confirmController);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPasswordInput(
            key: const Key('newPasswordField'),
            controller: controller,
            label: 'New Password',
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
            controller: confirmController,
            label: 'Confirm Password',
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
