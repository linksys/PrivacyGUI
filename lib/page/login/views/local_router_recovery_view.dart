import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/bottom_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/instant_admin/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';

import 'package:pin_code_fields/pin_code_fields.dart';

class LocalRouterRecoveryView extends ArgumentsConsumerStatefulView {
  const LocalRouterRecoveryView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<LocalRouterRecoveryView> createState() =>
      _LocalRouterRecoveryViewState();
}

class _LocalRouterRecoveryViewState
    extends ConsumerState<LocalRouterRecoveryView> {
  final TextEditingController _otpController = TextEditingController();
  String userInputCode = '';

  @override
  void dispose() {
    super.dispose();
    _otpController.dispose();
  }

  @override
  Widget build(BuildContext context) => _contentView();

  Widget _contentView() {
    final state = ref.watch(routerPasswordProvider);

    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      scrollable: true,
      child: AppBasicLayout(
        content: Center(
          child: AppCard(
            child: SizedBox(
              width: 289,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.headlineSmall(loc(context).forgotPassword),
                  const AppGap.medium(),
                  AppText.bodyMedium(
                      loc(context).localRouterRecoveryDescription),
                  const AppGap.large3(),
                  Semantics(
                    label: 'pin code text field',
                    textField: true,
                    child: PinCodeTextField(
                      errorTextSpace: 0,
                      onChanged: (String value) {
                        setState(() {
                          userInputCode = value;
                        });
                      },
                      length: 5,
                      appContext: context,
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      autoDismissKeyboard: true,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius:
                            CustomTheme.of(context).radius.asBorderRadius().small,
                        borderWidth: 1,
                        fieldHeight: 56,
                        fieldWidth: 40,
                        activeColor: Theme.of(context).colorScheme.outline,
                        selectedColor: Theme.of(context).colorScheme.outline,
                        inactiveColor: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  if (state.remainingErrorAttempts != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.small2),
                      child: AppText.bodyMedium(
                        _getErrorString(state.remainingErrorAttempts!),
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const AppGap.large5(),
                  AppFilledButton(
                    loc(context).textContinue,
                    onTap: userInputCode.length == 5
                        ? () {
                            _validateCode(userInputCode);
                          }
                        : null,
                  )
                ],
              ),
            ),
          ),
        ),
        footer: const BottomBar(),
      ),
    );
  }

  _validateCode(String code) {
    ref
        .read(routerPasswordProvider.notifier)
        .checkRecoveryCode(code)
        .then((isCodeValid) {
      if (isCodeValid) {
        context.pushNamed(
          RouteNamed.localPasswordReset,
          extra: {'code': code},
        );
      }
    });
  }

  String _getErrorString(int remaining) {
    switch (remaining) {
      case 1:
        return '${loc(context).localRouterRecoveryKeyErorr}\n${loc(context).localRouterRecoveryKeyLastChance}';
      case 0:
        return '${loc(context).localRouterRecoveryKeyErorr}\n${loc(context).localRouterRecoveryKeyLocked}';
      default:
        return '${loc(context).localRouterRecoveryKeyErorr}\n${loc(context).localLoginRemainingAttempts(remaining)}';
    }
  }
}
