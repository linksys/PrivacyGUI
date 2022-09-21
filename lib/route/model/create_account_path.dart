import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/create_account/view/_view.dart';
import 'package:linksys_moab/page/otp_flow/view/_view.dart';
import 'package:linksys_moab/page/setup/view/_view.dart';

import 'package:linksys_moab/route/_route.dart';

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
        return OtpFlowView(
          args: args,
          next: SaveCloudSettingsPath(),
        );
      case SaveCloudSettingsPath:
        return SaveSettingsView(args: args,);
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
        return OtpFlowView(
          args: args,
          next: SaveCloudSettingsPath(),
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

