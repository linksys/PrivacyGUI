import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/text/app_text.dart';

enum ContactSupportRegion {
  us(phone: '(800) 326-7114'),
  canada(phone: '1-800-326-7114');

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
      default:
    }
  }
}

class ContactSupportChoose extends ArgumentsConsumerStatelessView {
  const ContactSupportChoose({
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
