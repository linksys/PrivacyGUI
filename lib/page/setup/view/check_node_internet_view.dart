import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/progress_bars/indeterminate_progressbar.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/route/route.dart';

import '../../../design/colors.dart';

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
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      _hasInternet = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    NavigationCubit.of(context).push(SetupParentLocationPath());
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        elevation: 0,
      ),
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Checking for internet...',
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
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}