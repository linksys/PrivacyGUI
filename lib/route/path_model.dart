import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/page/create_account/add_account_view.dart';
import 'package:moab_poc/page/create_account/choose_login_type_view.dart';
import 'package:moab_poc/page/create_account/choose_otp_method_view.dart';
import 'package:moab_poc/page/create_account/enable_2sv_view.dart';
import 'package:moab_poc/page/create_account/have_old_account_view.dart';
import 'package:moab_poc/page/create_account/otp_view.dart';
import 'package:moab_poc/page/login/enter_router_password_view.dart';
import 'package:moab_poc/page/login/forgot_email_view.dart';
import 'package:moab_poc/page/login/login_otp_methods_view.dart';
import 'package:moab_poc/page/login/no_router_view.dart';
import 'package:moab_poc/page/setup/debug_tools_view.dart';
import 'package:moab_poc/page/setup/get_wifi_up_view.dart';
import 'package:moab_poc/page/setup/home_view.dart';
import 'package:moab_poc/page/login/login_cloud_account_view.dart';
import 'package:moab_poc/page/setup/parent_scan_qrcode_view.dart';
import 'package:moab_poc/page/setup/permissions_primer_view.dart';
import 'package:moab_poc/page/setup/place_node_view.dart';
import 'package:moab_poc/page/setup2/add_child_plug_view.dart';
import 'package:moab_poc/page/setup2/add_child_scan_qrcode_view.dart';
import 'package:moab_poc/page/setup2/add_child_searching_view.dart';
import 'package:moab_poc/page/setup2/create_account_phone_view.dart';
import 'package:moab_poc/page/setup2/create_account_view.dart';
import 'package:moab_poc/page/setup2/nodes_success_view.dart';
import 'package:moab_poc/page/setup2/otp_code_input_view.dart';
import 'package:moab_poc/page/setup2/save_settings_view.dart';
import 'package:moab_poc/page/setup2/set_location_view.dart';
import 'package:moab_poc/page/setup2/setup_finished_view.dart';
import 'package:moab_poc/route/route.dart';

import '../page/setup/check_node_internet_view.dart';
import '../page/setup/connect_to_modem_view.dart';
import '../page/login/login_cloud_account_otp_view.dart';
import '../page/setup/plug_node_view.dart';
import '../page/setup2/add_child_finished_view.dart';
import '../page/setup2/create_admin_password_view.dart';
import '../page/setup2/customize_wifi_view.dart';
import '../page/setup2/region_picker_view.dart';

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
    _completer.complete(data);
  }

  bool isComplete() => _completer.isCompleted;

  Future<T?> waitForComplete() {
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

  Widget buildPage(MoabRouterDelegate delegate) {
    switch (P) {
      case HomePath:
        return HomeView(
          onLogin: () {
            delegate.push(AuthInputAccountPath());
          },
          onSetup: () {
            delegate.push(SetupWelcomeEulaPath());
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
  Widget buildPage(MoabRouterDelegate delegate) {
    switch (P) {
      case SetupWelcomeEulaPath:
        return GetWiFiUpView(onNext: () {
          delegate.push(SetupParentPlugPath());
        });
      case SetupCustomizeSSIDPath:
        return CustomizeWifiView(
          onNext: () {
            delegate.push(CreateCloudAccountPath());
          },
          onSkip: () {
            delegate.push(CreateCloudAccountPath());
          },
        );
      case SetupNodesDonePath:
        return NodesSuccessView(onNext: () {
          delegate.push(SetupCustomizeSSIDPath());
        });
      case SetupFinishPath:
        return SetupFinishedView(
            wifiSsid: '',
            wifiPassword: '',
            onNext: () {
              delegate.popTo(HomePath());
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
  Widget buildPage(MoabRouterDelegate delegate) {
    switch (P) {
      case SetupParentPlugPath:
        return PlugNodeView(onNext: () {
          delegate.push(SetupParentWiredPath());
        });
      case SetupParentWiredPath:
        return ConnectToModemView(onNext: () {
          delegate.push(SetupParentPlacePath());
        });
      case SetupParentPlacePath:
        return PlaceNodeView(onNext: () {
          delegate.push(SetupParentPermissionPath());
        });
      case SetupParentPermissionPath:
        return PermissionsPrimerView(onNext: () {
          delegate.push(SetupParentQrCodeScanPath());
        });
      case SetupParentLocationPath:
        return SetLocationView(onNext: () {
          delegate.push(SetupNthChildPath());
        });
      case SetupParentQrCodeScanPath:
        return ParentScanQRCodeView(onNext: () {
          delegate.push(InternetCheckingPath());
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
  Widget buildPage(MoabRouterDelegate delegate) {
    switch (P) {
      case InternetCheckingPath:
        return CheckNodeInternetView(
          onNext: () {
            delegate.push(SetupParentLocationPath());
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
  Widget buildPage(MoabRouterDelegate delegate) {
    switch (P) {
      case SetupNthChildPath:
        return AddChildFinishedView(onAddMore: () {
          delegate.push(SetupNthChildQrCodePath());
        }, onAddDone: () {
          delegate.push(SetupNodesDonePath());
        });
      case SetupNthChildQrCodePath:
        return AddChildScanQRCodeView(onNext: () {
          delegate.push(SetupNthChildPlugPath());
        });
      case SetupNthChildPlugPath:
        return AddChildPlugView(onNext: () {
          delegate.push(SetupNthChildSearchingPath());
        });
      case SetupNthChildSearchingPath:
        return AddChildSearchingView(onNext: () {
          delegate.push(SetupNthChildLocationPath());
        });
      case SetupNthChildLocationPath:
        return SetLocationView(onNext: () {
          delegate.popTo(SetupNthChildPath());
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
  Widget buildPage(MoabRouterDelegate delegate) {
    switch (P) {
      case CreateCloudAccountPath:
        return AddAccountView(
          onNext: () {
            delegate.push(ChooseLoginMethodPath());
          },
          onSkip: () {
            delegate.push(CreateAdminPasswordPath());
          },
        );
      case CreateAdminPasswordPath:
        return CreateAdminPasswordView(onNext: () {
          delegate.push(SaveCloudSettingsPath());
        });
      case ChooseLoginMethodPath:
        return ChooseLoginTypeView(
            onCodeNext: () {
              delegate.push(ChooseLoginOtpMethodPath());
            },
            onPasswordNext: () {
              delegate.push(EnableTwoSVPath());
            },
            onSkip: () {
              delegate.push(AlreadyHaveOldAccountPath());
            },
        );
      case ChooseLoginOtpMethodPath:
        return ChooseOTPMethodView(
            email: 'moabuser@email.com',
            onTextNext: () {
              delegate.push(EnterOtpPath());
            },
            onEmailNext: () {
              delegate.push(EnterOtpPath());
            },
        );
      case EnterOtpPath:
        return OtpView(
          onNext: () {
            delegate.push(SaveCloudSettingsPath());
          },
          useSMS: true,
          destination: '(123)-456-7890',
        );
      case SaveCloudSettingsPath:
        return SaveSettingsView(onNext: () {
          delegate.push(SetupFinishPath());
        });
      case AlreadyHaveOldAccountPath:
        return const HaveOldAccountView();
      case EnableTwoSVPath:
        return EnableTwoSVView(
            onNext: () {
              delegate.push(ChooseLoginOtpMethodPath());
            },
            onSkip: () {
              delegate.push(SaveCloudSettingsPath());
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
  Widget buildPage(MoabRouterDelegate delegate) {
    switch (P) {
      case AuthInputAccountPath:
        return LoginCloudAccountView(
          onNext: () {
            delegate.push(AuthChooseOtpPath());
          },
          onLocalLogin: () {
            delegate.push(AuthLocalLoginPath());
          },
          onForgotEmail: () {
            delegate.push(AuthForgotEmailPath());
          },
        );
      case AuthChooseOtpPath:
        return LoginOTPMethodsView(
          onTextNext: () {
            delegate.push(AuthInputOtpPath());
          },
          onEmailNext: () {
            delegate.push(AuthInputOtpPath());
          },
        );
      case AuthInputOtpPath:
        return OtpView(
          onNext: () {
            delegate.push(NoRouterPath());
          },
          useSMS: true,
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
              delegate.push(NoRouterPath());
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
  Widget buildPage(MoabRouterDelegate delegate) {
    switch (P) {
      case DebugToolsMainPath:
        return const DebugToolsView();
      default:
        return Center();
    }
  }
}

class DebugToolsMainPath extends DebugToolsPath<DebugToolsMainPath> {}
