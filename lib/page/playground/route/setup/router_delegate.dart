import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/page/playground/route/setup/path_model.dart';
import 'package:moab_poc/page/setup/get_wifi_up_view.dart';
import 'package:moab_poc/page/setup/home_view.dart';
import 'package:moab_poc/page/setup/plug_node_view.dart';

import '../../../setup/check_node_finished_view.dart';
import '../../../setup/check_node_internet_view.dart';
import '../../../setup/connect_to_modem_view.dart';
import '../../../setup/manual_enter_ssid_view.dart';
import '../../../setup/parent_scan_qrcode_view.dart';
import '../../../setup/permissions_primer_view.dart';
import '../../../setup/place_node_view.dart';
import '../../../setup2/add_child_connected_view.dart';
import '../../../setup2/add_child_finished_view.dart';
import '../../../setup2/add_child_searching_view.dart';
import '../../../setup2/add_child_set_location_view.dart';
import '../../../setup2/create_account_finished_view.dart';
import '../../../setup2/create_account_password_view.dart';
import '../../../setup2/create_account_view.dart';
import '../../../setup2/create_admin_password_view.dart';
import '../../../setup2/customize_wifi_view.dart';
import '../../../setup2/nodes_success_view.dart';
import '../../../setup2/otp_code_input_view.dart';
import '../../../setup2/save_settings_view.dart';
import '../../../setup2/setup_finished_view.dart';

class SetupRouterDelegate extends RouterDelegate<SetupRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<SetupRoutePath> {
  SetupRouterDelegate() : navigatorKey = GlobalKey();

  final _stack = <SetupRoutePath>[];

  static SetupRouterDelegate of(BuildContext context) {
    final delegate = Router.of(context).routerDelegate;
    assert(delegate is SetupRouterDelegate, 'Delegate type must match');
    return delegate as SetupRouterDelegate;
  }

  @override
  SetupRoutePath get currentConfiguration {
    print('Get currentConfiguration:: ${_stack.length}');
    return _stack.isNotEmpty ? _stack.last : SetupRoutePath.home();
  }

  List<String> get stack => List.unmodifiable(_stack);
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    print(
        'SetupRouterDelegate::build:${describeIdentity(this)}.stack: [${_stack.map((e) => e.path).join(',').toString()}]');
    if (_stack.isEmpty) {
      _stack.add(SetupRoutePath.home());
    }
    return Navigator(
        key: navigatorKey,
        pages: [
          for (final configuration in _stack)
            MaterialPage(
              name: configuration.path,
              key: ValueKey(configuration.path),
              child: _pageFactory(
                  context: context,
                  path: configuration.path,
                  title: configuration.path),
            ),
        ],
        onPopPage: _onPopPage);
  }

  @override
  Future<void> setInitialRoutePath(SetupRoutePath configuration) {
    return setNewRoutePath(configuration);
  }

  @override
  Future<void> setNewRoutePath(SetupRoutePath configuration) async {
    print('SetupRouterDelegate::setNewRoutePath:${configuration.path}');
    _stack
      ..clear()
      ..add(configuration);
    return SynchronousFuture<void>(null);
  }

  void push(SetupRoutePath newRoute) {
    _stack.add(newRoute);
    notifyListeners();
  }

  void pop() {
    if (_stack.isNotEmpty) {
      _stack.remove(_stack.last);
    }
    notifyListeners();
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (_stack.isNotEmpty) {
      if (_stack.last.path == route.settings.name) {
        _stack.removeWhere((element) => element.path == route.settings.name);
        notifyListeners();
      }
    }
    return route.didPop(result);
  }

  // Mock UI pages
  Widget _pageFactory(
      {required BuildContext context,
      required String path,
      required String title}) {
    switch (path) {
      case SetupRoutePath.setupRootPrefix:
        return HomeView(
          onSetup: () {
            push(SetupRoutePath.welcome());
          },
          onLogin: () {},
        );
      case SetupRoutePath.setupWelcomeEulaPrefix:
        return GetWiFiUpView(
          onNext: () => push(SetupRoutePath.setupParentWired()),
        );
      // case SetupRoutePath.setupParentPrefix:
      //   return StartParentNodeView(
      //     onNext: () => push(SetupRoutePath.setupParentWired()),
      //   );
      case SetupRoutePath.setupParentWiredPrefix:
        return PlugNodeView(
          onNext: () => push(SetupRoutePath.setupConnectToModem()),
        );
      case SetupRoutePath.setupParentConnectToModemPrefix:
        return ConnectToModemView(
            onNext: () => push(SetupRoutePath.placeParentNode()));
      case SetupRoutePath.setupPlaceParentNodePrefix:
        return PlaceNodeView(
            onNext: () => push(SetupRoutePath.permissionPrimer()));
      case SetupRoutePath.setupParentPermissionPrimerPrefix:
        return PermissionsPrimerView(
            onNext: () => push(SetupRoutePath.setupManualParentSSID()));
      case SetupRoutePath.setupParentScanQRCodePrefix:
        return AddChildScanQRCodeView(onNext: () => push(SetupRoutePath.setupInternetCheck()));
      case SetupRoutePath.setupParentManualSSIDPrefix:
        return ManualEnterSSIDView(
          onNext: () => push(SetupRoutePath.setupParentLocation()),
        );
      case SetupRoutePath.setupParentLocationPrefix:
        return SetLocationView(onNext: () => push(SetupRoutePath.setupNthChild()));
      case SetupRoutePath.setupNthChildPrefix:
        return AddChildFinishedView(
          onAddMore: () => push(SetupRoutePath.setupPlugNthChild()),
          onAddDone: () => push(SetupRoutePath.setupCustomizeWifiSettings()),
        );
      case SetupRoutePath.setupNthchildScanQRCodePrefix:
        return AddChildScanQRCodeView(
          onNext: () {},
        );
      case SetupRoutePath.setupNthChildPlugPrefix:
        return PlugNodeView(
            onNext: () => push(SetupRoutePath.setupNthChildLooking()));
      case SetupRoutePath.setupNthChildLookingPrefix:
        return AddChildSearchingView(
            onNext: () => push(SetupRoutePath.setupNthChildFounded()));
      case SetupRoutePath.setupNthChildFoundedPrefix:
        return AddChildConnectedView(
          onNext: () => push(SetupRoutePath.setupNthChild()),
        );
      case SetupRoutePath.setupNthChildLocationPrefix:
        return SetLocationView(onNext: () {});
      case SetupRoutePath.setupNthChildSuccessPrefix:
        return NodesSuccessView(onNext: () {});
      case SetupRoutePath.setupCustomizeWifiSettingsPrefix:
        return CustomizeWifiView(
            onNext: () => push(SetupRoutePath.setupCreateCloudAccount()),
            onSkip: () => push(SetupRoutePath.setupCreateCloudAccount()));
      case SetupRoutePath.setupCreateCloudAccountPrefix:
        return CreateAccountView(
            onNext: () => push(SetupRoutePath.setupEnterOTP()),
            onSkip: () => push(SetupRoutePath.setupCreateAdminPassword()));
      case SetupRoutePath.setupCreateCloudPasswordPrefix:
        return CreateAccountPasswordView(
            onNext: () => push(SetupRoutePath.setupSaveSettings()));
      case SetupRoutePath.setupEnterOTPPrefix:
        return OtpCodeInputView(
          onNext: () => push(SetupRoutePath.setupCreateCloudAccountSuccess()),
          onSkip: () => push(SetupRoutePath.setupCreateCloudPassword()),
        );
      case SetupRoutePath.setupCreateCloudAccountSuccessPrefix:
        return CreateAccountFinishedView(
          onNext: () => push(SetupRoutePath.setupSaveSettings()),
        );
      case SetupRoutePath.setupCreateAdminPasswordPrefix:
        return CreateAdminPasswordView(
            onNext: () => push(SetupRoutePath.setupSaveSettings()));
      case SetupRoutePath.setupSaveSettingsPrefix:
        return SaveSettingsView(
            onNext: () => push(SetupRoutePath.setupFinished()));
      case SetupRoutePath.setupFinishedPrefix:
        return SetupFinishedView(
          onNext: () => push(SetupRoutePath.home()),
          wifiSsid: '',
          wifiPassword: '',
        );
      case SetupRoutePath.setupInternetCheckPrefix:
        return CheckNodeInternetView(
            onNext: () => push(SetupRoutePath.setupInternetCheckFinished()));
      case SetupRoutePath.setupInternetCheckFinishedPrefix:
        return CheckNodeFinishedView(
            onNext: () => push(SetupRoutePath.setupNthChild()));
      case SetupRoutePath.setupChildPrefix:
        return _createPage(title: 'Setup Child', callback: () {});
      default:
        return _createPage(title: 'Unknown Page', callback: () {});
    }
  }

  // Widget _pageFactory(
  //     {required BuildContext context,
  //     required String path,
  //     required String title}) {
  //   switch (path) {
  //     case SetupRoutePath.setupParentPrefix:
  //       return _createPage(
  //           title: 'Setup Parent',
  //           callback: () {
  //             SetupRouterDelegate.of(context)
  //                 .push(SetupRoutePath.setupInternetCheck());
  //           });
  //     case SetupRoutePath.setupInternetCheckPrefix:
  //       return _createPage(
  //           title: 'Internet Check',
  //           callback: () {
  //             SetupRouterDelegate.of(context).push(SetupRoutePath.setupChild());
  //           });
  //     case SetupRoutePath.setupChildPrefix:
  //       return _createPage(title: 'Setup Child', callback: () {});
  //     default:
  //       return _createPage(title: 'Unknown Page', callback: () {});
  //   }
  // }

  Widget _createPage({required String title, required VoidCallback callback}) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: callback,
          child: const Text('Next'),
        ),
      ),
    );
  }
}
