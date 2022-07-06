import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/progress_bars/indeterminate_progressbar.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/route/model/model.dart';

class SaveSettingsView extends StatefulWidget {
  SaveSettingsView({
    Key? key,
  }) : super(key: key);


  @override
  State<SaveSettingsView> createState() => _SaveSettingsViewState();
}

class _SaveSettingsViewState extends State<SaveSettingsView> {
  @override
  void initState() {
    super.initState();
    _fakeInternetChecking();
  }

  //TODO: The svg image must be replaced
  final Widget image = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Setup Finished',
  );

  _fakeInternetChecking() async {
    await Future.delayed(const Duration(seconds: 5));
    NavigationCubit.of(context).push(SetupFinishPath());
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      child: BasicLayout(
        header: BasicHeader(
          title: AppLocalizations.of(context)!.saving_settings_view_title,
        ),
        content: Center(
          child: Column(
            children: [
              image,
              const SizedBox(
                height: 130,
              ),
              Center(
                  child: Text(
                      AppLocalizations.of(context)!.adding_nodes_more_info)
              ),
              const SizedBox(
                height: 69,
              ),
              const IndeterminateProgressBar(),
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
