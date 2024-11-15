import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/page/components/styled/bottom_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

class LoginLocalView extends ArgumentsConsumerStatefulView {
  const LoginLocalView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<LoginLocalView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginLocalView> {
  String? _passwordHint;
  String? _errorMessage;
  int? _delayTime;
  int? _remainingAttempts;
  Timer? _timer;
  bool isCountdownJustFinished = false;
  bool _showPassword = false;
  late AuthNotifier auth;

  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    auth = ref.read(authProvider.notifier);
    //Use this to prevent errors from modifying the state during the init stage
    Future.doWhile(() => !mounted).then((value) {
      _getAdminPasswordHint();
      ref
          .read(dashboardManagerProvider.notifier)
          .checkDeviceInfo(null)
          .then((value) {
        buildBetterActions(value.services);
        _getAdminPasswordAuthStatus(value.services);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    return state.when(error: (error, stack) {
      //The countdown has been triggered and finished, but the error still exists in AsyncValue state
      //The error message should not be set again when countdown is terminated
      if (!isCountdownJustFinished) {
        // Just get the error and the countdown has yet to be triggered
        final JNAPError? jnapError = (error is JNAPError) ? error : null;
        setErrorMessage(jnapError);
      }
      return contentView();
    }, data: (state) {
      //Read password hint from the state
      _passwordHint = state.localPasswordHint;
      return contentView();
    }, loading: () {
      return const AppFullScreenSpinner();
    });
  }

  void setErrorMessage(JNAPError? error) {
    if (error != null) {
      // Check if it's the invalid admin password error from CheckAdminPassword3
      if (error.result == errorInvalidAdminPassword ||
          error.result == errorPasswordCheckDelayed) {
        // Do not re-assign the error data while the timer is still running
        if (!_isTimerRunning()) {
          final errorContent =
              jsonDecode(error.error!) as Map<String, dynamic>?;
          _delayTime = errorContent?['delayTimeRemaining'] as int?;
          _remainingAttempts = errorContent?['attemptsRemaining'] as int?;
          if (_delayTime != null) {
            // Trigger the timer as long as there is delay time
            _errorMessage = getCountdownPrompt(errorResult: error.result);
            _startTimer(errorResult: error.result);
          } else if (_remainingAttempts == 0) {
            // delay time will be absent if remaining attempts reach to 0
            // No need to count down
            setState(() {
              _errorMessage = loc(context).localLoginTooManyAttemptsTitle;
            });
          }
        }
      } else {
        // Older check admin password jnaps or other error types
        setState(() {
          _errorMessage = errorCodeHelper(context, error.result);
        });
      }
    } else {
      // Should not be here
      setState(() {
        _errorMessage = errorCodeHelper(context, '');
      });
    }
  }

  String getCountdownPrompt({String? errorResult}) {
    final result = switch (errorResult) {
      errorPasswordCheckDelayed => '',
      _ => '${loc(context).localLoginIncorrectRouterPassword}\n',
    };
    if (_remainingAttempts != null && _delayTime != null) {
      return '$result${loc(context).localLoginTryAgainIn(_delayTime!)}\n${loc(context).localLoginRemainingAttempts(_remainingAttempts!)}';
    } else {
      return loc(context).localLoginIncorrectRouterPassword;
    }
  }

  void _startTimer({String? errorResult}) {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_delayTime! < 1) {
        // Countdown has finished, clear the error message and refresh the view
        setState(() {
          _timer?.cancel();
          _delayTime = null;
          _remainingAttempts = null;
          _errorMessage = null;
          // By setting true, it prevent the error message being set again in this view updating
          isCountdownJustFinished = true;
        });
      } else {
        setState(() {
          // Keep count down the delay time and update the error message
          _delayTime = _delayTime! - 1;
          _errorMessage = getCountdownPrompt(errorResult: errorResult);
        });
      }
    });
  }

  bool _isTimerRunning() => _timer?.isActive ?? false;

  StyledAppPageView contentView() {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      scrollable: true,
      child: AppBasicLayout(
        content: Center(
          child: SizedBox(
            width: 4.col,
            child: AppCard(
              excludeSemantics: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.headlineSmall(loc(context).login),
                  const AppGap.large3(),
                  SizedBox(
                    width: 289,
                    child: AppPasswordField(
                      border: const OutlineInputBorder(),
                      controller: _passwordController,
                      hintText: loc(context).routerPassword,
                      onChanged: (value) {
                        setState(() {
                          _shouldEnableLoginButton();
                        });
                      },
                      onSubmitted: (_) {
                        if (_passwordController.text.isEmpty) {
                          return;
                        }
                        _doLogin();
                      },
                      errorText: _errorMessage,
                    ),
                  ),
                  if (_passwordHint != null &&
                      _passwordHint?.isNotEmpty == true)
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: SizedBox(
                        width: 200,
                        child: ExpansionTile(
                          title: AppText.labelMedium(
                            _showPassword
                                ? loc(context).hideHint
                                : loc(context).showHint,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tilePadding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          trailing: const SizedBox(),
                          expandedAlignment: Alignment.centerLeft,
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          onExpansionChanged: (value) {
                            setState(() {
                              _showPassword = value;
                            });
                          },
                          children: [AppText.bodySmall(_passwordHint!)],
                        ),
                      ),
                    ),
                  const AppGap.large3(),
                  AppTextButton.noPadding(
                    loc(context).forgotPassword,
                    onTap: () {
                      context.pushNamed(RouteNamed.localRouterRecovery);
                    },
                  ),
                  const AppGap.large3(),
                  AppFilledButton(
                    loc(context).login,
                    onTap: _shouldEnableLoginButton()
                        ? () {
                            _doLogin();
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        footer: const BottomBar(),
      ),
    );
  }

  bool _shouldEnableLoginButton() =>
      _passwordController.text.isNotEmpty && !_isTimerRunning();

  void _getAdminPasswordHint() {
    auth.getPasswordHint();
  }

  void _getAdminPasswordAuthStatus(List<String> services) {
    auth.getAdminPasswordAuthStatus(services).then((result) {
      if (result != null && !isCountdownJustFinished) {
        // Create the error and the countdown has yet to be triggered
        final JNAPError jnapError = JNAPError(
          result: errorPasswordCheckDelayed,
          error: jsonEncode(result),
        );
        setErrorMessage(jnapError);
      }
    });
  }

  _doLogin() {
    isCountdownJustFinished = false;
    auth.localLogin(_passwordController.text);
  }
}
