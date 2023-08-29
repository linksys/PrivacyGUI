import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/layouts/basic_header.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/network/_network.dart';
import 'package:linksys_app/route/constants.dart';

import 'package:linksys_app/util/in_app_browser.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

enum AdminPasswordType { create, reset }

class CreateAdminPasswordView extends ArgumentsConsumerStatefulView {
  const CreateAdminPasswordView({Key? key, super.args}) : super(key: key);

  @override
  ConsumerState<CreateAdminPasswordView> createState() =>
      _CreateAdminPasswordViewState();
}

class _CreateAdminPasswordViewState
    extends ConsumerState<CreateAdminPasswordView> {
  bool _isValidData = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  AdminPasswordType _type = AdminPasswordType.create;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController hintController = TextEditingController();

  void _checkInputData(_) {
    setState(() {
      _isValidData = passwordController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.args.containsKey('type')) {
      _type = widget.args['type'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const AppFullScreenSpinner(
            text: 'Processing',
          )
        : _isSuccess
            ? _successView()
            : _contentView();
  }

  Widget _successView() {
    return AppPageView.noNavigationBar(
      child: AppBasicLayout(
        header: BasicHeader(
          title:
              getAppLocalizations(context).create_router_password_reset_success,
        ),
        content: Column(
          children: [
            const AppGap.extraBig(),
            AppPrimaryButton(
              getAppLocalizations(context).go_to_dashboard,
              onTap: () {
                context.goNamed(RouteNamed.dashboardHome);
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _contentView() {
    return StyledAppPageView(
      scrollable: true,
      child: AppBasicLayout(
        header: BasicHeader(
          title: _type == AdminPasswordType.reset
              ? getAppLocalizations(context).create_router_password_reset_title
              : getAppLocalizations(context).create_router_password_title,
          description:
              getAppLocalizations(context).create_router_password_subtitle,
        ),
        content: Column(
          children: [
            AppPadding(
              padding: const AppEdgeInsets.symmetric(vertical: AppGapSize.big),
              child: AppPasswordField(
                headerText: getAppLocalizations(context).password,
                hintText: 'Enter Password',
                controller: passwordController,
                onChanged: _checkInputData,
              ),
            ),
            AppTextField(
              headerText: getAppLocalizations(context).password_hint,
              hintText: 'Add a hint',
              controller: hintController,
              onChanged: _checkInputData,
            ),
            const AppGap.extraBig(),
            const AppGap.extraBig(),
            AppTertiaryButton(
                getAppLocalizations(context)
                    .create_router_password_how_to_access, onTap: () {
              MoabInAppBrowser.withDefaultOption().openUrlRequest(
                  urlRequest: URLRequest(
                      url: Uri.parse('https://www.linksys.com/us/')));
            })
          ],
        ),
        footer: Visibility(
          visible: _isValidData,
          child: AppPrimaryButton(
            getAppLocalizations(context).next,
            onTap: () {
              if (_type == AdminPasswordType.create) {
              } else {
                _createPassword(passwordController.text, hintController.text);
              }
            },
          ),
        ),
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  _createPassword(String password, String hint) async {
    _setLoading(true);
    await ref
        .read(networkProvider.notifier)
        .createAdminPassword(password, hint)
        .then((value) {
      setState(() {
        _isSuccess = true;
      });
    });
    _setLoading(false);
  }

  _setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }
}
