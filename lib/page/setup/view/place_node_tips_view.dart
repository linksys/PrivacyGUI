import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import '../../components/layouts/basic_layout.dart';

class PlaceNodeTipsView extends StatefulWidget {
  const PlaceNodeTipsView({Key? key}) : super(key: key);

  @override
  State<PlaceNodeTipsView> createState() => _PlaceNodeTipsViewState();
}

class _PlaceNodeTipsViewState extends State<PlaceNodeTipsView> {
  final PageController _controller = PageController(initialPage: 0);
  final Widget avoidInsideImage = Image.asset(
    'assets/images/avoid_place_inside.png',
  );
  final Widget inTheOpenImage =
      Image.asset('assets/images/out_in_the_open.png');

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
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BasicHeader(
                    title: getAppLocalizations(context)
                        .place_node_tips_first_view_index),
                const SizedBox(height: 8),
                BasicHeader(
                    title: getAppLocalizations(context)
                        .place_node_tips_first_view_title)
              ],
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 44),
                inTheOpenImage,
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
        BasePageView.withCloseButton(
          context,
          scrollable: true,
          child: BasicLayout(
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BasicHeader(
                    title: getAppLocalizations(context)
                        .place_node_tips_second_view_index),
                const SizedBox(height: 8),
                BasicHeader(
                    title: getAppLocalizations(context)
                        .place_node_tips_second_view_title)
              ],
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [const SizedBox(height: 44), avoidInsideImage],
            ),
          ),
        )
      ],
    );
  }
}
