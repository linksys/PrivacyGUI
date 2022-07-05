import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/page/components/customs/customs.dart';
import 'package:moab_poc/page/components/customs/no_network_bottom_modal.dart';
import 'package:moab_poc/page/create_account/view/view.dart';
import 'package:moab_poc/page/dashboard/view/dashboard_view.dart';
import 'package:moab_poc/page/landing/view/view.dart';
import 'package:moab_poc/page/login/view/view.dart';
import 'package:moab_poc/page/setup/view/adding_nodes_view.dart';
import 'package:moab_poc/page/setup/view/no_use_account_confirm_view.dart';
import 'package:moab_poc/page/setup/view/use_same_account_prompt_view.dart';
import 'package:moab_poc/page/setup/view/view.dart';
import 'package:moab_poc/util/logger.dart';

import '../page/components/customs/otp_flow/otp_view.dart';
import '../page/setup/view/android_location_permission_denied_view.dart';
import '../page/setup/view/android_location_permission_view.dart';
import '../page/setup/view/android_manually_connect_view.dart';
import '../page/setup/view/android_qr_choice_view.dart';
import 'route.dart';

enum PageNavigationType { back, close, none }


class PathConfig {
  bool removeFromHistory = false;
}

class PageConfig {
  PageNavigationType navType = PageNavigationType.back;
  ThemeData themeData = MoabTheme.mainLightModeData;
  bool isFullScreenDialog = false;
  bool ignoreAuthChanged = false;
  bool ignoreConnectivityChanged = false;
  bool isOpaque = true;
  bool isBackDisable = false;
}

mixin ReturnablePath<T> {
  final Completer<T?> _completer = Completer();

  void complete(T? data) {
    logger.d("${describeIdentity(this)} complete with data $data");
    _completer.complete(data);
  }

  bool isComplete() => _completer.isCompleted;

  Future<T?> waitForComplete() {
    logger.d("${describeIdentity(this)} is waiting for complete...");
    return _completer.future;
  }
}

/// BasePath is the top level path class for providing to get a generic name
/// and some interfaces -
/// BasePath.buildPage() this better to implement on the sub abstract path,
/// this is because we can easy to understand the whole route in the setup.
abstract class BasePath<P> {
  Map<String, dynamic>? args;

  String get name => P.toString();

  PathConfig get pathConfig => PathConfig();

  PageConfig get pageConfig => PageConfig();

  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case HomePath:
        return HomeView(args: args,);
      case UnknownPath:
        return const Center(
          child: Text("Unknown Path"),
        );
      default:
        return const Center();
    }
  }
}

class HomePath extends BasePath<HomePath> {}

class UnknownPath extends BasePath<UnknownPath> {}

abstract class PopUpPath<P> extends BasePath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case NoInternetConnectionPath:
        return NoInternetConnectionModal();
      default:
        return Center();
    }
  }
}
class NoInternetConnectionPath extends PopUpPath<NoInternetConnectionPath> {
  @override
  PageConfig get pageConfig =>
      super.pageConfig..isFullScreenDialog = true..isOpaque = false;
}

abstract class SetupPath<P> extends BasePath<P> {

  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case SetupWelcomeEulaPath:
        return GetWiFiUpView();
      case SetupCustomizeSSIDPath:
        return const CustomizeWifiView();
      case SetupNodesDonePath:
        return const NodesSuccessView();
      case SetupFinishPath:
        return SetupFinishedView(args: args,);
      case SetupNodesDoneUnFoundPath:
        return const NodesSuccessView();
      case SetupAddingNodesPath:
        return const AddingNodesView();
      default:
        return const Center();
    }
  }
}

class SetupWelcomeEulaPath extends SetupPath<SetupWelcomeEulaPath> {}

class SetupCustomizeSSIDPath extends SetupPath<SetupCustomizeSSIDPath> {}

class SetupNodesDonePath extends SetupPath<SetupNodesDonePath> {}

class SetupNodesDoneUnFoundPath extends SetupPath<SetupNodesDoneUnFoundPath> {}

class SetupFinishPath extends SetupPath<SetupFinishPath> {}

class SetupAddingNodesPath extends SetupPath<SetupAddingNodesPath> {}

// Setup Parent Flow
abstract class SetupParentPath<P> extends SetupPath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case SetupParentPlugPath:
        return PlugNodeView();
      case SetupParentWiredPath:
        return ConnectToModemView();
      case SetupParentPlacePath:
        return PlaceNodeView();
      case SetupParentPermissionPath:
        return PermissionsPrimerView();
      case SetupParentLocationPath:
        return const SetLocationView();
      case SetupParentQrCodeScanPath:
        return const ParentScanQRCodeView();
      case SetupParentConnectWIFIPath:
        return AndroidManuallyConnectView();
      case SetupParentEasyConnectWIFIPath:
        return AndroidQRChoiceView();
      case SetupParentLocationPermissionDeniedPath:
        return const AndroidLocationPermissionDenied();
      case SetupParentManualEnterSSIDPath:
        return const ManualEnterSSIDView();
      case AndroidLocationPermissionPrimerPath:
        return AndroidLocationPermissionPrimer();
      default:
        return const Center();
    }
  }
}

class SetupParentPlugPath extends SetupParentPath<SetupParentPlugPath> {}

class SetupParentWiredPath extends SetupParentPath<SetupParentWiredPath> {}

class SetupParentPlacePath extends SetupParentPath<SetupParentPlacePath> {}

// TODO revisit - can this being a common page, not for setup specific
class SetupParentPermissionPath
    extends SetupParentPath<SetupParentPermissionPath> {}

class SetupParentQrCodeScanPath
    extends SetupParentPath<SetupParentQrCodeScanPath> {}

class SetupParentManualPath extends SetupParentPath<SetupParentManualPath> {}

class SetupParentLocationPath extends SetupParentPath<SetupParentLocationPath> {
}

class SetupParentManualEnterSSIDPath extends SetupParentPath<SetupParentManualEnterSSIDPath>{}

class SetupParentConnectWIFIPath
    extends SetupParentPath<SetupParentConnectWIFIPath> {}

class SetupParentEasyConnectWIFIPath
    extends SetupParentPath<SetupParentEasyConnectWIFIPath> {}
class SetupParentLocationPermissionDeniedPath extends SetupParentPath<SetupParentLocationPermissionDeniedPath>{}

class AndroidLocationPermissionPrimerPath extends SetupParentPath<AndroidLocationPermissionPrimerPath>{}

// Internet Check Flow
abstract class InternetCheckPath<P> extends SetupPath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case InternetCheckingPath:
        return const CheckNodeInternetView();

      default:
        return const Center();
    }
  }
}

class InternetCheckingPath extends InternetCheckPath<InternetCheckingPath> {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;

  @override
  PageConfig get pageConfig =>
      super.pageConfig..navType = PageNavigationType.none;
}

abstract class SetupChildPath<P> extends SetupPath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case SetupNthChildPath:
        return AddChildFinishedView();
      case SetupNthChildQrCodePath:
        return const AddChildScanQRCodeView();
      case SetupNthChildPlugPath:
        return AddChildPlugView();
      case SetupNthChildSearchingPath:
        return const AddChildSearchingView();
      case SetupNthChildLocationPath:
        return const SetLocationView();
      case SetupNthChildPlacePath:
        return PlaceNodeView(
            isAddOnNodes: true,
            );
      default:
        return const Center();
    }
  }
}

class SetupNthChildPath extends SetupChildPath<SetupNthChildPath> {}

class SetupNthChildQrCodePath extends SetupChildPath<SetupNthChildQrCodePath> {}

class SetupNthChildPlugPath extends SetupChildPath<SetupNthChildPlugPath> {}

class SetupNthChildSearchingPath
    extends SetupChildPath<SetupNthChildSearchingPath> {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;

  @override
  PageConfig get pageConfig =>
      super.pageConfig..navType = PageNavigationType.none;
}

class SetupNthChildLocationPath
    extends SetupChildPath<SetupNthChildLocationPath> {}

class SetupNthChildPlacePath extends SetupChildPath<SetupNthChildPlacePath> {}

abstract class CreateAccountPath<P> extends BasePath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case CreateCloudAccountPath:
        return AddAccountView(args: args,);
      case CreateAdminPasswordPath:
        return const CreateAdminPasswordView();
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
      default:
        return const Center();
    }
  }
}

class CreateCloudAccountPath extends CreateAccountPath<CreateCloudAccountPath> {
}

class SameAccountPromptPath extends CreateAccountPath<SameAccountPromptPath> {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}
class CreateAdminPasswordPath
    extends CreateAccountPath<CreateAdminPasswordPath> {}

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
      case AuthLocalResetPasswordPath:
        return const LocalResetRouterPasswordView();
      case AuthResetLocalOtpPath:
        if (args != null) {
          args!['onNext'] = DashboardMainPath();
        }
        return OtpFlowView(args: args,);
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

class AuthLocalResetPasswordPath extends AuthenticatePath<AuthLocalResetPasswordPath> {}

abstract class DebugToolsPath<P> extends BasePath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case DebugToolsMainPath:
        return const DebugToolsView();
      default:
        return const Center();
    }
  }
}

class DebugToolsMainPath extends DebugToolsPath<DebugToolsMainPath> {}

abstract class DashboardPath<P> extends BasePath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case DashboardMainPath:
        return const DashboardView();
      default:
        return const Center();
    }
  }
}

class DashboardMainPath extends DashboardPath<DashboardMainPath> {}