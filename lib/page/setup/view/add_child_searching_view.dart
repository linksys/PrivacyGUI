import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/indeterminate_progressbar.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../design/colors.dart';
import 'package:linksys_moab/route/model/model.dart';

class AddChildSearchingView extends StatefulWidget {
  const AddChildSearchingView({
    Key? key,
  }) : super(key: key);


  @override
  State<AddChildSearchingView> createState() => _AddChildSearchingViewState();
}

class _AddChildSearchingViewState extends State<AddChildSearchingView> {
  bool _hasFound = false;

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
    setState(() {
      _hasFound = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    NavigationCubit.of(context).push(SetupAddingNodesPath());
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      child: BasicLayout(
        header: BasicHeader(
          title: _hasFound ? getAppLocalizations(context).found_it : getAppLocalizations(context).looking_for_your_node,
        ),
        content: Center(
          child: Column(
            children: [
              _hasFound
                  ? const Icon(
                      Icons.check,
                      color: MoabColor.listItemCheck,
                      size: 200,
                    )
                  : image,
              const SizedBox(
                height: 130,
              ),
              if (!_hasFound) const IndeterminateProgressBar(),
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
