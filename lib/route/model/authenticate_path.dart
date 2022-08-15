import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/components/customs/customs.dart';
import 'package:linksys_moab/page/login/view/view.dart';
import 'package:linksys_moab/page/otp_flow/otp_flow.dart';
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
        return CloudLoginAccountView(
          args: args,
          next: next ?? AuthCloudReadyForLoginPath(),
        );
      case AuthSetupLoginPath:
        return CloudLoginAccountView(
          args: args,
          next: next ?? SaveCloudSettingsPath(),
        );
      case AuthCloudLoginOtpPath:
        return OtpFlowView(
          args: args,
          next: next ?? AuthCloudReadyForLoginPath(),
        );
      case AuthForgotEmailPath:
        return const ForgotEmailView();
      case SelectPhoneRegionCodePath:
        return const RegionPickerView();
      case AuthLocalLoginPath:
        return const EnterRouterPasswordView();
      case AuthCloudLoginWithPasswordPath:
        return CloudLoginPasswordView(
          args: args,
          next: next,
        );
      case AuthCloudForgotPasswordPath:
        return CloudForgotPasswordView();
      case AuthCloudResetPasswordPath:
        return CloudResetPasswordView();
      case AuthLocalRecoveryKeyPath:
        return LocalRecoveryKeyView();
      case AuthResetLocalOtpPath:
        return OtpFlowView(
          args: args,
          next: DashboardMainPath(),
        );
      case AuthLocalResetPasswordPath:
        return CreateAdminPasswordView(
          args: args,
        );
      case AuthCloudReadyForLoginPath:
        return CloudReadyForLoginView(args: args,);
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

class AuthSetupLoginPath extends AuthenticatePath {}

// Local Login

class AuthLocalLoginPath extends AuthenticatePath {}

class AuthLocalRecoveryKeyPath extends AuthenticatePath {}

class AuthLocalResetPasswordPath extends AuthenticatePath {}
