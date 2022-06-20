import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/page/components/customs/customs.dart';
import 'package:moab_poc/page/create_account/view/view.dart';
import 'package:moab_poc/page/landing/view/view.dart';
import 'package:moab_poc/page/login/view/view.dart';
import 'package:moab_poc/page/setup/view/view.dart';
import 'package:moab_poc/route/navigation_cubit.dart';
import 'package:moab_poc/util/logger.dart';

enum PageNavigationType { back, close, none }

class PathConfig {
  bool removeFromFactory = false;
}

class PageConfig {
  PageNavigationType navType = PageNavigationType.back;
  ThemeData themeData = MoabTheme.setupModuleLightModeData;
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
  String get name => P.toString();

  PathConfig get pathConfig => PathConfig();

  PageConfig get pageConfig => PageConfig();

  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case HomePath:
        return HomeView(
          onLogin: () {
            // cubit.push(AuthInputAccountPath());
            cubit.push(AuthCreateAccountPhonePath());
          },
          onSetup: () {
            cubit.push(SetupWelcomeEulaPath());
          },
        );
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
  PageConfig get pageConfig =>
      super.pageConfig..themeData = MoabTheme.setupModuleLightModeData;

  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case SetupWelcomeEulaPath:
        return GetWiFiUpView(onNext: () {
          cubit.push(SetupParentPlugPath());
        });
      case SetupCustomizeSSIDPath:
        return CustomizeWifiView(
          onNext: () {
            cubit.push(CreateCloudAccountPath());
          },
          onSkip: () {
            cubit.push(CreateCloudAccountPath());
          },
        );
      case SetupNodesDonePath:
        return NodesSuccessView(onNext: () {
          cubit.push(SetupCustomizeSSIDPath());
        });
      case SetupFinishPath:
        return SetupFinishedView(
            wifiSsid: '',
            wifiPassword: '',
            onNext: () {
              // delegate.popTo(HomePath());
            });
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
        return PlugNodeView(onNext: () {
          cubit.push(SetupParentWiredPath());
        });
      case SetupParentWiredPath:
        return ConnectToModemView(onNext: () {
          cubit.push(SetupParentPlacePath());
        });
      case SetupParentPlacePath:
        return PlaceNodeView(onNext: () {
          cubit.push(SetupParentPermissionPath());
        });
      case SetupParentPermissionPath:
        return PermissionsPrimerView(onNext: () {
          cubit.push(SetupParentQrCodeScanPath());
        });
      case SetupParentLocationPath:
        return SetLocationView(onNext: () {
          cubit.push(SetupNthChildPath());
        });
      case SetupParentQrCodeScanPath:
        return ParentScanQRCodeView(onNext: () {
          cubit.push(InternetCheckingPath());
        });
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
        return CheckNodeInternetView(
          onNext: () {
            cubit.push(SetupParentLocationPath());
          },
        );

      default:
        return const Center();
    }
  }
}

class InternetCheckingPath extends InternetCheckPath<InternetCheckingPath> {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromFactory = true;

  @override
  PageConfig get pageConfig =>
      super.pageConfig..navType = PageNavigationType.none;
}

abstract class SetupChildPath<P> extends SetupPath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case SetupNthChildPath:
        return AddChildFinishedView(onAddMore: () {
          cubit.push(SetupNthChildQrCodePath());
        }, onAddDone: () {
          cubit.push(SetupNodesDonePath());
        });
      case SetupNthChildQrCodePath:
        return AddChildScanQRCodeView(onNext: () {
          cubit.push(SetupNthChildPlugPath());
        });
      case SetupNthChildPlugPath:
        return AddChildPlugView(onNext: () {
          cubit.push(SetupNthChildSearchingPath());
        });
      case SetupNthChildSearchingPath:
        return AddChildSearchingView(onNext: () {
          cubit.push(SetupNthChildLocationPath());
        });
      case SetupNthChildLocationPath:
        return SetLocationView(onNext: () {
          cubit.popTo(SetupNthChildPath());
        });
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
  PathConfig get pathConfig => super.pathConfig..removeFromFactory = true;

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
        return AddAccountView(
          onNext: () {
            cubit.push(ChooseLoginMethodPath());
          },
          onSkip: () {
            cubit.push(CreateAdminPasswordPath());
          },
        );
      case CreateAdminPasswordPath:
        return CreateAdminPasswordView(onNext: () {
          cubit.push(SaveCloudSettingsPath());
        });
      case ChooseLoginMethodPath:
        return ChooseLoginTypeView(
            onCodeNext: () {
              cubit.push(ChooseLoginOtpMethodPath());
            },
            onPasswordNext: () {
              cubit.push(EnableTwoSVPath());
            },
            onSkip: () {
              cubit.push(AlreadyHaveOldAccountPath());
            },
        );
      case ChooseLoginOtpMethodPath:
        return ChooseOTPMethodView(
            email: 'moabuser@email.com',
            onTextNext: () {
              cubit.push(EnterOtpPath());
            },
            onEmailNext: () {
              cubit.push(EnterOtpPath());
            },
        );
      case EnterOtpPath:
        return OtpView(
          onNext: () {
            cubit.push(SaveCloudSettingsPath());
          },
          destination: '(123)-456-7890',
        );
      case SaveCloudSettingsPath:
        return SaveSettingsView(onNext: () {
          cubit.push(SetupFinishPath());
        });
      case AlreadyHaveOldAccountPath:
        return const HaveOldAccountView();
      case EnableTwoSVPath:
        return EnableTwoSVView(
            onNext: () {
              cubit.push(ChooseLoginOtpMethodPath());
            },
            onSkip: () {
              cubit.push(SaveCloudSettingsPath());
            });
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

class ChooseLoginOtpMethodPath extends CreateAccountPath<ChooseLoginOtpMethodPath> {}

class EnterOtpPath extends CreateAccountPath<EnterOtpPath> {}

class CreateCloudPasswordPath
    extends CreateAccountPath<CreateCloudPasswordPath> {}

class CreateCloudAccountSuccessPath
    extends CreateAccountPath<CreateCloudAccountSuccessPath> {}

class SaveCloudSettingsPath extends CreateAccountPath<SaveCloudSettingsPath> {}

class AlreadyHaveOldAccountPath extends CreateAccountPath<AlreadyHaveOldAccountPath> {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class EnableTwoSVPath extends CreateAccountPath<EnableTwoSVPath> {}

abstract class AuthenticatePath<P> extends BasePath<P> {
  @override
  PageConfig get pageConfig =>
      super.pageConfig..themeData = MoabTheme.AuthModuleLightModeData;

  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case AuthInputAccountPath:
        return LoginCloudAccountView(
          onNext: () {
            cubit.push(AuthChooseOtpPath());
          },
          onLocalLogin: () {
            cubit.push(AuthLocalLoginPath());
          },
          onForgotEmail: () {
            cubit.push(AuthForgotEmailPath());
          },
        );
      case AuthChooseOtpPath:
        return LoginOTPMethodsView(
          onTextNext: () {
            cubit.push(AuthInputOtpPath());
          },
          onEmailNext: () {
            cubit.push(AuthInputOtpPath());
          },
        );
      case AuthInputOtpPath:
        return OtpView(
          onNext: () {
            cubit.push(NoRouterPath());
          },
          destination: '(123)-456-7890',
        );
      case AuthForgotEmailPath:
        return const ForgotEmailView();
      case NoRouterPath:
        return NoRouterView(onNext: () {}, onLogout: () {});
      case AuthCreateAccountPhonePath:
        return CreateAccountPhoneView(
          onSave: () {},
          onSkip: () {},
        );
      case SelectPhoneRegionCodePath:
        return const RegionPickerView();
      case AuthLocalLoginPath:
        return EnterRouterPasswordView(
            onNext: () {
              cubit.push(NoRouterPath());
            },
            onForgot: () {

            });
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
  PageConfig get pageConfig =>
      super.pageConfig..themeData = MoabTheme.AuthModuleLightModeData;

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
