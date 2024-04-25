import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PnpIspTypeSelectionView extends ConsumerWidget {
  const PnpIspTypeSelectionView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.back,
      title: 'What type of ISP ', //'What type of ISP settings do you have?',
      child: AppBasicLayout(
        content: ListView(
          shrinkWrap: true,
          children: [
            ISPTypeCard(
              title: 'DHCP (default)',
              description:
                  'Dynamic Host Configuration Protocol (DHCP) automatically assigns IP addresses to devices connected to the network.',
              isCurrentlyApplying: true,
              tapAction: () {
                //TODO: Go To DHCP page
              },
            ),
            ISPTypeCard(
              title: 'Static IP',
              description:
                  'A static Internet Protocol (IP) address is a permanent number assigned to a computer by an internet Service Provider (ISP).',
              isCurrentlyApplying: true,
              tapAction: () {
                context.goNamed(RouteNamed.pnpStaticIp);
              },
            ),
            ISPTypeCard(
              title: loc(context).pppoe,
              description:
                  'Point-to-Point Protocol over Ethernet is a specification for connecting multiple computer users on an Ethernet local area network to a remote site.',
              isCurrentlyApplying: true,
              tapAction: () {
                context.goNamed(RouteNamed.pnpIspSettings, extra: {'needVlanId': false});
              },
            ),
            ISPTypeCard(
              title: 'PPPoE over VLAN',
              description:
                  'Sometimes your ISP may require you to have a PPPoE over VLAN to access the internet.',
              isCurrentlyApplying: true,
              tapAction: () {
                context.goNamed(RouteNamed.pnpIspSettings, extra: {'needVlanId': true});
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ISPTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isCurrentlyApplying;
  final VoidCallback tapAction;

  const ISPTypeCard({
    required this.title,
    required this.description,
    required this.isCurrentlyApplying,
    required this.tapAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: tapAction,
      child: SizedBox(
        height: 110,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(title),
                  const AppGap.small(),
                  AppText.bodyMedium(description),
                ],
              ),
            ),
            const AppGap.semiSmall(),
            isCurrentlyApplying
                ? const Icon(LinksysIcons.check)
                : const Icon(LinksysIcons.chevronRight),
          ],
        ),
      ),
    );
  }
}
