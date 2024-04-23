import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/main.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
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
      title: 'Unplug your modem',
      scrollable: true,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.bodyLarge(
              'These settings are provided by your Internet Service Provider (ISP). If you aren\'t sure about yours, we recommend contacting your ISP.',
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture(
                      CustomTheme.of(context).images.modemPlugged,
                      fit: BoxFit.fitWidth,
                    ),
                    const AppGap.big(),
                    const AppGap.extraBig(),
                    Row(
                      children: [
                        AppTextButton(
                          'Not sure which device is the modem?',
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              useRootNavigator: true,
                              useSafeArea: true,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (context) {
                                return _bottomSheetContent();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        footer: AppFilledButton.fillWidth(
          loc(context).next,
          onTap: () {
            context.goNamed(RouteNamed.pnpMakeSureLightOff);
          },
        ),
      ),
    );
  }

  Widget _bottomSheetContent() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.semiBig),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.headlineSmall(
            'Identifying your modem',
          ),
          const AppGap.semiBig(),
          const AppText.bodyMedium(
            'Modems are usually connected to the internet via a coaxial cable or phone cable coming into your home.',
          ),
          const AppGap.semiBig(),
          const AppText.bodyMedium(
            'Modems can be horizontal or vertical depending on the brand.',
          ),
          const AppGap.regular(),
          const AppGap.extraBig(),
          Container(
            alignment: Alignment.center,
            child: SvgPicture(
              CustomTheme.of(context).images.modemIdentifying,
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}
