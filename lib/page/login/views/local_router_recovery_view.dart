import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/bottom_bar.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/administration/router_password/providers/_providers.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';

import 'package:pin_code_fields/pin_code_fields.dart';

class LocalRouterRecoveryView extends ArgumentsConsumerStatefulView {
  const LocalRouterRecoveryView({Key? key, super.args}) : super(key: key);

  @override
  _LocalRouterRecoveryViewState createState() =>
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
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Center(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.headlineSmall(loc(context).forgot_password),
                const AppGap.regular(),
                AppText.bodyMedium(loc(context).localRouterRecoveryDescription),
                const AppGap.big(),
                PinCodeTextField(
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
                    borderRadius: BorderRadius.circular(4),
                    borderWidth: 1,
                    fieldHeight: 56,
                    fieldWidth: 40,
                    activeColor: Theme.of(context).colorScheme.outline,
                    selectedColor: Theme.of(context).colorScheme.outline,
                    inactiveColor: Theme.of(context).colorScheme.outline,
                  ),
                ),
                if (state.remainingErrorAttempts != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.semiSmall),
                    child: AppText.bodyMedium(
                      'That key didn\'t work. Check it and try again.\nTries remaining: ${state.remainingErrorAttempts}',
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const AppGap.big(),
                AppTextButton.noPadding(
                  loc(context).localRouterRecoveryHint,
                  onTap: () {},
                ),
                const AppGap.big(),
                AppFilledButton(
                  loc(context).text_continue,
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
}
