import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/create_account/view/_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

import 'package:pin_code_fields/pin_code_fields.dart';

class LocalRecoveryKeyView extends ArgumentsConsumerStatefulView {
  const LocalRecoveryKeyView({Key? key, super.args}) : super(key: key);

  @override
  _LocalResetRouterPasswordState createState() =>
      _LocalResetRouterPasswordState();
}

class _LocalResetRouterPasswordState
    extends ConsumerState<LocalRecoveryKeyView> {
  final bool _isLoading = false;
  final TextEditingController _otpController = TextEditingController();
  String _errorReason = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppText.descriptionMain('TBD'),
    );
  }

  Widget _contentView() {
    final theme = AppTheme.of(context);
    return StyledAppPageView(
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).reset_router_password,
        ),
        content: Column(
          children: [
            PinCodeTextField(
              onChanged: (String value) {
                setState(() {
                  _errorReason = '';
                });
              },
              onCompleted: (String? value) => _onNext(value),
              length: 5,
              appContext: context,
              controller: _otpController,
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.underline,
                fieldHeight: 46,
                fieldWidth: 48,
                inactiveColor: theme.colors.tertiaryText,
              ),
            ),
            const AppGap.regular(),
            if (_errorReason.isNotEmpty)
              AppPadding(
                padding:
                    const AppEdgeInsets.symmetric(vertical: AppGapSize.small),
                child: AppText.descriptionSub(
                  _errorReason,
                  color: ConstantColors.tertiaryRed,
                ),
              ),
          ],
        ),
      ),
    );
  }

  _onNext(String? value) {
    ref.read(navigationsProvider.notifier).push(
        AuthLocalResetPasswordPath()..args = {'type': AdminPasswordType.reset});
    // ref.read(navigationsProvider.notifier).push(AuthResetLocalOtpPath()
    //   ..args = {
    //     'username': 'austin.chang@linksys.com', // TODO
    //   });
  }
}
