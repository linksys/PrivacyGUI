import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
    return UiKitPageView.withSliver(
      title: loc(context).pnpUnplugModemTitle,
      scrollable: true,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(
            loc(context).pnpUnplugModemDesc,
          ),
          AppGap.xxl(),
          AppGap.sm(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Assets.images.modemPlugged.svg(
                  semanticsLabel: 'modem Plugged image',
                  fit: BoxFit.fitWidth,
                ),
                AppGap.xxl(),
                AppGap.xxxl(),
              ],
            ),
          ),
          Wrap(
            children: [
              AppButton.text(
                label: loc(context).pnpUnplugModemTip,
                onTap: () {
                  showSimpleAppOkDialog(
                    context,
                    scrollable: true,
                    content: _bottomSheetContent(),
                  );
                },
              ),
            ],
          ),
          AppGap.xxl(),
          AppButton(
            label: loc(context).next,
            variant: SurfaceVariant.highlight,
            onTap: () {
              context.pushNamed(RouteNamed.pnpModemLightsOff);
            },
          ),
        ],
      ),
    );
  }

  Widget _bottomSheetContent() {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.headlineSmall(
            loc(context).pnpUnplugModemTipTitle,
          ),
          AppGap.xl(),
          AppText.bodyMedium(
            loc(context).pnpUnplugModemTipDesc1,
          ),
          AppGap.xl(),
          AppText.bodyMedium(
            loc(context).pnpUnplugModemTipDesc2,
          ),
          AppGap.lg(),
          AppGap.xxxl(),
          Container(
            alignment: Alignment.center,
            child: Assets.images.modemIdentifying.svg(
              semanticsLabel: 'modem Identifying image',
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}
