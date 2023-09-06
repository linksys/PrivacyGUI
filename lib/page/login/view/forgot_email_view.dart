import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/customs/network_check_view.dart';
import 'package:linksys_app/page/components/layouts/basic_header.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class ForgotEmailView extends ConsumerStatefulWidget {
  const ForgotEmailView({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotEmailView> createState() => _ForgotEmailViewState();
}

class _ForgotEmailViewState extends ConsumerState<ForgotEmailView> {
  bool _isBehindRouter = false;

  @override
  void initState() {
    super.initState();
    // TODO check is behind router
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.close,
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).forgot_email,
        ),
        content: _isBehindRouter
            ? _contentViewBehindRouter('{a***********ng@b*******m}')
            : NetworkCheckView(
                description: getAppLocalizations(context)
                    .cloud_forgot_email_connect_to_your_router,
                button: AppPrimaryButton(
                  getAppLocalizations(context).am_connected,
                  onTap: () {
                    // TODO router API
                    setState(() {
                      _isBehindRouter = !_isBehindRouter;
                    });
                  },
                )),
      ),
    );
  }

  Widget _contentViewBehindRouter(String maskedMail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyLarge(
          getAppLocalizations(context).cloud_forgot_email_router_connected_to,
        ),
        const AppGap.big(),
        AppText.bodyLarge(
          maskedMail,
        ),
      ],
    );
  }
}
