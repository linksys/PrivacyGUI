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
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

/// The entry point view for the PnP (Plug and Play) setup flow.
///
/// This view acts as a gatekeeper. It orchestrates a series of initial checks
/// and, based on the results, directs the user to the appropriate next step,
/// such as the main setup wizard, a password prompt, or a troubleshooter.
class PnpAdminView extends ArgumentsBaseConsumerStatefulView {
  const PnpAdminView({super.key, super.args});

  @override
  ConsumerState<PnpAdminView> createState() => _PnpAdminViewState();
}

/// Represents the different UI states of the [PnpAdminView].
enum _PnpAdminStatus {
  /// Performing initial checks (e.g., fetching device info).
  initializing,

  /// The router is configured, but the password is required.
  awaitingPassword,

  /// The router is in a factory default state.
  unconfigured,

  /// Actively checking for an internet connection.
  checkingInternet,

  /// Internet connection has been successfully established.
  internetConnected,

  /// A critical, unrecoverable error occurred.
  error,
}

class _PnpAdminViewState extends ConsumerState<PnpAdminView> {
  late final TextEditingController _textEditController;
  late final BasePnpNotifier pnp;
  final InputValidator _validator = InputValidator([RequiredRule()]);

  // The current UI state of this view.
  _PnpAdminStatus _status = _PnpAdminStatus.initializing;

  // Local state for the password input form.
  bool _processing = false;
  String? _inputError;
  Object? _error;
  String? _password;

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();
    pnp = ref.read(pnpProvider.notifier);
    _password = widget.args['p'] as String?;

    // Use a post-frame callback to safely call async logic from initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runInitialChecks();
    });
  }

  /// Runs the sequence of initial checks to determine the state of the router.
  Future<void> _runInitialChecks() async {
    logger.i(
        '[PnP]: Starting initial checks... ${_password != null ? 'with' : 'without'} a pre-filled password.');
    setState(() {
      _status = _PnpAdminStatus.initializing;
    });

    try {
      await pnp.runInitialChecks(_password);

      // If all checks passed, check for an interruption request from another flow.
      final routeFrom = ref.read(pnpTroubleshooterProvider).enterRouteName;
      if (routeFrom.isNotEmpty) {
        throw ExceptionInterruptAndExit(route: routeFrom);
      }

      logger.i('[PnP]: All initial checks passed. Internet is connected.');
      setState(() {
        _status = _PnpAdminStatus.internetConnected;
      });

      await Future.delayed(const Duration(seconds: 1));
      logger.i('[PnP]: Navigating to main setup wizard (pnpConfig).');
      context.goNamed(RouteNamed.pnpConfig);
    } on ExceptionFetchDeviceInfo catch (e) {
      logger.e('[PnP]: Failed to fetch device info.', error: e);
      setState(() {
        _status = _PnpAdminStatus.error;
        _error = e;
      });
    } on ExceptionRouterUnconfigured {
      logger.i('[PnP]: Router is unconfigured. Displaying unconfigured view.');
      setState(() {
        _status = _PnpAdminStatus.unconfigured;
        _password = defaultAdminPassword;
      });
    } on ExceptionInvalidAdminPassword {
      logger.w('[PnP]: Invalid admin password. Awaiting user input.');
      setState(() {
        _status = _PnpAdminStatus.awaitingPassword;
        _password = null; // Clear the invalid password
      });
    } on ExceptionNoInternetConnection {
      logger.w('[PnP]: No internet connection detected. Navigating to troubleshooter.');
      var ssid = '';
      if (_password != null) {
        ssid = pnp.getDefaultWiFiNameAndPassphrase().name;
      }
      context.goNamed(
        RouteNamed.pnpNoInternetConnection,
        extra: ssid.isEmpty ? null : {'ssid': ssid},
      );
      // Don't update state, as we are navigating away.
    } on ExceptionInterruptAndExit catch (e) {
      logger.i('[PnP]: Flow interrupted. Navigating to: ${e.route}');
      if (ref.read(authProvider).value?.loginType == LoginType.local) {
        ref.read(pollingProvider.notifier).forcePolling();
      }
      context.goNamed(e.route);
    } catch (e, stackTrace) {
      logger.e('[PnP]: An unexpected error occurred during initial checks',
          error: e, stackTrace: stackTrace);
      setState(() {
        _status = _PnpAdminStatus.error;
        _error = e;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _textEditController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Render different UI based on the current status.
    switch (_status) {
      case _PnpAdminStatus.initializing:
        return _checkFactorySettingView();
      case _PnpAdminStatus.checkingInternet:
        return _checkInternetView();
      case _PnpAdminStatus.internetConnected:
        return _internetConnectedView();
      case _PnpAdminStatus.error:
        return _checkDeviceInfoView();
      case _PnpAdminStatus.unconfigured:
      case _PnpAdminStatus.awaitingPassword:
        return _mainView();
    }
  }

  //region UI Builder Methods
  //----------------------------------------------------------------------------

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
                      '[PnP]: Error view - "Try Again" tapped, navigating to home.');
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
                child: _status == _PnpAdminStatus.unconfigured
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
          onTap: () async {
            logger.i('[PnP]: Continue tapped from unconfigured state.');
            try {
              setState(() {
                _status = _PnpAdminStatus.checkingInternet;
              });
              await pnp.checkAdminPassword(_password);
              await pnp.checkInternetConnection();
              logger.i(
                  '[PnP]: Logged in from unconfigured state, navigating to setup wizard.');
              context.goNamed(RouteNamed.pnpConfig);
            } on ExceptionNoInternetConnection {
              // This is handled by the _runInitialChecks method, but we add a catch here for this specific flow.
              logger.w('[PnP]: No internet after continuing from unconfigured state.');
              context.goNamed(RouteNamed.pnpNoInternetConnection);
            } catch (e) {
              logger.e(
                '[PnP]: Failed to continue from unconfigured state.',
                error: e,
              );
              setState(() {
                _status = _PnpAdminStatus.awaitingPassword;
              });
            }
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

  void _doLogin() async {
    logger.i('[PnP]: Login button tapped.');
    setState(() {
      _processing = true;
    });
    try {
      await pnp.checkAdminPassword(_textEditController.text);
      setState(() {
        _status = _PnpAdminStatus.checkingInternet;
      });
      await pnp.checkInternetConnection();
      logger.i(
          '[PnP]: Manual login successful, navigating to setup wizard.');
      context.goNamed(RouteNamed.pnpConfig);
    } on ExceptionInvalidAdminPassword catch (e) {
      logger.w('[PnP]: Manual login failed - invalid password.');
      setState(() {
        _error = e;
      });
    } on ExceptionNoInternetConnection {
      logger.w('[PnP]: No internet after manual login.');
      context.goNamed(RouteNamed.pnpNoInternetConnection);
    } catch (e) {
      logger.e('[PnP]: Unexpected error during manual login.', error: e);
      setState(() {
        _error = e;
      });
    }
    setState(() {
      _processing = false;
    });
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
  //endregion
}