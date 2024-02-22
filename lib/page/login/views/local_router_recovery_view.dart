import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/layouts/basic_header.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/administration/router_password/providers/_providers.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    _otpController.dispose();
  }

  @override
  Widget build(BuildContext context) => _contentView();

  Widget _contentView() {
    final state = ref.watch(routerPasswordProvider);
    final goRouter = GoRouter.of(context);

    return StyledAppPageView(
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Enter Recovery Key',
        ),
        content: Column(
          children: [
            PinCodeTextField(
              onChanged: (String value) {
                // ref.read(routerPasswordProvider.notifier).clearErrorPrompt();
              },
              onCompleted: (String? value) => _onNext(value, goRouter),
              length: 5,
              appContext: context,
              controller: _otpController,
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.underline,
                fieldHeight: 46,
                fieldWidth: 48,
              ),
            ),
            const AppGap.regular(),
            if (state.remainingErrorAttempts != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.small),
                child: AppText.bodyMedium(
                  'That key didn\'t work. Check it and try again.\nTries remaining: ${state.remainingErrorAttempts}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  _onNext(String? value, GoRouter goRouter) async {
    if (value != null) {
      final isCodeValid = await ref
          .read(routerPasswordProvider.notifier)
          .checkRecoveryCode(value);
      if (isCodeValid) {
        goRouter.pushNamed(
          RouteNamed.localPasswordReset,
          extra: {'code': value},
        );
      }
    }
  }
}
