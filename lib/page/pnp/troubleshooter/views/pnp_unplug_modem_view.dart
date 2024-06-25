import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';

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
      title: loc(context).pnpUnplugModemTitle,
      scrollable: true,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyLarge(
              loc(context).pnpUnplugModemDesc,
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
                    const AppGap.large3(),
                    const AppGap.large4(),
                    Row(
                      children: [
                        AppTextButton(
                          loc(context).pnpUnplugModemTip,
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
            context.pushNamed(RouteNamed.pnpModemLightsOff);
          },
        ),
      ),
    );
  }

  Widget _bottomSheetContent() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.large2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.headlineSmall(
            loc(context).pnpUnplugModemTipTitle,
          ),
          const AppGap.large2(),
          AppText.bodyMedium(
            loc(context).pnpUnplugModemTipDesc1,
          ),
          const AppGap.large2(),
          AppText.bodyMedium(
            loc(context).pnpUnplugModemTipDesc2,
          ),
          const AppGap.medium(),
          const AppGap.large4(),
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
