import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/timer_countdown_widget.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginCloudAuthView extends ArgumentsConsumerStatefulView {
  const LoginCloudAuthView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<LoginCloudAuthView> createState() => _LoginCloudAuthViewState();
}

class _LoginCloudAuthViewState extends ConsumerState<LoginCloudAuthView> {
  bool _isLoading = false;
  String? _token;
  String? _session;
  Object? _error;

  //
  GRASessionInfo? _sessionInfo;

  @override
  void initState() {
    super.initState();
    // Read query parameters - token, nid, sn, etc
    final queryParameters = widget.args;
    _token = queryParameters['token'];
    _session = queryParameters['session'];
    _error = queryParameters['error'];
    _isLoading = false;
    init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future init() async {
    final token = _token;
    final session = _session;
    if (token == null || session == null) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    await Future.doWhile(() => !mounted);
    final sessionInfo = _error == null
        ? await ref
            .read(authProvider.notifier)
            .testSessionAuthentication(token: token, session: session)
            .onError((error, stackTrace) {
            _error = error;
            return null;
          })
        : null;
    _sessionInfo = sessionInfo;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      scrollable: true,
      child: (context, constraints) => AppBasicLayout(
        content: Center(
            child: AppCard(
                child: _isLoading
                    ? const AppSpinner()
                    : SizedBox(
                        width: 4.col,
                        child: _error != null ? _errorView() : _mainView(),
                      ))),
      ),
    );
  }

  Widget _errorView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.labelLarge(_handleError()),
        AppGap.large1(),
      ],
    );
  }

  String _handleError() {
    final error = _error;
    if (error == null) {
      return '';
    }
    if (error is ErrorResponse) {
      return error.errorMessage ?? '';
    }
    return error.toString();
  }

  Widget _mainView() {
    bool canProceed = _token != null && _sessionInfo != null;
    final secondsLeft = (_sessionInfo?.expiredIn ?? 0) * -1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image(
          image: CustomTheme.of(context).images.devices.getByName(
                routerIconTestByModel(
                  modelNumber: _sessionInfo?.modelNumber ?? 'LN12',
                ),
              ),
          height: 120,
          width: 120,
          fit: BoxFit.contain,
        ),
        const AppGap.medium(),
        AppText.titleLarge(loc(context).login),
        const AppGap.medium(),
        canProceed
            ? AppText.labelLarge(loc(context)
                .loginWithAccessTokenMessage(_sessionInfo?.serialNumber ?? ''))
            : AppText.labelLarge(loc(context).notEnoughInfoToLogin),
        AppGap.medium(),
        if (_sessionInfo != null) ...[
          AppText.bodyMedium(
              '${loc(context).status}: ${_sessionInfo?.status.toValue()}'),
          TimerCountdownWidget(
            initialSeconds: secondsLeft,
            title: 'Session',
          ),
        ],
        const AppGap.large3(),
        if (BuildConfig.isEnableEnvPicker &&
            BuildConfig.forceCommandType != ForceCommand.local)
          Align(
            alignment: Alignment.bottomRight,
            child: AppTextButton.noPadding(
              loc(context).selectEnv,
              onTap: () async {
                final _ = await showModalBottomSheet(
                    enableDrag: false,
                    context: context,
                    builder: (context) => _createEnvPicker());
                setState(() {});
              },
            ),
          ),
        AppFilledButton(
          loc(context).proceed,
          onTap: _sessionInfo?.status == GRASessionStatus.active && canProceed
              ? () {
                  _cloudLogin(_token!, _session!);
                }
              : null,
        ),
      ],
    );
  }

  Widget _createEnvPicker() {
    bool isLoading = false;
    return StatefulBuilder(builder: (context, setState) {
      return isLoading
          ? AppFullScreenSpinner(text: loc(context).processing)
          : Padding(
              padding: const EdgeInsets.all(Spacing.medium),
              child: Column(
                children: [
                  ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: CloudEnvironment.values.length,
                      itemBuilder: (context, index) => InkWell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Spacing.medium),
                              child: AppPanelWithValueCheck(
                                title: CloudEnvironment.values[index].name,
                                valueText: '',
                                isChecked: cloudEnvTarget ==
                                    CloudEnvironment.values[index],
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                cloudEnvTarget = CloudEnvironment.values[index];
                              });
                            },
                          )),
                  const Spacer(),
                  AppFilledButton(
                    loc(context).save,
                    onTap: () async {
                      setState(() {
                        isLoading = true;
                      });

                      final pref = await SharedPreferences.getInstance();
                      pref.setString(pCloudEnv, cloudEnvTarget.name);
                      BuildConfig.load();
                      setState(() {
                        isLoading = false;
                      });
                      Navigator.pop(context, cloudEnvTarget);
                    },
                  ),
                  const AppGap.medium(),
                ],
              ),
            );
    });
  }

  Future<void> _cloudLogin(String token, String session) {
    if (_sessionInfo == null) {
      logger.e('LoginCloudView _cloudLogin: sessionInfo is null');
      return Future.value();
    }
    logger.d('LoginCloudView _cloudLogin: $token, $session');
    setState(() {
      _isLoading = true;
    });

    return ref
        .read(authProvider.notifier)
        .cloudLoginAuth(
          token: token,
          sn: _sessionInfo?.serialNumber ?? '',
          sessionInfo: _sessionInfo!,
        )
        .onError((error, stackTrace) {
      logger.e('LoginCloudView _cloudLogin error: $error');
    }).whenComplete(() {
      setState(() {
        _isLoading = false;
      });
    });
  }
}
