import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeView extends ArgumentsStatefulView {
  const HomeView({Key? key, super.args}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isOpenDebug = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('home rebuild');
    return _isLoading
        ? const LinksysPageView.noNavigationBar(
            child: LinksysFullScreenSpinner(
              text: 'Loading...',
            ),
          )
        : LinksysPageView(
            child: LinksysBasicLayout(
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
      LinksysPrimaryButton(
        getAppLocalizations(context).login,
        key: const Key('home_view_button_login'),
        onTap: () async {
          // TODO local auth check
          final pref = await SharedPreferences.getInstance();
          if (pref.containsKey(linksysPrefEnableBiometrics)) {
            if (await Utils.checkCertValidation()) {
              // TODO
              // bool canUseBiometrics = await Utils.canUseBiometrics();
              // if cannot use, show a alert to let user open it
              bool isPass = await Utils.doLocalAuthenticate();
              if (isPass) {
                final authBloc = context.read<AuthBloc>();
                await authBloc.requestSession();
                authBloc.add(Authorized(isCloud: true));
              } else {
                NavigationCubit.of(context).push(AuthInputAccountPath());
              }
            } else {
              NavigationCubit.of(context).push(AuthInputAccountPath());
            }
          } else {
            NavigationCubit.of(context).push(AuthInputAccountPath());
          }
        },
      ),
      LinksysSecondaryButton(
        getAppLocalizations(context).setup_new_router,
        key: const Key('home_view_button_setup'),
        onTap: () {
          NavigationCubit.of(context).push(SetupWelcomeEulaPath());
        },
      ),
      ...showDebugButton(),
      FutureBuilder(
          future: PackageInfo.fromPlatform().then((value) => value.version),
          initialData: '-',
          builder: (context, data) {
            return LinksysText.tags(
              'version ${data.data} ${cloudEnvTarget == CloudEnvironment.prod ? '' : cloudEnvTarget.name}',
            );
          }),
    ]);
  }

  List<Widget> showDebugButton() {
    if (_isOpenDebug) {
      return [
        const LinksysGap.semiBig(),
        LinksysSecondaryButton(
          'Debug Tools',
          onTap: () {
            NavigationCubit.of(context).push(DebugToolsMainPath());
          },
        ),
      ];
    } else {
      return [];
    }
  }

  _initialize() async {}
}
