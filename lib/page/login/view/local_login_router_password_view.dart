import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:moab_poc/page/components/customs/network_check_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/logger.dart';

class EnterRouterPasswordView extends StatefulWidget {
  const EnterRouterPasswordView({
    Key? key,
  }) : super(key: key);

  @override
  _EnterRouterPasswordState createState() => _EnterRouterPasswordState();
}

class _EnterRouterPasswordState extends State<EnterRouterPasswordView> {
  bool _isConnectedToRouter = false;
  bool _isLoading = false;
  bool _isPasswordValidate = false;
  String _errorReason = '';

  String _hint = '';

  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // TODO check is behind router
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const FullScreenSpinner()
        : BasePageView(
            scrollable: true,
            child: _isConnectedToRouter
                ? _enterRouterPasswordView(context)
                : NetworkCheckView(
                    description:
                        getAppLocalizations(context).local_login_connect_to_your_router,
                    button: PrimaryButton(
                      text: getAppLocalizations(context).text_continue,
                      onPress: checkWifi,
                    )),
          );
  }

  void checkWifi() async {
    // TODO: check if connect to router
    setState(() {
      _isLoading = true;
      _isConnectedToRouter = true;
    });
    await context
        .read<AuthBloc>()
        .getAdminPasswordInfo()
        .then((value) => _handleAdminPasswordInfo(value));
    setState(() {
      _isLoading = false;
    });
  }

  Widget _enterRouterPasswordView(BuildContext context) {
    return BasicLayout(
      alignment: CrossAxisAlignment.start,
      header: BasicHeader(
        title: getAppLocalizations(context).local_login_title,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 44,
          ),
          InputField(
            titleText: getAppLocalizations(context).router_password,
            hintText: getAppLocalizations(context).router_password,
            controller: _passwordController,
            onChanged: _verifyPassword,
            isError: _errorReason.isNotEmpty,
          ),
          if (_errorReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                _errorReason,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    ?.copyWith(color: Colors.red),
              ),
            ),
          const SizedBox(
            height: 26,
          ),
          if (_hint.isNotEmpty)
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(getAppLocalizations(context).show_hint),
                collapsedTextColor: Theme.of(context).colorScheme.onTertiary,
                textColor: Theme.of(context).colorScheme.onTertiary,
                tilePadding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                trailing: const SizedBox(),
                expandedAlignment: Alignment.centerLeft,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(_hint)],
              ),
            ),
          SimpleTextButton(
              text: getAppLocalizations(context).forgot_router_password,
              onPressed: () {
                NavigationCubit.of(context).push(AuthLocalRecoveryKeyPath());
              }),
          const SizedBox(
            height: 37,
          ),
          PrimaryButton(
            text: getAppLocalizations(context).text_continue,
            onPress: _isPasswordValidate ? _localLogin : null,
          ),
        ],
      ),
    );
  }

  _verifyPassword(String value) async {
    setState(() {
      _isPasswordValidate = value.isNotEmpty;
    });
  }

  _localLogin() async {
    setState(() {
      _isLoading = true;
    });
    await context
        .read<AuthBloc>()
        .localLogin(_passwordController.text)
        .then((value) => NavigationCubit.of(context).clearAndPush(DashboardMainPath()))
        .onError((error, stackTrace) => _handleError(error as CloudException));
    setState(() {
      _isLoading = false;
    });
  }

  _handleAdminPasswordInfo(AdminPasswordInfo info) {
    if (!info.hasAdminPassword) {
      NavigationCubit.of(context).replace(CreateAdminPasswordPath());
    } else {
      setState(() {
        _hint = info.hint;
      });
    }
  }

  _handleError(CloudException error) {
    if (error.code == 'LOCAL_LOGIN_FAILED') {
      setState(() {
        _errorReason = error.message;
      });
    }
  }
}

// class ShowHintSection extends StatefulWidget {
//   const ShowHintSection({Key? key, required this.hint}) : super(key: key);
//
//   final String hint;
//
//   @override
//   _ShowHintSectionState createState() => _ShowHintSectionState();
// }
//
// class _ShowHintSectionState extends State<ShowHintSection> {
//   bool isShowingHint = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SimpleTextButton(
//             text: isShowingHint ? 'Hide hint' : 'Show hint',
//             onPressed: () {
//               setState(() {
//                 isShowingHint = !isShowingHint;
//               });
//             }),
//         Visibility(
//           visible: isShowingHint,
//           child: Text(widget.hint,
//               style: Theme.of(context)
//                   .textTheme
//                   .headline3
//                   ?.copyWith(color: Theme.of(context).colorScheme.primary)),
//         ),
//         SizedBox(
//           height: isShowingHint ? 54 : 18,
//         ),
//       ],
//     );
//   }
// }