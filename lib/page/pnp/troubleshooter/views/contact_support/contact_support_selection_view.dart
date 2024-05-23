import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

enum ContactSupportRegion {
  //TODO: A large area will contain more than one regions
  us(phone: '(800) 326-7114'),
  canada(phone: '1-800-326-7114'),
  latinAmerica(phone: '01 800 681 1811'),
  europe(phone: '022 008 298'),
  middleEastAndAfrica(phone: '800 844 5905'),
  asiaPacific(phone: '886-2-2656-3377');

  final String phone;

  const ContactSupportRegion({
    required this.phone,
  });

  getTitle(BuildContext context) {
    switch (this) {
      case us:
        return 'United States';
      case canada:
        return 'Canada';
      case latinAmerica:
        return 'Latin America';
      case europe:
        return 'Europe';
      case middleEastAndAfrica:
        return 'Middle East and Africa';
      case asiaPacific:
        return 'Asia Pacific';
      default:
    }
  }
}

class ContactSupportSelectionView extends ArgumentsConsumerStatelessView {
  const ContactSupportSelectionView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StyledAppPageView(
      title: 'Choose your region',
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: AppBasicLayout(
        content: ListView.builder(
          itemCount: ContactSupportRegion.values.length,
          itemBuilder: (context, index) => AppCard(
            onTap: () {
              context.goNamed(
                RouteNamed.contactSupportDetails,
                extra: {
                  'region': ContactSupportRegion.values[index],
                },
              );
            },
            child: Row(
              children: [
                Expanded(
                  child: AppText.titleMedium(
                    ContactSupportRegion.values[index].getTitle(context),
                  ),
                ),
                const Icon(LinksysIcons.chevronRight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
