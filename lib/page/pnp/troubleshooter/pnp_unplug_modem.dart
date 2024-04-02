import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';

class PnpUnplugModemView extends ConsumerStatefulWidget {
  const PnpUnplugModemView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpUnplugModemView> createState() => _PnpUnplugModemViewState();
}

class _PnpUnplugModemViewState extends ConsumerState<PnpUnplugModemView> {
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
      child: AppBasicLayout(
        content: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.big(),
              const AppText.headlineMedium(
                'Unplug your modem',
              ),
              const AppGap.big(),
              const AppText.bodyMedium(
                  'These settings are provided by your Internet Service Provider (ISP). If you aren\'t sure about yours, we recommend contacting your ISP.'),
              Expanded(
                child: Center(
                  child: SvgPicture(
                    CustomTheme.of(context).images.unplugModem,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ]),
        footer: Column(children: [
          AppFilledButton.fillWidth(
            'Next',
            onTap: () {
              context.goNamed(RouteNamed.pnpMakeSureLightOff);
            },
          ),
          AppTextButton.fillWidth(
            'Not sure which device is the modem?',
            onTap: () {
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                useSafeArea: true,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (context) {
                  return _showBottomsheet();
                },
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _showBottomsheet() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: AppIconButton(
              icon: LinksysIcons.close,
              onTap: () {
                context.pop();
              },
            ),
          ),
          const AppText.headlineMedium(
            'Identifying your modem',
          ),
          const AppGap.big(),
          const AppText.bodyMedium(
              'Modems are usually connected to the internet via a coaxial cable or phone cable coming into your home.'),
          const AppGap.big(),
          const AppText.bodyMedium(
              'Modems can be horizontal or vertical depending on the brand.'),
          Expanded(
            child: Center(
              child: SvgPicture(
                CustomTheme.of(context).images.identifyYourModem,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
