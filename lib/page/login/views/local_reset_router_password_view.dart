import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/bottom_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_admin/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:ui_kit_library/ui_kit.dart';

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

  AppPasswordRule get hintNotContainPasswordRule => AppPasswordRule(
        label: loc(context).routerPasswordRuleHintContainPassword,
        validate: ((text) =>
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
    final rules = [
      AppPasswordRule(
          label: loc(context).routerPasswordRuleTenChars,
          validate: ((text) => LengthRule().validate(text))),
      AppPasswordRule(
          label: loc(context).routerPasswordRuleLowerUpper,
          validate: ((text) => HybridCaseRule().validate(text))),
      AppPasswordRule(
          label: loc(context).routerPasswordRuleOneNumber,
          validate: ((text) => DigitalCheckRule().validate(text))),
      AppPasswordRule(
          label: loc(context).routerPasswordRuleSpecialChar,
          validate: ((text) => SpecialCharCheckRule().validate(text))),
      AppPasswordRule(
          label: loc(context).routerPasswordRuleStartEndWithSpace,
          validate: ((text) => NoSurroundWhitespaceRule().validate(text))),
      AppPasswordRule(
          label: loc(context).routerPasswordRuleConsecutiveChar,
          validate: ((text) => !ConsecutiveCharRule().validate(text))),
      AppPasswordRule(
          label: loc(context).passwordsMustMatch,
          validate: ((text) => _confirmController.text == text)),
    ];

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      padding: EdgeInsets.zero,
      scrollable: true,
      pageFooter: const BottomBar(),
      child: (context, constraints) => Center(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          width: context.colWidth(4),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.headlineSmall(
                    loc(context).localResetRouterPasswordTitle),
                AppGap.lg(),
                AppText.bodyMedium(
                    loc(context).localResetRouterPasswordDescription),
                AppGap.xxxl(),
                AppPasswordInput(
                  controller: _newPasswordController,
                  label: loc(context).routerPasswordNew,
                  rules: rules,
                  onChanged: (value) {
                    setState(() {
                      isPasswordValid = !rules
                          .any((r) => !r.validate(_newPasswordController.text));
                      isHintNotContainPassword = hintNotContainPasswordRule
                          .validate(_newPasswordController.text);
                      ref.read(routerPasswordProvider.notifier).setValidate(
                          isPasswordValid && isHintNotContainPassword);
                    });
                  },
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(confirmFocusNode);
                  },
                ),
                AppGap.lg(),
                Focus(
                  focusNode: confirmFocusNode,
                  child: AppPasswordInput(
                    controller: _confirmController,
                    label: loc(context).retypeRouterPassword,
                    onChanged: (value) {
                      setState(() {
                        isPasswordValid = !rules.any(
                            (r) => !r.validate(_newPasswordController.text));
                      });
                      ref.read(routerPasswordProvider.notifier).setValidate(
                          isPasswordValid && isHintNotContainPassword);
                    },
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(hintFocusNode);
                    },
                  ),
                ),
                AppGap.lg(),
                Focus(
                  focusNode: hintFocusNode,
                  child: AppTextFormField(
                    controller: _hintController,
                    label: loc(context).routerPasswordHintOptional,
                    onChanged: (value) {
                      setState(() {
                        isHintNotContainPassword = hintNotContainPasswordRule
                            .validate(_newPasswordController.text);
                      });
                      ref.read(routerPasswordProvider.notifier).setValidate(
                          isPasswordValid && isHintNotContainPassword);
                    },
                  ),
                ),
                AppGap.xxxl(),
                AppButton(
                  label: loc(context).save,
                  variant: SurfaceVariant.highlight,
                  onTap: state.isValid ? _save : null,
                )
              ],
            ),
          ),
        ),
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
            AppButton.text(
              label: actionTitle,
              onTap: action,
            )
          ],
        ),
      );
    });
  }
}
