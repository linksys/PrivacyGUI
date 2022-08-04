import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/components/customs/customs.dart';
import 'package:linksys_moab/page/components/customs/otp_flow/otp_view.dart';
import 'package:linksys_moab/page/login/view/view.dart';
import 'package:linksys_moab/route/route.dart';

import '../../page/create_account/view/view.dart';
import 'model.dart';

abstract class AuthenticatePath extends BasePath {
  @override
  PageConfig get pageConfig => super.pageConfig..ignoreAuthChanged = true;

  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case AuthInputAccountPath:
        return const LoginCloudAccountView();
      case AuthCloudLoginOtpPath:
        if (args != null) {
          args!['onNext'] = AuthCloudReadyForLoginPath();
        }
        return OtpFlowView(args: args);
      case AuthForgotEmailPath:
        return const ForgotEmailView();
      case SelectPhoneRegionCodePath:
        return const RegionPickerView();
      case AuthLocalLoginPath:
        return const EnterRouterPasswordView();
      case AuthCloudLoginWithPasswordPath:
        return const LoginTraditionalPasswordView();
      case AuthCloudForgotPasswordPath:
        return const CloudForgotPasswordView();
      case AuthCloudResetPasswordPath:
        return const CloudResetPasswordView();
      case AuthLocalRecoveryKeyPath:
        return const LocalRecoveryKeyView();
      case AuthResetLocalOtpPath:
        if (args != null) {
          args!['onNext'] = DashboardMainPath();
        }
        return OtpFlowView(
          args: args,
        );
      case AuthLocalResetPasswordPath:
        return CreateAdminPasswordView(
          args: args,
        );
      case AuthCloudReadyForLoginPath:
        return const CloudReadyForLoginView();
      default:
        return const Center();
    }
  }
}

// Cloud Login

class AuthResetLocalOtpPath extends AuthenticatePath {}

class AuthInputAccountPath extends AuthenticatePath {}

class AuthCloudLoginOtpPath extends AuthenticatePath {}

class AuthCloudReadyForLoginPath extends AuthenticatePath {
  @override
  PageConfig get pageConfig => super.pageConfig..ignoreAuthChanged = false;
}

class AuthForgotEmailPath extends AuthenticatePath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class SelectPhoneRegionCodePath extends AuthenticatePath with ReturnablePath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class AuthCloudLoginWithPasswordPath extends AuthenticatePath {}

class AuthCloudForgotPasswordPath extends AuthenticatePath {}

class AuthCloudResetPasswordPath extends AuthenticatePath {}

// Local Login

class AuthLocalLoginPath extends AuthenticatePath {}

class AuthLocalRecoveryKeyPath extends AuthenticatePath {}

class AuthLocalResetPasswordPath extends AuthenticatePath {}
