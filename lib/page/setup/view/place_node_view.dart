import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/page/setup/view/place_node_tips_view.dart';
import 'package:moab_poc/route/route.dart';

import '../../components/base_components/button/primary_button.dart';
import '../../components/layouts/basic_header.dart';
import 'package:moab_poc/route/model/model.dart';

class PlaceNodeView extends StatelessWidget {
  var isAddOnNodes;

  PlaceNodeView({
    Key? key,
    this.isAddOnNodes = false,
  }) : super(key: key);

  // Replace this to svg if the svg image is fixed
  final Widget image = Image.asset('assets/images/nodes_position.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
          header: _header(context),
          content: _content(context),
          footer: _footer(context)),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BasicHeader(
          title: isAddOnNodes
              ? getAppLocalizations(context).place_node_view_addOnNodes_title
              : getAppLocalizations(context).place_node_view_title,
        ),
        const SizedBox(
          height: 6,
        ),
        DescriptionText(
            text: isAddOnNodes
                ? getAppLocalizations(context)
                    .place_node_view_addOnNodes_subtitle
                : getAppLocalizations(context).place_node_view_subtitle)
      ],
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        image,
        const SizedBox(height: 14),
        SimpleTextButton(
          text: getAppLocalizations(context).placement_tips,
          onPressed: () {
            _goToPlacementTipsPage(context);
          },
        )
      ],
    );
  }

  Widget _footer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isAddOnNodes
            ? const SizedBox(height: 0)
            : DescriptionText(
                text: getAppLocalizations(context).place_node_view_content),
        const SizedBox(
          height: 27,
        ),
        PrimaryButton(
          text: getAppLocalizations(context).next,
          onPress: () {
            if (isAddOnNodes) {
              NavigationCubit.of(context).push(SetupNthChildSearchingPath());
            } else {
              NavigationCubit.of(context).push(SetupParentPermissionPath());
            }
          },
        )
      ],
    );
  }

  void _goToPlacementTipsPage(BuildContext context) {
    showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return const PlaceNodeTipsView();
        });
  }
}
