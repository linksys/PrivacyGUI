import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeView extends ArgumentsConsumerStatefulView {
  const HomeView({Key? key, super.args}) : super(key: key);

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  bool _isOpenDebug = false;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      backState: StyledBackState.none,
      child: _isLoading
          ? const AppFullScreenSpinner(
              text: 'Loading...',
            )
          : AppBasicLayout(
              content: _content(context),
              footer: _footer(context),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _content(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: GestureDetector(
            child: SvgPicture(CustomTheme.of(context).images.linksysWordmark),
            onTap: () {
              context.goNamed(RouteNamed.pnp);
            },
          ),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    return Column(children: [
      AppFilledButton.fillWidth(
        getAppLocalizations(context).login,
        key: const Key('home_view_button_login'),
        onTap: () {
          if (BuildConfig.forceCommandType == ForceCommand.local) {
            context.pushNamed(RouteNamed.localLoginPassword);
          } else {
            context.pushNamed(RouteNamed.cloudLoginAccount);
          }
        },
      ),
      const AppGap.small(),
      if (!kIsWeb)
        AppFilledButton.fillWidth(
          'Local Log in',
          key: const Key('home_view_button_local_login'),
          onTap: () async {
            // Local version flow
            context.pushNamed(RouteNamed.localLoginPassword);
          },
        ),
      Stack(
        children: [
          Center(
            child: FutureBuilder(
                future:
                    PackageInfo.fromPlatform().then((value) => value.version),
                initialData: '-',
                builder: (context, data) {
                  var version = 'version ${data.data}';
                  version = BuildConfig.forceCommandType == ForceCommand.local
                      ? version
                      : '$version ${cloudEnvTarget == CloudEnvironment.prod ? '' : cloudEnvTarget.name}';
                  // if (kDebugMode && kIsWeb) {
                  if (kIsWeb) {
                    version = '$version - ${BuildConfig.forceCommandType.name}';
                  }
                  return AppText.bodySmall(
                    version,
                  );
                }),
          ),
          if (BuildConfig.isEnableEnvPicker &&
              BuildConfig.forceCommandType != ForceCommand.local)
            Align(
                alignment: Alignment.bottomRight,
                child: AppTextButton.noPadding('Select Env', onTap: () async {
                  final _ = await showModalBottomSheet(
                      enableDrag: false,
                      context: context,
                      builder: (context) => _createEnvPicker());
                  setState(() {});
                })),
        ],
      ),
    ]);
  }

  List<Widget> showDebugButton() {
    if (_isOpenDebug) {
      return [
        const AppGap.semiBig(),
        AppTextButton(
          'Debug Tools',
          onTap: () {
            context.pushNamed(RouteNamed.debug);
          },
        ),
      ];
    } else {
      return [];
    }
  }

  _initialize() async {}

  Widget _createEnvPicker() {
    bool isLoading = false;
    return StatefulBuilder(builder: (context, setState) {
      return isLoading
          ? AppFullScreenSpinner(text: getAppLocalizations(context).processing)
          : Padding(
              padding: const EdgeInsets.all(Spacing.regular),
              child: Column(
                children: [
                  ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: CloudEnvironment.values.length,
                      itemBuilder: (context, index) => InkWell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Spacing.regular),
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
                  const AppGap.regular(),
                ],
              ),
            );
    });
  }
}
