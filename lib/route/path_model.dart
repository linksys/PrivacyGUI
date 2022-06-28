import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/page/components/customs/customs.dart';
import 'package:moab_poc/page/create_account/view/view.dart';
import 'package:moab_poc/page/landing/view/view.dart';
import 'package:moab_poc/page/login/view/view.dart';
import 'package:moab_poc/page/poc/dashboard/dashboard_view.dart';
import 'package:moab_poc/page/setup/view/view.dart';
import 'package:moab_poc/util/logger.dart';

import 'route.dart';

enum PageNavigationType { back, close, none }


class PathConfig {
  bool removeFromHistory = false;
}

class PageConfig {
  PageNavigationType navType = PageNavigationType.back;
  ThemeData themeData = MoabTheme.mainLightModeData;
  bool isFullScreenDialog = false;
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
        return Center(
          child: Text("Unknown Path"),
        );
      default:
        return Center();
    }
  }
}

class HomePath extends BasePath<HomePath> {}

class UnknownPath extends BasePath<UnknownPath> {}

abstract class SetupPath<P> extends BasePath<P> {

  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case SetupWelcomeEulaPath:
        return GetWiFiUpView();
      case SetupCustomizeSSIDPath:
        return CustomizeWifiView();
      case SetupNodesDonePath:
        return NodesSuccessView();
      case SetupFinishPath:
        return SetupFinishedView();
      default:
        return Center();
    }
  }
}

class SetupWelcomeEulaPath extends SetupPath<SetupWelcomeEulaPath> {}

class SetupCustomizeSSIDPath extends SetupPath<SetupCustomizeSSIDPath> {}

class SetupNodesDonePath extends SetupPath<SetupNodesDonePath> {}

class SetupFinishPath extends SetupPath<SetupFinishPath> {}

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
        return SetLocationView();
      case SetupParentQrCodeScanPath:
        return ParentScanQRCodeView();
      default:
        return Center();
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

// Internet Check Flow
abstract class InternetCheckPath<P> extends SetupPath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case InternetCheckingPath:
        return CheckNodeInternetView();

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
        return AddChildScanQRCodeView();
      case SetupNthChildPlugPath:
        return AddChildPlugView();
      case SetupNthChildSearchingPath:
        return AddChildSearchingView();
      case SetupNthChildLocationPath:
        return SetLocationView();
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

abstract class CreateAccountPath<P> extends BasePath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case CreateCloudAccountPath:
        return AddAccountView(args: args,);
      case CreateAdminPasswordPath:
        return CreateAdminPasswordView();
      case ChooseLoginMethodPath:
        return ChooseLoginTypeView(args: args,);
      case ChooseLoginOtpMethodPath:
        return ChooseOTPMethodView(args: args);
      case EnterOtpPath:
        if (args != null) {
          args!['onNext'] = SaveCloudSettingsPath();
        }
        return OtpView(args: args,);
      case SaveCloudSettingsPath:
        return SaveSettingsView();
      case AlreadyHaveOldAccountPath:
        return const HaveOldAccountView();
      case EnableTwoSVPath:
        return EnableTwoSVView();
      default:
        return const Center();
    }
  }
}

class CreateCloudAccountPath extends CreateAccountPath<CreateCloudAccountPath> {
}

class CreateAdminPasswordPath
    extends CreateAccountPath<CreateAdminPasswordPath> {}

class ChooseLoginMethodPath extends CreateAccountPath<ChooseLoginMethodPath> {}

class ChooseLoginOtpMethodPath
    extends CreateAccountPath<ChooseLoginOtpMethodPath> {}

class EnterOtpPath extends CreateAccountPath<EnterOtpPath> {}

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

class EnableTwoSVPath extends CreateAccountPath<EnableTwoSVPath> {}

abstract class AuthenticatePath<P> extends BasePath<P> {

  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case AuthInputAccountPath:
        return LoginCloudAccountView();
      case AuthChooseOtpPath:
        return LoginOTPMethodsView(args: args,);
      case AuthInputOtpPath:
        if (args != null) {
          args!['onNext'] = NoRouterPath();
        }
        return OtpView(args: args);
      case AuthForgotEmailPath:
        return const ForgotEmailView();
      case NoRouterPath:
        return NoRouterView();
      case AuthCreateAccountPhonePath:
        return CreateAccountPhoneView(args: args,);
      case SelectPhoneRegionCodePath:
        return const RegionPickerView();
      case AuthLocalLoginPath:
        return EnterRouterPasswordView();
      default:
        return const Center();
    }
  }
}

class AuthInputAccountPath extends AuthenticatePath<AuthInputAccountPath> {}

class AuthChooseOtpPath extends AuthenticatePath<AuthChooseOtpPath> {}

class AuthInputOtpPath extends AuthenticatePath<AuthInputOtpPath> {}

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

class AuthLocalLoginPath extends AuthenticatePath<AuthLocalLoginPath> {}

abstract class DebugToolsPath<P> extends BasePath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case DebugToolsMainPath:
        return const DebugToolsView();
      default:
        return Center();
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
        return Center();
    }
  }
}

class DashboardMainPath extends DashboardPath<DashboardMainPath> {}