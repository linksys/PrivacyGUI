import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/utils.dart';
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
  final Widget logoImage = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    key: const Key('linksys_logo'),
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
        key: const Key('home_view_button_login'),
        text: getAppLocalizations(context).login,
        onPress: () async {
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
      const SizedBox(
        height: 24,
      ),
      SecondaryButton(
        key: const Key('home_view_button_setup'),
        text: getAppLocalizations(context).setup_new_router,
        onPress: () {
          NavigationCubit.of(context).push(SetupWelcomeEulaPath());
        },
      ),
      ...showDebugButton(),
      SizedBox(
        height: 16,
      ),
      FutureBuilder(
          future:
          PackageInfo.fromPlatform().then((value) => value.version),
          initialData: '-',
          builder: (context, data) {
            return Text('version ${data.data} ${cloudEnvTarget == CloudEnvironment.prod ? '' : cloudEnvTarget.name}',
                style: Theme.of(context).textTheme.headline4?.copyWith(
                  fontWeight: FontWeight.w700,
                ));
          }),
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
  }
}
