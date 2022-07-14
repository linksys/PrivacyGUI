import 'package:flutter/widgets.dart';
import 'package:moab_poc/page/create_account/view/view.dart';
import 'package:moab_poc/route/route.dart';

import '../../page/components/customs/otp_flow/otp_view.dart';
import '../../page/setup/view/no_use_account_confirm_view.dart';
import '../../page/setup/view/save_settings_view.dart';
import '../../page/setup/view/use_same_account_prompt_view.dart';
import 'base_path.dart';

abstract class CreateAccountPath<P> extends BasePath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case CreateCloudAccountPath:
        return AddAccountView(args: args,);
      case CreateAdminPasswordPath:
        return CreateAdminPasswordView(args: args,);
      case ChooseLoginMethodPath:
        return ChooseLoginTypeView(args: args,);
      case CreateAccountOtpPath:
        if (args != null) {
          args!['onNext'] = SaveCloudSettingsPath();
        }
        return OtpFlowView(args: args,);
      case SaveCloudSettingsPath:
        return SaveSettingsView();
      case AlreadyHaveOldAccountPath:
        return const HaveOldAccountView();
      case NoUseCloudAccountPath:
        return const NoUseAccountConfirmView();
      case EnableTwoSVPath:
        return const EnableTwoSVView();
      case CreateCloudPasswordPath:
        return CreateAccountPasswordView();
      case SameAccountPromptPath:
        return UseSameAccountPromptView();
      case CreateAccount2SVPath:
        if (args != null) {
          args!['onNext'] = SaveCloudSettingsPath();
        }
        return OtpFlowView(args: args,);
      default:
        return const Center();
    }
  }
}

class CreateCloudAccountPath extends CreateAccountPath<CreateCloudAccountPath> {
}
class CreateAccount2SVPath
    extends CreateAccountPath<CreateAccount2SVPath> {}
class SameAccountPromptPath extends CreateAccountPath<SameAccountPromptPath> {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}
class CreateAdminPasswordPath
    extends CreateAccountPath<CreateAdminPasswordPath> {}

// TODO: nobody use this
class ChooseLoginMethodPath extends CreateAccountPath<ChooseLoginMethodPath> {}

class CreateAccountOtpPath extends CreateAccountPath<CreateAccountOtpPath> {}

class CreateCloudPasswordPath
    extends CreateAccountPath<CreateCloudPasswordPath> {}

class CreateCloudAccountSuccessPath
    extends CreateAccountPath<CreateCloudAccountSuccessPath> {}

class SaveCloudSettingsPath extends CreateAccountPath<SaveCloudSettingsPath> {}

class AlreadyHaveOldAccountPath
    extends CreateAccountPath<AlreadyHaveOldAccountPath> {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class NoUseCloudAccountPath extends CreateAccountPath<NoUseCloudAccountPath> {}

class EnableTwoSVPath extends CreateAccountPath<EnableTwoSVPath> {}