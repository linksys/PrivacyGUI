import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/create_account/view/view.dart';
import 'package:linksys_moab/route/route.dart';

import '../../page/components/customs/otp_flow/otp_view.dart';
import '../../page/setup/view/no_use_account_confirm_view.dart';
import '../../page/setup/view/save_settings_view.dart';
import '../../page/setup/view/use_same_account_prompt_view.dart';
import 'base_path.dart';

abstract class CreateAccountPath extends BasePath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case CreateCloudAccountPath:
        return AddAccountView(
          args: args,
        );
      case CreateAdminPasswordPath:
        return CreateAdminPasswordView(
          args: args,
        );
      case CreateAccountOtpPath:
        if (args != null) {
          args!['onNext'] = SaveCloudSettingsPath();
        }
        return OtpFlowView(
          args: args,
        );
      case SaveCloudSettingsPath:
        return SaveSettingsView();
      case AlreadyHaveOldAccountPath:
        return const HaveOldAccountView();
      case NoUseCloudAccountPath:
        return const NoUseAccountConfirmView();
      case CreateCloudPasswordPath:
        return CreateAccountPasswordView(
          args: args,
        );
      case SameAccountPromptPath:
        return UseSameAccountPromptView();
      case CreateAccount2SVPath:
        if (args != null) {
          args!['onNext'] = SaveCloudSettingsPath();
        }
        return OtpFlowView(
          args: args,
        );
      default:
        return const Center();
    }
  }
}

class CreateCloudAccountPath extends CreateAccountPath {}

class CreateAccount2SVPath extends CreateAccountPath {}

class SameAccountPromptPath extends CreateAccountPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class CreateAdminPasswordPath extends CreateAccountPath {}

class CreateAccountOtpPath extends CreateAccountPath {}

class CreateCloudPasswordPath extends CreateAccountPath {}

class CreateCloudAccountSuccessPath extends CreateAccountPath {}

class SaveCloudSettingsPath extends CreateAccountPath {
  @override
  PageConfig get pageConfig => super.pageConfig..ignoreAuthChanged = true;
}

class AlreadyHaveOldAccountPath extends CreateAccountPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class NoUseCloudAccountPath extends CreateAccountPath {}

