import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/core/utils/logger.dart';
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
  String? _sn;

  @override
  void initState() {
    super.initState();
    // Read query parameters - token, nid, sn, etc
    final queryParameters = widget.args;
    _token = queryParameters['token'];
    _sn = queryParameters['sn'];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool canProceed = _token != null && _sn != null;
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText.titleLarge(loc(context).login),
                            const AppGap.medium(),
                            canProceed
                                ? AppText.labelLarge(
                                    'You are log in with access token to manage $_sn, do you want to proceed?')
                                : AppText.labelLarge(
                                    'Not enough information to login'),
                            AppGap.medium(),
                            const AppGap.large3(),
                            if (BuildConfig.isEnableEnvPicker &&
                                BuildConfig.forceCommandType !=
                                    ForceCommand.local &&
                                canProceed)
                              Align(
                                  alignment: Alignment.bottomRight,
                                  child: AppTextButton.noPadding('Select Env',
                                      onTap: () async {
                                    final _ = await showModalBottomSheet(
                                        enableDrag: false,
                                        context: context,
                                        builder: (context) =>
                                            _createEnvPicker());
                                    setState(() {});
                                  })),
                            AppFilledButton(
                              'Proceed',
                              onTap: canProceed
                                  ? () {
                                      _cloudLogin(_token!, _sn!);
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ))),
      ),
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
                    'Save',
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

  Future<void> _cloudLogin(String token, String sn) {
    logger.d('LoginCloudView _cloudLogin: $token, $sn');
    setState(() {
      _isLoading = true;
    });

    return ref
        .read(authProvider.notifier)
        .cloudLoginAuth(
          token: token,
          sn: sn,
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
