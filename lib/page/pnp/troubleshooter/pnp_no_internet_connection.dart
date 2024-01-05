import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/widgets/panel/border_list_tile.dart';

class PnpNoInternetConnectionView extends ConsumerStatefulWidget {
  const PnpNoInternetConnectionView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpNoInternetConnectionView> createState() =>
      _PnpNoInternetConnectionState();
}

class _PnpNoInternetConnectionState
    extends ConsumerState<PnpNoInternetConnectionView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      backState: StyledBackState.none,
      child: AppBasicLayout(
        header: SvgPicture(CustomTheme.of(context).images.noInternetConnection),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.big(),
            const AppText.headlineMedium(
              'No internet connection',
            ),
            const AppGap.big(),
            const AppText.bodyMedium(
                'Your internet might be down because of a logic power outage or issue with your ISP'),
            const AppGap.big(),
            BorderListTile(
              title: 'Restart your modem',
              subTitle: 'Some ISPs require this weh setting up a new router',
              onTap: () {},
            ),
            const AppGap.semiBig(),
            BorderListTile(
              title: 'Enter ISP settings',
              subTitle:
                  'Enter Static IP or PPPoE settings provided by your ISP',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
