import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_moab/bloc/account/_account.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/setup/_setup.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class SaveSettingsView extends ArgumentsStatefulView {
  const SaveSettingsView({Key? key, super.args}) : super(key: key);

  @override
  State<SaveSettingsView> createState() => _SaveSettingsViewState();
}

class _SaveSettingsViewState extends State<SaveSettingsView> {
  StreamSubscription? _subscription;
  late final SetupBloc _setupBloc;
  late final AuthBloc _authBloc;
  late final ConnectivityCubit _connectivityCubit;
  late final AccountCubit _accountCubit;

  @override
  void initState() {
    _setupBloc = context.read<SetupBloc>();
    _authBloc = context.read<AuthBloc>();
    _connectivityCubit = context.read<ConnectivityCubit>();
    _accountCubit = context.read<AccountCubit>();
    super.initState();
    if (widget.args['config'] != null &&
        widget.args['config'] == 'LOCALAUTHCREATEACCOUNT') {
      _setupBloc.add(LocalAuthorizedCreatAccount());
    } else {
      _setupBloc.add(SaveRouterSettings());
    }
  }

  //TODO: The svg image must be replaced
  final Widget image = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Setup Finished',
  );

  _processLogin() async {
    logger.d('SaveSettings:: _processLogin()');
    // if (_authBloc.state is AuthOnCloudLoginState) {
    //   _authBloc.add(CloudLogin());
    // } else if (_authBloc.state is AuthOnCreateAccountState) {
    //   _authBloc
    //       .createVerifiedAccount()
    //       .then((value) => _authBloc.add(CloudLogin()));
    // } else if (_setupBloc.state.adminPassword.isNotEmpty) {
    //   logger.d('SaveSettings:: _processLogin(): local login');
    //   _authBloc.localLogin(_setupBloc.state.adminPassword);
    // } else if (_authBloc.state is AuthCloudLoginState ||
    //     _authBloc.state is AuthLocalLoginState) {
    //   if (widget.args['config'] != null &&
    //       widget.args['config'] == 'LOCALAUTHCREATEACCOUNT') {
    //     NavigationCubit.of(context).popTo(AccountDetailPath());
    //   } else {
    //     NavigationCubit.of(context).clearAndPush(SetupFinishPath());
    //   }
    // }
  }

  _listenConnectivityChange(String newSSID) {
    logger.d('SaveSettings:: _listenConnectivityChange()');
    _subscription?.cancel();
    _subscription = _connectivityCubit.stream.listen((event) {
      if (Platform.isIOS) {
        if (event.connectivityInfo.ssid != newSSID) {
          return;
        }
      } else { // TODO #WORKAROUND Android current cannot get SSID
        if (event.connectivityInfo.type != ConnectivityResult.wifi) {
          return;
        }
      }
      _setupBloc.add(ResumePointChanged(
          status: SetupResumePoint.wifiConnectionBackSuccess));
      // TODO #LINKSYS
      // _tryConnectMQTT().then((value) {
      //   if (value) {
      //     logger.d('SaveSettings:: _listenConnectivityChange(): $value');
      //
      //     _setupBloc.add(FetchNetworkId());
      //   } else {
      //     _setupBloc.add(ResumePointChanged(
      //         status: SetupResumePoint.wifiConnectionBackFailed));
      //   }
      // });
    });
  }

  Future _associateNetwork() async {
    await _accountCubit.fetchAccount();
    // connect to local broker again
    // await _connectivityCubit.connectToLocalBroker();
    // get group ID, account ID from cloud
    final accountId = _accountCubit.state.id;
    final groupId = _accountCubit.state.groupId;
    // get network ID from router
    await _setupBloc.associateNetwork(accountId, groupId);
    //
  }

  // Future<bool> _tryConnectMQTT() async {
  //   logger.d('SaveSettings:: _tryConnectMQTT()');
  //   const maxRetry = 20;
  //   int retry = 0;
  //   bool isConnect = false;
  //   do {
  //     isConnect = await _connectivityCubit
  //         .connectToLocalBroker()
  //         .onError((error, stackTrace) => false);
  //     if (isConnect) {
  //       return isConnect;
  //     } else {
  //       retry++;
  //       await Future.delayed(const Duration(seconds: 6));
  //     }
  //   } while (retry < maxRetry);
  //   return isConnect;
  // }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (BuildContext context, state) {
        logger.d('SaveSettings:: AuthState changed: ${state.status}');
        if (state is AuthCloudLoginState) {
          _associateNetwork().then((value) {
            if (widget.args['config'] != null &&
                widget.args['config'] == 'LOCALAUTHCREATEACCOUNT') {
              NavigationCubit.of(context).popToOrPush(AccountDetailPath());
            } else {
              NavigationCubit.of(context).clearAndPush(SetupFinishPath());
            }
          });
        } else if (state is AuthLocalLoginState) {
          NavigationCubit.of(context).clearAndPush(SetupFinishPath());
        }
      },
      child: BlocConsumer<SetupBloc, SetupState>(
        listener: (BuildContext context, state) {
          logger.d('SaveSettings:: SetupState changed: ${state.resumePoint}');
          if (state.resumePoint == SetupResumePoint.wifiInterrupted) {
            //
            _listenConnectivityChange(state.wifiSSID);
          } else if (state.resumePoint == SetupResumePoint.finish) {
            // login
            _processLogin();
          }
        },
        builder: (context, state) {
          return BasePageView.noNavigationBar(
            child: BasicLayout(
              header: BasicHeader(
                title: getAppLocalizations(context).saving_settings_view_title,
              ),
              content: _buildContent(state),
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(SetupState state) {
    if (state.resumePoint == SetupResumePoint.wifiInterrupted) {
      return Center(
        child: Column(
          children: [
            image,
            const SizedBox(
              height: 130,
            ),
            Center(
              child: Text(
                  'Waiting for connect back to ${state.wifiSSID}, or open setting to connect it back.'),
            ),
            const SizedBox(
              height: 69,
            ),
            PrimaryButton(
              text: 'Open settings',
              onPress: () {
                openAppSettings();
              },
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      );
    } else if (state.resumePoint == SetupResumePoint.wifiConnectionBackFailed) {
      return Center(
        child: Column(
          children: [
            image,
            const SizedBox(
              height: 130,
            ),
            Center(
              child: Text(
                  'We\'re not able to establish connection to ${state.wifiSSID}, please check your WiFi connection and try again'),
            ),
            const SizedBox(
              height: 69,
            ),
            PrimaryButton(
              text: 'Try again',
              onPress: () {
                _listenConnectivityChange(state.wifiSSID);
              },
            ),
            SecondaryButton(
              text: 'Open settings',
              onPress: () {
                openAppSettings();
              },
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      );
    } else {
      return Center(
        child: Column(
          children: [
            image,
            const SizedBox(
              height: 130,
            ),
            Center(
                child:
                    Text(getAppLocalizations(context).adding_nodes_more_info)),
            const SizedBox(
              height: 69,
            ),
            const IndeterminateProgressBar(),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      );
    }
  }
}
