import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/bottom_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/administration/network_admin/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
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
  final _hintController = TextEditingController();
  final validations = [
    Validation(
        description: 'At least 10 characters',
        validator: ((text) => LengthRule().validate(text))),
    Validation(
        description: 'Upper and lowercase letters',
        validator: ((text) => HybridCaseRule().validate(text))),
    Validation(
        description: '1 number',
        validator: ((text) => DigitalCheckRule().validate(text))),
    Validation(
        description: '1 special character',
        validator: ((text) => SpecialCharCheckRule().validate(text))),
  ];

  @override
  void dispose() {
    super.dispose();

    _newPasswordController.dispose();
    _hintController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routerPasswordProvider);
    return StyledAppPageView(
      scrollable: true,
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Center(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.headlineSmall(
                    loc(context).localResetRouterPasswordTitle),
                const AppGap.regular(),
                AppText.bodyMedium(
                    loc(context).localResetRouterPasswordDescription),
                const AppGap.big(),
                AppPasswordField(
                  border: const OutlineInputBorder(),
                  withValidator: state.hasEdited,
                  validations: validations,
                  hintText: loc(context).localResetRouterPasswordTitle,
                  controller: _newPasswordController,
                  onFocusChanged: (hasFocus) {
                    ref
                        .read(routerPasswordProvider.notifier)
                        .setEdited(hasFocus);
                  },
                  onValidationChanged: (isValid) {
                    ref
                        .read(routerPasswordProvider.notifier)
                        .setValidate(isValid);
                  },
                ),
                const AppGap.regular(),
                AppTextField(
                  border: const OutlineInputBorder(),
                  hintText: loc(context).routerPasswordHint,
                  controller: _hintController,
                ),
                const AppGap.big(),
                AppFilledButton(
                  loc(context).save,
                  onTap: state.isValid ? _save : null,
                )
              ],
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
      dialogTitle = loc(context).successExclamation;
      dialogContent = loc(context).localResetRouterPasswordSuccessContent;
      actionTitle = loc(context).localResetRouterPasswordSuccessNext;
      action = () {
        context.goNamed(RouteNamed.localLoginPassword);
      };
    }).onError((error, stackTrace) {
      //TODO: Error messages are not defined by UI
      dialogTitle = loc(context).failedExclamation;
      dialogContent = (error is JNAPError) ? error.result : '';
      actionTitle = loc(context).ok;
      action = () {
        context.pop();
      };
    }).whenComplete(() {
      showAdaptiveDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog.adaptive(
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
