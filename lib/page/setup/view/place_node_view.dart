import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../components/base_components/button/primary_button.dart';
import '../../components/layouts/basic_header.dart';

class PlaceNodeView extends StatelessWidget {
  PlaceNodeView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final VoidCallback onNext;

  // Replace this to svg if the svg image is fixed
  final Widget image = Image.asset('assets/images/nodes_position.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: _header(context),
        content: _content(context),
        footer: _footer(context)
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BasicHeader(
          title: AppLocalizations.of(context)!.place_node_view_title,
        ),
        const SizedBox(
          height: 6,
        ),
        Text(
          AppLocalizations.of(context)!.place_node_view_subtitle,
          style: Theme
              .of(context)
              .textTheme
              .headline4
              ?.copyWith(color: Theme
              .of(context)
              .colorScheme
              .primary),
        ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        image,
        Text(
          AppLocalizations.of(context)!.placement_tips,
          style: Theme
              .of(context)
              .textTheme
              .headline4
              ?.copyWith(color: Theme
              .of(context)
              .colorScheme
              .primary),
        )
      ],
    );
  }

  Widget _footer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.place_node_view_content, style: Theme
            .of(context)
            .textTheme
            .headline4
            ?.copyWith(color: Theme
            .of(context)
            .colorScheme
            .primary)
        ),
        const SizedBox(
          height: 27,
        ),
        PrimaryButton(
          text: AppLocalizations.of(context)!.next,
          onPress: onNext,
        )
      ],
    );
  }
}
