
// Accounts
import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/dashboard/view/account/account_view.dart';
import 'package:linksys_moab/page/dashboard/view/account/cloud_password_validation_view.dart';
import 'package:linksys_moab/page/dashboard/view/account/input_new_password_view.dart';
import '_model.dart';
import 'package:linksys_moab/route/_route.dart';


import 'base_path.dart';

class AccountPath extends DashboardPath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case AccountDetailPath:
        return AccountView();
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
      default:
        return const Center();
    }
  }
}

class AccountDetailPath extends AccountPath {}

class CloudPasswordValidationPath extends AccountPath {}

class InputNewPasswordPath extends AccountPath {}