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
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_auto_master_flow.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_auto_master_waiting_view.dart';
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
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

class PnpAdminView extends ArgumentsBaseConsumerStatefulView {
  const PnpAdminView({super.key, super.args});

  @override
  ConsumerState<PnpAdminView> createState() => _PnpAdminViewState();
}

class _PnpAdminViewState extends ConsumerState<PnpAdminView>
    with PnpAutoMasterFlowMixin<PnpAdminView> {
  late final TextEditingController _textEditController;
  late final BasePnpNotifier pnp;
  final InputValidator _validator = InputValidator([
    RequiredRule(),
  ]);

  bool _showInternetConnected = false;
  bool _isCheckingInternet = false;
  // The first thing to do when entering this page is checking factory reset, so just show the spinner
  bool _isCheckingFactoryReset = true;
  // It will be true only if admin password check fails
  bool _hasDefaultPasswordChanged = false;
  bool _processing = false;
  String? _inputError;
  Object? _error;
  String? _password;
  bool _isFetchingDeviceInfo = false;
  bool _isWaitingForAutoMaster = false;
  bool _showAutoMasterConnectionError = false;
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
        .then((_) => _checkAutoMasterStatus())
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
          logger.e('[PnP]: Failed to fetch device info');
          // reload the page
          setState(() {
            _isFetchingDeviceInfo = true;
          });
        }, test: (error) => error is ExceptionFetchDeviceInfo)
        .catchError((error, stackTrace) {
          logger.e('[PnP]: The given admin password is invalid');
          setState(() {
            _inputError = '';
            _password = null;
          });
        }, test: (error) => error is ExceptionInvalidAdminPassword)
        .catchError((error, stackTrace) {
          logger.e('[PnP]: Auto Master polling failed, stay on error view');
          // Do nothing - UI already showing error view with retry button
        }, test: (error) => error is ExceptionAutoMasterPollingFailed)
        .catchError((error, stackTrace) {
          _promptForRotatedPassword();
        }, test: (error) => error is ExceptionAutoMasterRotatedPassword)
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
    // In order to let users see internet connected screen,
    // this has a higher priority when both showInternetConnected and isCheckingInternet are true
    if (_isFetchingDeviceInfo) {
      return _checkDeviceInfoView();
    } else if (_isWaitingForAutoMaster) {
      return PnpAutoMasterWaitingView(
        showConnectionError: _showAutoMasterConnectionError,
        onRetry: _retryAutoMasterCheck,
      );
    } else if (_showInternetConnected) {
      return _internetConnectedView();
    } else {
      if (_isCheckingInternet) {
        return _checkInternetView();
      } else {
        return _isCheckingFactoryReset
            ? _checkFactorySettingView()
            : _mainView();
      }
    }
  }

  Widget _checkDeviceInfoView() {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
      padding: EdgeInsets.zero,
      enableSafeArea: (bottom: true, top: false, left: true, right: false),
      child: (context, constraints) => AppBasicLayout(
        content: Center(
          child: AppCard(
            showBorder: false,
            color: Theme.of(context).colorScheme.background,
            padding: EdgeInsets.zero,
            child: _errorView(),
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.headlineSmall(loc(context).generalError),
              const AppGap.large5(),
              AppFilledButton(
                loc(context).tryAgain,
                onTap: () {
                  logger.d(
                      '[PnP]: Fetch device info error. Tap try again, go home.');
                  context.goNamed(RouteNamed.home);
                },
              )
            ],
          ),
        ),
      ),
    );
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

  Widget _checkFactorySettingView() {
    return Center(
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

  Widget _mainView() {
    final deviceInfo =
        ref.watch(pnpProvider.select((value) => value.deviceInfo));
    final isUnconfiguredRouter = ref.read(pnpProvider).isUnconfigured ?? false;
    return StyledAppPageView(
      scrollable: true,
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
      enableSafeArea: (bottom: true, top: false, left: true, right: false),
      child: (context, constraints) => Center(
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image(
                image: CustomTheme.of(context)
                    .getRouterImage(routerIconTestByModel(
                  modelNumber: deviceInfo?.modelNumber ?? 'LN12',
                )),
                height: 160,
                width: 160,
                fit: BoxFit.contain,
              ),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                child: isUnconfiguredRouter && !_hasDefaultPasswordChanged
                    ? _unconfiguredView()
                    : _routerPasswordView(),
              )
            ],
          ),
        ),
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
        AppText.bodyLarge(loc(context).factoryResetDesc),
        const AppGap.large5(),
        AppFilledButton(
          loc(context).textContinue,
          onTap: () {
            _examineAdminPassword(_password)
                .then((_) => _checkAutoMasterStatus())
                .then((_) => _checkInternetConnection())
                .then((_) {
              logger.i(
                  '[PnP]: Logged in successfully by given password, go to Setup page');
              if (mounted) {
                context.goNamed(RouteNamed.pnpConfig);
              }
            }).catchError((error, stackTrace) {
              final route = (error as ExceptionInterruptAndExit).route;
              logger.e('[PnP]: Interrupted, go to: $route');
              if (mounted) {
                context.goNamed(route);
              }
            }, test: (error) => error is ExceptionInterruptAndExit).catchError(
                    (error, stackTrace) {
              logger.e('[PnP]: Auto Master polling failed, stay on error view');
              // Do nothing - UI already showing error view with retry button
            },
                    test: (error) =>
                        error is ExceptionAutoMasterPollingFailed).catchError(
                    (error, stackTrace) {
              _promptForRotatedPassword();
            },
                    test: (error) =>
                        error is ExceptionAutoMasterRotatedPassword).onError(
                    (error, stackTrace) {
              logger.e(
                '[PnP]: ${_password == null ? 'There is no admin password, bring up the input view' : 'The given password is invalid'}',
              );
              setState(() {
                _hasDefaultPasswordChanged = true;
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

  void _doLogin() {
    setState(() {
      _processing = true;
    });
    _examineAdminPassword(_textEditController.text)
        // Gate on Auto Master before entering config, consistent with the
        // auto-login and default-password paths. Without this, a user manually
        // re-logging in after make-Master rotated the credential is dropped
        // straight into the WiFi form while Auto Master is still `running`, then
        // bounced again by the pre-save check — filling the form twice.
        .then((_) => _checkAutoMasterStatus())
        .then((_) => _checkInternetConnection())
        .then((_) {
      logger.i(
          '[PnP]: Logged in successfully by tapping Login, go to Setup page');
      if (mounted) {
        context.goNamed(RouteNamed.pnpConfig);
      }
    }).catchError((error, stackTrace) {
      final route = (error as ExceptionInterruptAndExit).route;
      logger.e('[PnP]: Interrupted, go to: $route');
      if (mounted) {
        context.goNamed(route);
      }
    }, test: (error) => error is ExceptionInterruptAndExit).catchError(
        (error, stackTrace) {
      // PnpAutoMasterWaitingView already shows the error + retry button.
      logger.e('[PnP]: Auto Master polling failed, stay on error view');
    }, test: (error) => error is ExceptionAutoMasterPollingFailed).catchError(
        (error, stackTrace) {
      // Auto Master finished while the user was logging in, so the password they
      // just typed is already obsolete. Ask again rather than dropping them into
      // the WiFi form — this is the primary running→complete outcome here, and
      // without an explicit branch it would fall through to the catch-all below
      // and surface a bogus "invalid password" error.
      _promptForRotatedPassword();
    }, test: (error) => error is ExceptionAutoMasterRotatedPassword).onError(
        (error, stackTrace) {
      logger.e('[PnP]: The input admin password is invalid');
      setState(() {
        _error = error;
      });
    }).whenComplete(() {
      // A redirect above may have already disposed this view; guard the
      // setState so it doesn't fire after dispose.
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    });
  }

  Future _checkRouterConfigured() {
    logger.i('[PnP]: Check the router configured');
    setState(() {
      _isCheckingFactoryReset = true;
    });
    return pnp.checkRouterConfigured().then((_) {}).catchError(
        (error, stackTrace) {
      logger.e('[PnP]: The router is unconfigured');
      setState(() {
        // _hasDefaultPasswordChanged = false;
        _inputError = '';
        _password = defaultAdminPassword;
      });
      throw error;
    }, test: (error) => error is ExceptionRouterUnconfigured).whenComplete(() {
      setState(() {
        _isCheckingFactoryReset = false;
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
        _showInternetConnected = true;
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
          return pnp.getDefaultWiFiSettings().primaryRadio?.ssid ?? '';
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
    }, test: (error) => error is ExceptionNoInternetConnection).catchError(
        (error, stackTrace) {
      // A stale credential, not a WAN fault — the internet check now tells the
      // two apart. Leave the spinner behind and rethrow so the caller's own
      // handler asks for the password; going to the troubleshooter here is
      // exactly the wrong answer (#1180: the ISP settings were fine).
      setState(() {
        _isCheckingInternet = false;
      });
      throw error;
    }, test: (error) => error is ExceptionInvalidAdminPassword);
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

  Future _checkAutoMasterStatus() async {
    final status = await pnp.checkAutoMasterStatus();
    logger.i('[PnP]: Auto Master status check result: $status');

    // make-Master already finished before this view even loaded — the
    // post-reconnect case: the router bounced us back to PnP and by the time we
    // got here the status was already `complete`. There is nothing to wait for,
    // but the admin password has been rotated all the same, so whatever
    // credential we hold is dead and the next authed call would 401.
    //
    // This has to be caught here rather than by `runAutoMasterFlow`'s
    // `completed` branch: that flow only runs when the status is `running`, so a
    // status that is *already* `complete` never reaches it.
    //
    // The other statuses deliberately fall through to the early return below:
    // - `failed` — Auto Master gave up (it found another Master), and firmware
    //   leaves the admin password untouched. The credential still works.
    // - `idle` — it has not started. Note this is the opposite of `idle` inside
    //   `_waitForCompletion`, where it means "was running, now finished and
    //   reset"; that reading is only valid once `running` has been observed.
    // - `null` — status unavailable (unreachable, or firmware that will not
    //   serve it unauthed). Nothing is known, so nothing is assumed.
    if (status == AutoMasterStatus.complete) {
      throw ExceptionAutoMasterRotatedPassword();
    }
    if (status != AutoMasterStatus.running) return;
    if (!mounted) return;

    final result = await runAutoMasterFlow(
      // Every setState here follows an await, and the make-Master window is
      // exactly when the router bounces us between routes — so this view can be
      // disposed mid-flow. The mixin only fires these while mounted.
      onEnterWaiting: () => setState(() {
        _isWaitingForAutoMaster = true;
        _showAutoMasterConnectionError = false;
      }),
      onShowConnectionError: () =>
          setState(() => _showAutoMasterConnectionError = true),
      onExitWaiting: () => setState(() => _isWaitingForAutoMaster = false),
    );

    switch (result) {
      case AutoMasterFlowResult.completed:
        // make-Master rotated the admin password, so whatever credential got us
        // here is dead and the user has to supply the new one.
        //
        // That means PnP's own password prompt, not `localLoginPassword`: the
        // local login page is where a *finished* setup lands
        // (userAcknowledgedAutoConfiguration == true). Reaching it from inside
        // PnP strands the user on a page for a flow they have not completed —
        // which is exactly the reported symptom, a reconnect landing on login
        // instead of back in PnP.
        //
        // This is the running -> complete transition only: the flow above is
        // entered exclusively from a `running` status. A view that finds Auto
        // Master already `complete` on entry is caught by the gate before this
        // point, and lands on the same prompt from there.
        throw ExceptionAutoMasterRotatedPassword();
      case AutoMasterFlowResult.proceed:
      case AutoMasterFlowResult.budgetExhausted:
        // Nothing is pending here — the next steps (internet check, then
        // pnpConfig) re-read live router state, so an unknown Auto Master
        // outcome needs no extra handling: if the credential did rotate, the
        // next authed call fails and the existing error paths take over.
        logger.i('[PnP]: Auto Master not blocking, continuing PnP flow');
        return;
      case AutoMasterFlowResult.connectionError:
        // The waiting view is showing the error + retry button.
        throw ExceptionAutoMasterPollingFailed();
    }
  }

  /// Auto Master rotated the admin password — put this view back on its own
  /// password prompt so the user can enter the new one.
  ///
  /// No navigation: this *is* the PnP entry view, so the prompt is one setState
  /// away. Clearing [_password] is the load-bearing part — it holds the
  /// credential we arrived with (the `p` route arg, or the factory default),
  /// which the rotation has just invalidated. Leaving it set would let the next
  /// precheck retry it and spend another CGI auth attempt on a password that
  /// cannot work.
  void _promptForRotatedPassword() {
    logger.i('[PnP]: Auto Master rotated the password, prompt for the new one');
    if (!mounted) return;
    setState(() {
      _isWaitingForAutoMaster = false;
      _password = null;
      _inputError = '';
      _processing = false;
    });
    pnp.setAttachedPassword(null);
    // Drop the stale local session too. `_password` and the pnp state are not
    // where the JNAP auth header comes from: it is built from the auth session's
    // stored local password, so a session left behind by a login that happened
    // *before* the rotation keeps `isLoggedIn()` true. The entry precheck then
    // skips `_examineAdminPassword` entirely — observed in #1180's QA log, where
    // no CheckAdminPassword went out at all after the reconnect — and the very
    // next authed call goes out with the dead credential.
    //
    // Logging out is safe from here: the `/pnp*` redirect branch does not watch
    // authProvider, and it leaves pnpProvider (hence `deviceInfo`) intact, so
    // this view stays put instead of being re-elected elsewhere.
    ref.read(authProvider.notifier).logout();
  }

  void _retryAutoMasterCheck() {
    setState(() {
      _showAutoMasterConnectionError = false;
    });
    _checkAutoMasterStatus().then((_) => _checkInternetConnection()).then((_) {
      logger.i('[PnP]: Retry Auto Master check succeeded, go to Setup page');
      if (mounted) {
        context.goNamed(RouteNamed.pnpConfig);
      }
    }).catchError((error, stackTrace) {
      final route = (error as ExceptionInterruptAndExit).route;
      logger.e('[PnP]: Retry interrupted, go to: $route');
      if (mounted) {
        context.goNamed(route);
      }
    }, test: (error) => error is ExceptionInterruptAndExit).catchError(
        (error, stackTrace) {
      logger.e('[PnP]: Auto Master polling failed, stay on error view');
      // Do nothing - UI already showing error view with retry button
    }, test: (error) => error is ExceptionAutoMasterPollingFailed).catchError(
        (error, stackTrace) {
      _promptForRotatedPassword();
    },
        test: (error) =>
            // Both land on the password prompt. The second arrives from the
            // internet check rather than the Auto Master gate — the status read
            // came back inconclusive, so the check ran and its 401 revealed the
            // rotation the status could not. Without this branch it would escape
            // this chain entirely as an unhandled error.
            error is ExceptionAutoMasterRotatedPassword ||
            error is ExceptionInvalidAdminPassword);
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
