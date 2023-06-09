import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/consts.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/animation/hover.dart';
import 'package:linksys_widgets/widgets/animation/rotation.dart';
import 'package:linksys_widgets/widgets/animation/scale.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
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
    logger.d('home rebuild');
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

  Widget _content(BuildContext context) {
    return Container(
      alignment: Alignment.topRight,
      child: GestureDetector(
          onLongPress: () {
            setState(() {
              _isOpenDebug = !_isOpenDebug;
            });
          },
          child: SvgPicture(AppTheme.of(context).images.linksysBlackLogo)),
    );
  }

  Widget _footer(BuildContext context) {
    return Column(children: [
      AppPrimaryButton(
        getAppLocalizations(context).login,
        key: const Key('home_view_button_login'),
        onTap: () async {
          ref.read(navigationsProvider.notifier).push(AuthInputAccountPath());
        },
      ),
      AppSecondaryButton(
        getAppLocalizations(context).setup_new_router,
        key: const Key('home_view_button_setup'),
        onTap: null,
      ),
      ...showDebugButton(),
      Stack(
        children: [
          Center(
            child: FutureBuilder(
                future:
                    PackageInfo.fromPlatform().then((value) => value.version),
                initialData: '-',
                builder: (context, data) {
                  return AppText.tags(
                    'version ${data.data} ${cloudEnvTarget == CloudEnvironment.prod ? '' : cloudEnvTarget.name}',
                  );
                }),
          ),
          if (BuildConfig.isEnableEnvPicker)
            Align(
                alignment: Alignment.bottomRight,
                child:
                    AppTertiaryButton.noPadding('Select Env', onTap: () async {
                  final result = await showModalBottomSheet(
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
        AppSecondaryButton(
          'Debug Tools',
          onTap: () {
            ref.read(navigationsProvider.notifier).push(DebugToolsMainPath());
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
          : AppPadding.regular(
              child: Column(
                children: [
                  ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: CloudEnvironment.values.length,
                      itemBuilder: (context, index) => InkWell(
                            child: AppPadding(
                              padding: const AppEdgeInsets.symmetric(
                                  horizontal: AppGapSize.regular),
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
                  AppPrimaryButton(
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
