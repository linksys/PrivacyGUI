import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:moab_poc/route/model/model.dart';


class HomeView extends ArgumentsStatefulView {
  const HomeView({
    Key? key, super.args
  }) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isOpenDebug = false;
  final Widget logoImage = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Linksys Logo',
    height: 180,
  );

  @override
  Widget build(BuildContext context) {
    logger.d('DEBUG:: HomeView: build');
    return BasePageView(
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
        text: AppLocalizations.of(context)!.login,
        onPress: () { NavigationCubit.of(context).push(AuthInputAccountPath()); },
      ),
      const SizedBox(
        height: 24,
      ),
      SecondaryButton(
        text: AppLocalizations.of(context)!.setup_new_router,
        onPress: () { NavigationCubit.of(context).push(SetupWelcomeEulaPath()); },
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
}
