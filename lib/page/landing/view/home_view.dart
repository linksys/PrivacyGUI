import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/logger.dart';


class HomeView extends StatefulWidget {
  HomeView({
    Key? key,
    required this.onLogin,
    required this.onSetup,
  }) : super(key: key);

  final VoidCallback onLogin;
  final VoidCallback onSetup;

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
        onPress: widget.onLogin,
      ),
      const SizedBox(
        height: 24,
      ),
      SecondaryButton(
        text: AppLocalizations.of(context)!.setup_new_router,
        onPress: widget.onSetup,
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
            NavigationCubitExts.push(context, DebugToolsMainPath());
          },
        ),
      ];
    } else {
      return [];
    }
  }
}
