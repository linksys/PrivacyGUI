import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

class PnpAdminView extends ArgumentsBaseConsumerStatefulView {
  const PnpAdminView({super.key, super.args});

  @override
  ConsumerState<PnpAdminView> createState() => _PnpAdminViewState();
}

class _PnpAdminViewState extends ConsumerState<PnpAdminView> {
  late final TextEditingController _textEditController;
  late final BasePnpNotifier pnp;
  final InputValidator _validator = InputValidator([
    RequiredRule(),
  ]);

  bool _internetConnected = false;
  bool _isCheckingInternet = false;
  bool _hasCheckingRouterConfigured = false;
  bool _isFactoryReset = false;
  bool _processing = false;
  String? _inputError;
  Object? _error;
  String? _password;

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();

    pnp = ref.read(pnpProvider.notifier);
    // check path include local password
    _password = widget.args['p'] as String?;
    logger.i(
        '[PnP]: Start PNP setup ${_password != null ? 'with' : 'without'} admin password');
    // verify admin password is valid
    pnp
        .fetchDeviceInfo()
        .then((_) {
          logger.i('[PnP]: Get device info successfully');
          if (_password != null) {
            // keep the admin password anyway if it exists
            pnp.setAttachedPassword(_password!);
          }
        })
        .then((_) => _checkRouterConfigured())
        .then((_) {
          logger.i('[PnP]: The router has already configured');
          final isLoggedIn = ref.read(routerRepositoryProvider).isLoggedIn();
          if (!isLoggedIn) {
            return _examineAdminPassword(_password);
          }
        })
        .then((_) => _checkInternetConnection())
        .then((_) {
          final routeFrom = ref.read(pnpTroubleshooterProvider).enterRouteName;
          if (routeFrom.isNotEmpty) {
            throw ExceptionInterruptAndExit(route: routeFrom);
          }
        })
        .then((_) {
          logger.i('[PnP]: Auto-login successfully, go to Setup page');
          context.goNamed(RouteNamed.pnpConfig);
        })
        .catchError((error, stackTrace) {
          logger.e('[PnP]: The given admin password is invalid');
          setState(() {
            _inputError = '';
            _password = null;
          });
        }, test: (error) => error is ExceptionInvalidAdminPassword)
        // .catchError((error, stackTrace) {
        //   logger.e(
        //       '[PnP Troubleshooter]: Internet connection failed - initiate the troubleshooter');
        //   if (_password != null) {
        //     pnp.fetchData().then((value) {
        //       final ssid = pnp.getDefaultWiFiNameAndPassphrase().name;
        //       context.goNamed(
        //         RouteNamed.pnpNoInternetConnection,
        //         extra: {'ssid': ssid},
        //       );
        //     }).onError((error, stackTrace) {
        //       logger.e(
        //           '[PnP Troubleshooter]: Fetch data failed (Getting SSID): $error');
        //       context.goNamed(RouteNamed.pnpNoInternetConnection);
        //     });
        //   } else {
        //     context.goNamed(RouteNamed.pnpNoInternetConnection);
        //   }
        // }, test: (error) => error is ExceptionNoInternetConnection)
        // .catchError((error, stackTrace) {
        //   logger.e('[PnP]: The router is unconfigured');
        //   setState(() {
        //     _internetChecked = true;
        //     _isFactoryReset = true;
        //     _inputError = '';
        //     _password = defaultAdminPassword;
        //   });
        // }, test: (error) => error is ExceptionRouterUnconfigured)
        .catchError((error, stackTrace) {
          final route = (error as ExceptionInterruptAndExit).route;
          logger.e('[PnP]: Interrupted and go to: $route');
          // Force polling to fetch latest data
          if (ref.read(authProvider).value?.loginType == LoginType.local) {
            ref.read(pollingProvider.notifier).forcePolling();
          }
          context.goNamed(route);
        }, test: (error) => error is ExceptionInterruptAndExit)
        .onError((error, stackTrace) {
          // All error should be handled on the above flow. Do nothing

          // logger.e('[PnP]: Uncaught Error',
          //     error: error, stackTrace: stackTrace);
          // context.goNamed(RouteNamed.pnpNoInternetConnection);
        });
  }

  @override
  void dispose() {
    super.dispose();

    _textEditController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _internetConnected ? _internetConnectedView() : !_isCheckingInternet ? _mainView() : _checkInternetView();
  }

  Widget _internetConnectedView() {
return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LinksysIcons.globe,
                  semanticLabel: 'globe',
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
                const AppGap.medium(),
                AppText.titleMedium(loc(context).launchInternetConnected),
              ],
            ),
          );
  }
  Widget _checkInternetView() {
    
        return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppSpinner(
                  semanticLabel: 'Check Internet spinner',
                ),
                const AppGap.medium(),
                AppText.titleMedium(loc(context).launchCheckInternet),
              ],
            ),
          );
  }

  Widget _unconfiguredView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.headlineSmall(loc(context).pnpFactoryResetTitle),
        const AppGap.medium(),
        AppText.bodyLarge(loc(context).pnpFactoryResetDesc),
        const AppGap.large5(),
        AppFilledButton(
          loc(context).textContinue,
          onTap: () {
            _examineAdminPassword(_password).then((_) {
              return _checkInternetConnection();
            }).then((_) {
              logger.i(
                  '[PnP]: Logged in successfully by given password, go to Setup page');
              context.goNamed(RouteNamed.pnpConfig);
            }).onError((error, stackTrace) {
              logger.e(
                '[PnP]: ${_password == null ? 'There is no admin password, bring up the input view' : 'The given password is invalid'}',
              );
              setState(() {
                _isFactoryReset = false;
              });
            });
          },
        ),
      ],
    );
  }

  Widget _routerPasswordView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.headlineSmall(loc(context).welcome),
        const AppGap.medium(),
        AppText.bodyLarge(loc(context).pnpRouterLoginDesc),
        const AppGap.large3(),
        AppPasswordField(
          hintText: loc(context).routerPassword,
          border: const OutlineInputBorder(),
          controller: _textEditController,
          errorText: _inputError?.isEmpty ?? true ? null : _inputError,
          onFocusChanged: (focused) {
            if (focused) {
              setState(() {
                _inputError = null;
                _error = null;
              });
            }
          },
          onChanged: (value) {
            setState(() {
              _inputError = value.isEmpty
                  ? ''
                  : _validator.validate(value)
                      ? null
                      : 'Password should not be empty';
            });
          },
          onSubmitted: (_) {
            if (_inputError == null && !_processing) {
              _doLogin();
            }
          },
        ),
        ..._checkError(context, _error),
        const AppGap.large3(),
        AppTextButton.noPadding(
          loc(context).pnpRouterLoginWhereIsIt,
          onTap: () {
            _showRouterPasswordModal();
          },
        ),
        const AppGap.large5(),
        AppFilledButton(
          loc(context).login,
          onTap: _inputError == null && !_processing
              ? () {
                  _doLogin();
                }
              : null,
        ),
      ],
    );
  }

  Widget _mainView() {
    final deviceInfo =
        ref.watch(pnpProvider.select((value) => value.deviceInfo));
    return !_hasCheckingRouterConfigured
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppSpinner(
                  semanticLabel: 'Initialize spinner',
                ),
                const AppGap.medium(),
                AppText.titleMedium(loc(context).processing),
              ],
            ),
          )
        : StyledAppPageView(
            scrollable: true,
            appBarStyle: AppBarStyle.none,
            backState: StyledBackState.none,
            enableSafeArea: (
              bottom: true,
              top: false,
              left: true,
              right: false
            ),
            child: Center(
              child: AppCard(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image(
                      image: CustomTheme.of(context).images.devices.getByName(
                          routerIconTestByModel(
                              modelNumber: deviceInfo?.modelNumber ?? 'LN11')),
                      height: 160,
                      width: 160,
                      fit: BoxFit.contain,
                    ),
                    AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      child: _isFactoryReset
                          ? _unconfiguredView()
                          : _routerPasswordView(),
                    )
                  ],
                ),
              ),
            ),
          );
  }

  void _doLogin() {
    setState(() {
      _processing = true;
    });
    _examineAdminPassword(_textEditController.text)
        .then((_) => _checkInternetConnection())
        .then((_) {
      logger.i(
          '[PnP]: Logged in successfully by tapping Login, go to Setup page');
      context.goNamed(RouteNamed.pnpConfig);
    }).onError((error, stackTrace) {
      logger.e('[PnP]: The input admin password is invalid');
      setState(() {
        _error = error;
      });
    }).whenComplete(() {
      setState(() {
        _processing = false;
      });
    });
  }

  Future _checkRouterConfigured() {
    logger.i('[PnP]: Check the router configured');
    setState(() {
      _hasCheckingRouterConfigured = false;
    });
    return pnp.checkRouterConfigured().then((_) {}).catchError(
        (error, stackTrace) {
      logger.e('[PnP]: The router is unconfigured');
      setState(() {
        _isFactoryReset = true;
        _inputError = '';
        _password = defaultAdminPassword;
      });
      throw error;
    }, test: (error) => error is ExceptionRouterUnconfigured).whenComplete(() {
      setState(() {
        _hasCheckingRouterConfigured = true;
      });
    });
  }

  Future _checkInternetConnection() {
    setState(() {
      _isCheckingInternet = true;
    });
    return pnp.checkInternetConnection().then((_) async {
      logger.i('[PnP]: Check the Internet connection - OK');
      setState(() {
        _internetConnected = true;
      });
      await Future.delayed(const Duration(seconds: 1)).then((_) {
        setState(() {
          _isCheckingInternet = false;
        });
      });
    }).catchError((error, stackTrace) async {
      logger.e(
          '[PnP Troubleshooter]: Internet connection failed - initiate the troubleshooter');
      var ssid = '';
      if (_password != null) {
        ssid = await pnp.fetchData().then((value) {
          return pnp.getDefaultWiFiNameAndPassphrase().name;
        }).onError((error, stackTrace) {
          logger.e(
              '[PnP Troubleshooter]: Fetch data failed (Getting SSID): $error');
          return '';
        });
      }
      context.goNamed(
        RouteNamed.pnpNoInternetConnection,
        extra: ssid.isEmpty ? null : {'ssid': ssid},
      );
      throw error;
    }, test: (error) => error is ExceptionNoInternetConnection);
  }

  List<Widget> _checkError(BuildContext context, Object? error) {
    if (error == null) {
      return [];
    }
    if (error is ExceptionInvalidAdminPassword) {
      return [
        AppText.labelMedium(loc(context).incorrectPassword,
            color: Theme.of(context).colorScheme.error)
      ];
    }
    return [
      AppText.labelMedium('Unknown error',
          color: Theme.of(context).colorScheme.error)
    ];
  }

  Future _examineAdminPassword(String? password) {
    return pnp.checkAdminPassword(password);
  }

  _showRouterPasswordModal() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.titleLarge(loc(context).routerPassword),
            actions: [
              AppTextButton(
                loc(context).close,
                onTap: () {
                  context.pop();
                },
              )
            ],
            content: SizedBox(
              width: 312,
              child:
                  AppText.bodyMedium(loc(context).modalRouterPasswordLocation),
            ),
          );
        });
  }
}
