
// Accounts
import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/dashboard/view/account/account_view.dart';
import 'package:linksys_moab/page/dashboard/view/account/cloud_password_validation_view.dart';
import 'package:linksys_moab/page/dashboard/view/account/input_new_password_view.dart';
import '../../page/dashboard/view/account/change_auth_mode_password_view.dart';
import '../../page/dashboard/view/account/login_method_options_view.dart';
import '../../page/otp_flow/view/otp_view.dart';
import '_model.dart';
import 'package:linksys_moab/route/_route.dart';


import 'base_path.dart';

class AccountPath extends DashboardPath {
  @override
  Widget buildPage() {
    switch (runtimeType) {
      case AccountDetailPath:
        return const AccountView();
      case CloudPasswordValidationPath:
        return CloudPasswordValidationView(
          args: args,
          next: next,
        );
      case InputNewPasswordPath:
        return InputNewPasswordView(
          args: args,
          next: next,
        );
      case LoginMethodOptionsPath:
        return LoginMethodOptionsView(
          next: LoginMethodOptionsPath(),
        );
      case OTPViewPath:
        return OtpFlowView(
          args: args,
          next: next,
        );
      case ChangeAuthModePasswordPath:
        return ChangeAuthModePasswordView(
          args: args,
          next: next,
        );
      default:
        return const Center();
    }
  }
}

class AccountDetailPath extends AccountPath {}

class CloudPasswordValidationPath extends AccountPath {}

class InputNewPasswordPath extends AccountPath {}

class LoginMethodOptionsPath extends AccountPath {}

class OTPViewPath extends AccountPath {}

class ChangeAuthModePasswordPath extends AccountPath {}