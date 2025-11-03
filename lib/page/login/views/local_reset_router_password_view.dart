import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/bottom_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_admin/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class LocalResetRouterPasswordView extends ArgumentsConsumerStatefulView {
  const LocalResetRouterPasswordView({Key? key, super.args}) : super(key: key);

  @override
  ConsumerState<LocalResetRouterPasswordView> createState() =>
      _LocalResetRouterPasswordViewState();
}

class _LocalResetRouterPasswordViewState
    extends ConsumerState<LocalResetRouterPasswordView> {
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _hintController = TextEditingController();
  FocusNode hintFocusNode = FocusNode();
  FocusNode confirmFocusNode = FocusNode();

  Validation get hintNotContainPasswordValidator => Validation(
        description: loc(context).routerPasswordRuleHintContainPassword,
        validator: ((text) =>
            !_hintController.text.toLowerCase().contains(text.toLowerCase())),
      );
  bool isPasswordValid = false;
  bool isHintNotContainPassword = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    _newPasswordController.dispose();
    _confirmController.dispose();
    _hintController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routerPasswordProvider);
    MediaQuery.of(context);
    final validations = [
      Validation(
          description: loc(context).routerPasswordRuleTenChars,
          validator: ((text) => LengthRule().validate(text))),
      Validation(
          description: loc(context).routerPasswordRuleLowerUpper,
          validator: ((text) => HybridCaseRule().validate(text))),
      Validation(
          description: loc(context).routerPasswordRuleOneNumber,
          validator: ((text) => DigitalCheckRule().validate(text))),
      Validation(
          description: loc(context).routerPasswordRuleSpecialChar,
          validator: ((text) => SpecialCharCheckRule().validate(text))),
      Validation(
          description: loc(context).routerPasswordRuleStartEndWithSpace,
          validator: ((text) => NoSurroundWhitespaceRule().validate(text))),
      Validation(
          description: loc(context).routerPasswordRuleConsecutiveChar,
          validator: ((text) => !ConsecutiveCharRule().validate(text))),
      Validation(
          description: loc(context).passwordsMustMatch,
          validator: ((text) => _confirmController.text == text)),
    ];

    return StyledAppPageView(
      // scrollable: true,
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      child: (context, constraints) => AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Center(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: Spacing.medium),
            width: 4.col,
            child: AppCard(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.headlineSmall(
                        loc(context).localResetRouterPasswordTitle),
                    const AppGap.medium(),
                    AppText.bodyMedium(
                        loc(context).localResetRouterPasswordDescription),
                    const AppGap.large3(),
                    AppPasswordField(
                      border: const OutlineInputBorder(),
                      controller: _newPasswordController,
                      headerText: loc(context).routerPasswordNew,
                      validations: validations,
                      onFocusChanged: (hasFocus) {
                        ref
                            .read(routerPasswordProvider.notifier)
                            .setEdited(hasFocus);
                      },
                      onValidationChanged: (isValid) {
                        setState(() {
                          isPasswordValid = isValid;
                          ref.read(routerPasswordProvider.notifier).setValidate(
                              isPasswordValid && isHintNotContainPassword);
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          isHintNotContainPassword =
                              hintNotContainPasswordValidator
                                  .validator(_newPasswordController.text);
                        });
                      },
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(confirmFocusNode);
                      },
                    ),
                    const AppGap.medium(),
                    AppPasswordField(
                      border: const OutlineInputBorder(),
                      controller: _confirmController,
                      headerText: loc(context).retypeRouterPassword,
                      focusNode: confirmFocusNode,
                      onChanged: (value) {
                        setState(() {
                          isPasswordValid = !validations.any(
                              (v) => !v.validator(_newPasswordController.text));
                        });
                        ref.read(routerPasswordProvider.notifier).setValidate(
                            isPasswordValid && isHintNotContainPassword);
                      },
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(hintFocusNode);
                      },
                    ),
                    const AppGap.large2(),
                    AppValidatorWidget(
                      validations: validations,
                      textToValidate: _newPasswordController.text,
                    ),
                    const AppGap.large3(),
                    AppTextField(
                      border: const OutlineInputBorder(),
                      controller: _hintController,
                      headerText: loc(context).routerPasswordHintOptional,
                      focusNode: hintFocusNode,
                      onChanged: (value) {
                        setState(() {
                          isHintNotContainPassword =
                              hintNotContainPasswordValidator
                                  .validator(_newPasswordController.text);
                        });
                        ref.read(routerPasswordProvider.notifier).setValidate(
                            isPasswordValid && isHintNotContainPassword);
                      },
                      onSubmitted: (_) {
                        if (isPasswordValid && isHintNotContainPassword) {
                          _save();
                        }
                      },
                    ),
                    const AppGap.large2(),
                    AppValidatorWidget(
                      validations: [hintNotContainPasswordValidator],
                      textToValidate: _newPasswordController.text,
                    ),
                    const AppGap.large3(),
                    AppFilledButton(
                      loc(context).save,
                      onTap: state.isValid ? _save : null,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        footer: const BottomBar(),
      ),
    );
  }

  void _save() {
    final code = widget.args['code'] ?? '';
    late String dialogTitle;
    late String dialogContent;
    late String actionTitle;
    late VoidCallback action;
    ref
        .read(routerPasswordProvider.notifier)
        .setAdminPasswordWithResetCode(
          _newPasswordController.text,
          _hintController.text,
          code,
        )
        .then<void>((_) {
      if (!mounted) return;
      dialogTitle = loc(context).successExclamation;
      dialogContent = loc(context).localResetRouterPasswordSuccessContent;
      actionTitle = loc(context).localResetRouterPasswordSuccessNext;
      action = () {
        context.goNamed(RouteNamed.localLoginPassword, extra: {'reset': true});
      };
    }).onError((error, stackTrace) {
      if (!mounted) return;
      dialogTitle = loc(context).failedExclamation;
      dialogContent = loc(context).invalidAdminPassword;
      actionTitle = loc(context).ok;
      action = () {
        context.pop();
      };
    }).whenComplete(() {
      if (!mounted) return;
      showAdaptiveDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog.adaptive(
          key: const ValueKey('resetSavedDialog'),
          title: AppText.titleLarge(dialogTitle),
          content: AppText.bodyMedium(dialogContent),
          actions: [
            AppTextButton(
              actionTitle,
              onTap: action,
            )
          ],
        ),
      );
    });
  }
}
