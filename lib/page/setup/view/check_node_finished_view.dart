import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/progress_bars/indeterminate_progressbar.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

// TODO nobody use this
class CheckNodeFinishedView extends StatelessWidget {
  CheckNodeFinishedView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  // final Widget image = SvgPicture.asset(
  //   'assets/images/linksys_logo_large_white.svg',
  //   semanticsLabel: 'Setup Finished',
  // );

  // TODO: Replace this to svg
  final Widget image = Image.asset('assets/images/icon_check.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Connected to internet!',
        ),
        content: Center(
          child: image,
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
