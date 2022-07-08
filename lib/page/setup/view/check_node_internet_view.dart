import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moab_poc/bloc/setup/bloc.dart';
import 'package:moab_poc/bloc/setup/state.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/progress_bars/indeterminate_progressbar.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/route/route.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../bloc/setup/event.dart';
import '../../../design/colors.dart';
import 'package:moab_poc/route/model/model.dart';

class CheckNodeInternetView extends StatefulWidget {
  const CheckNodeInternetView({
    Key? key,
  }) : super(key: key);

  @override
  State<CheckNodeInternetView> createState() => _CheckNodeInternetViewState();
}

class _CheckNodeInternetViewState extends State<CheckNodeInternetView> {
  bool _hasInternet = false;

  //TODO: The svg image must be replaced
  final Widget image = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Setup Finished',
  );

  @override
  void initState() {
    super.initState();
    _fakeInternetChecking();
  }

  _fakeInternetChecking() async {
    context.read<SetupBloc>().add(const ResumePointChanged(status: SetupResumePoint.INTERNETCHECK));
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      _hasInternet = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    NavigationCubit.of(context).push(SetupAddingNodesPath());
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).check_for_internet,
        ),
        content: Center(
          child: Column(
            children: [
              _hasInternet
                  ? const Icon(
                      Icons.check,
                      color: MoabColor.listItemCheck,
                      size: 200,
                    )
                  : image,
              const SizedBox(
                height: 130,
              ),
              if (!_hasInternet) const IndeterminateProgressBar(),
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ),
        footer: !_hasInternet ? Center(
          child: SimpleTextButton(text: getAppLocalizations(context).enter_isp_settings, onPressed: (){},),
        ) : null,
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
