import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/secondary_button.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/route/model/model.dart';

class HomeView extends ArgumentsStatefulView {
  const HomeView({Key? key, super.args}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isOpenDebug = false;
  bool _isLoading = false;
  final Widget logoImage = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Linksys Logo',
    height: 180,
  );

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('DEBUG:: HomeView: build');
    return _isLoading
        ? BasePageView.noNavigationBar(
            child: const FullScreenSpinner(
              text: 'Loading...',
            ),
          )
        : BasePageView(
            child: BasicLayout(
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
          child: logoImage),
    );
  }

  Widget _footer(BuildContext context) {
    return Column(children: [
      PrimaryButton(
        text: getAppLocalizations(context).login,
        onPress: () {
          NavigationCubit.of(context).push(AuthInputAccountPath());
        },
      ),
      const SizedBox(
        height: 24,
      ),
      SecondaryButton(
        text: getAppLocalizations(context).setup_new_router,
        onPress: () {
          NavigationCubit.of(context).push(DashboardMainPath());
        },
      ),
      ...showDebugButton()
    ]);
  }

  List<Widget> showDebugButton() {
    if (_isOpenDebug) {
      return [
        const SizedBox(
          height: 24,
        ),
        SecondaryButton(
          text: 'Debug Tools',
          onPress: () {
            NavigationCubit.of(context).push(DebugToolsMainPath());
          },
        ),
      ];
    } else {
      return [];
    }
  }

  _initialize() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    // TODO what if there has no network???
    await CloudEnvironmentManager().fetchCloudConfig();
    await CloudEnvironmentManager().fetchAllCloudConfigs();
    setState(() {
      _isLoading = false;
    });
  }
}
