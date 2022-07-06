import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../components/layouts/basic_layout.dart';

class PlaceNodeTipsView extends StatefulWidget {
  const PlaceNodeTipsView({Key? key}) : super(key: key);

  @override
  State<PlaceNodeTipsView> createState() => _PlaceNodeTipsViewState();
}

class _PlaceNodeTipsViewState extends State<PlaceNodeTipsView> {
  final PageController _controller = PageController(initialPage: 0);
  final Widget fpoImage = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Setup Finished',
  );
  final Widget inTheOpenImage = Image.asset('assets/images/out_in_the_open.png');


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      children: [
        BasePageView.withCloseButton(
          context,
          scrollable: true,
          child: BasicLayout(
            header: BasicHeader(title: AppLocalizations.of(context)!
                .place_node_tips_first_view_title),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 44),
                fpoImage,
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
        BasePageView.withCloseButton(
            context,
          scrollable: true,
          child: BasicLayout(
            header: BasicHeader(title: AppLocalizations.of(context)!.place_node_tips_second_view_title),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 44),
                inTheOpenImage
              ],
            ),
          ),
        )
      ],
    );
  }
}