import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/setup/bloc.dart';
import 'package:moab_poc/bloc/setup/event.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/in_app_browser.dart';

import '../../../bloc/setup/state.dart';

enum AdminPasswordType { create, reset }

class CreateAdminPasswordView extends ArgumentsStatefulView {
  const CreateAdminPasswordView({Key? key, super.args}) : super(key: key);

  @override
  _CreateAdminPasswordViewState createState() =>
      _CreateAdminPasswordViewState();
}

class _CreateAdminPasswordViewState extends State<CreateAdminPasswordView> {
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
    if (widget.args!.containsKey('type')) {
      _type = widget.args!['type'];
    }
    context.read<SetupBloc>().add(const ResumePointChanged(status: SetupResumePoint.ROUTERPASSWORD));
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? BasePageView.noNavigationBar(
            child: const FullScreenSpinner(
            text: 'Processing',
          ))
        : _isSuccess
            ? _SuccessView()
            : _contentView();
  }

  Widget _SuccessView() {
    return BasePageView.noNavigationBar(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context)
              .create_router_password_reset_success,
        ),
        content: Column(
          children: [
            SizedBox(
              height: 64,
            ),
            PrimaryButton(
              text: getAppLocalizations(context).go_to_dashboard,
              onPress: () {
                NavigationCubit.of(context).clearAndPush(DashboardMainPath());
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _contentView() {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: BasicHeader(
          title: _type == AdminPasswordType.reset
              ? getAppLocalizations(context).create_router_password_reset_title
              : getAppLocalizations(context).create_router_password_title,
          description:
              getAppLocalizations(context).create_router_password_subtitle,
        ),
        content: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 36, bottom: 37),
              child: InputField(
                titleText: getAppLocalizations(context).password,
                hintText: 'Enter Password',
                controller: passwordController,
                onChanged: _checkInputData,
              ),
            ),
            InputField(
              titleText: getAppLocalizations(context).password_hint,
              hintText: 'Add a hint',
              controller: hintController,
              onChanged: _checkInputData,
            ),
            const SizedBox(
              height: 100,
            ),
            SimpleTextButton(
                text: getAppLocalizations(context)
                    .create_router_password_how_to_access,
                onPressed: () {
                  MoabInAppBrowser.withDefaultOption().openUrlRequest(
                      urlRequest: URLRequest(
                          url: Uri.parse('https://www.linksys.com/us/')));
                })
          ],
        ),
        footer: Visibility(
          visible: _isValidData,
          child: PrimaryButton(
            text: getAppLocalizations(context).next,
            onPress: () {
              _createPassword(passwordController.text, hintController.text);
            },
          ),
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }

  _createPassword(String password, String hint) async {
    _setLoading(true);
    await context.read<AuthBloc>().createPassword(password, hint).then((value) {
      if (_type == AdminPasswordType.create) {
        NavigationCubit.of(context).clearAndPush(DashboardMainPath());
      } else {
        setState(() {
          _isSuccess = true;
        });
      }
    });
    _setLoading(false);
  }

  _setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }
}
