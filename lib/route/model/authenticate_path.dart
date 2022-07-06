import 'package:flutter/widgets.dart';
import 'package:moab_poc/page/components/customs/customs.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_view.dart';
import 'package:moab_poc/page/login/view/view.dart';
import 'package:moab_poc/route/route.dart';

import '../../page/create_account/view/view.dart';
import 'base_path.dart';
import 'dashboard_path.dart';

abstract class AuthenticatePath<P> extends BasePath<P> {

  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case AuthInputAccountPath:
        return const LoginCloudAccountView();
      case AuthCloudLoginOtpPath:
        if (args != null) {
          args!['onNext'] = NoRouterPath();
        }
        return OtpFlowView(args: args);
      case AuthForgotEmailPath:
        return const ForgotEmailView();
      case NoRouterPath:
        return const NoRouterView();
      case AuthCreateAccountPhonePath:
        return CreateAccountPhoneView(args: args,);
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
        return OtpFlowView(args: args,);
      case AuthLocalResetPasswordPath:
        return CreateAdminPasswordView(args: args,);
      default:
        return const Center();
    }
  }
}

// Cloud Login

class AuthResetLocalOtpPath extends AuthenticatePath<AuthResetLocalOtpPath> {}

class AuthInputAccountPath extends AuthenticatePath<AuthInputAccountPath> {}

class AuthCloudLoginOtpPath extends AuthenticatePath<AuthCloudLoginOtpPath> {}

class NoRouterPath extends AuthenticatePath<NoRouterPath> {}

class AuthForgotEmailPath extends AuthenticatePath<AuthForgotEmailPath> {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class AuthCreateAccountPhonePath
    extends AuthenticatePath<AuthCreateAccountPhonePath> {}

class SelectPhoneRegionCodePath
    extends AuthenticatePath<SelectPhoneRegionCodePath>
    with ReturnablePath<PhoneRegion> {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class AuthCloudLoginWithPasswordPath extends AuthenticatePath<AuthCloudLoginWithPasswordPath> {}

class AuthCloudForgotPasswordPath extends AuthenticatePath<AuthCloudForgotPasswordPath> {}

class AuthCloudResetPasswordPath extends AuthenticatePath<AuthCloudResetPasswordPath> {}

// Local Login

class AuthLocalLoginPath extends AuthenticatePath<AuthLocalLoginPath> {}
class AuthLocalRecoveryKeyPath extends AuthenticatePath<AuthLocalRecoveryKeyPath> {}
class AuthLocalResetPasswordPath extends AuthenticatePath<AuthLocalResetPasswordPath> {}