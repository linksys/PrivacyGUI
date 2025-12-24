import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';

import 'package:ui_kit_library/ui_kit.dart';

class PnpModemLightsOffView extends ConsumerStatefulWidget {
  const PnpModemLightsOffView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpModemLightsOffView> createState() => _PnpLightOffViewState();
}

class _PnpLightOffViewState extends ConsumerState<PnpModemLightsOffView> {
  @override
  Widget build(BuildContext context) {
    return UiKitPageView(
      title: loc(context).pnpModemLightsOffTitle,
      scrollable: true,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(
            loc(context).pnpModemLightsOffDesc,
          ),
          AppGap.xxl(),
          AppGap.sm(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Assets.images.modemDevice.svg(
                  semanticsLabel: 'modem Device image',
                  fit: BoxFit.fitWidth,
                ),
                AppGap.xxl(),
                AppGap.xxxl(),
                Row(
                  children: [
                    Flexible(
                      child: AppButton.text(
                        label: loc(context).pnpModemLightsOffTip,
                        onTap: () {
                          showSimpleAppOkDialog(
                            context,
                            content: SingleChildScrollView(
                                child: _bottomSheetContent()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppGap.xxl(),
          AppButton(
            label: loc(context).next,
            variant: SurfaceVariant.highlight,
            onTap: () {
              context.pushNamed(RouteNamed.pnpWaitingModem);
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
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.headlineSmall(
            loc(context).pnpModemLightsOffTipTitle,
          ),
          AppGap.xl(),
          AppText.bodyMedium(
            loc(context).pnpModemLightsOffTipDesc,
          ),
          AppGap.xl(),
          Column(
            children: [
              _buildNumberedItem(1, loc(context).pnpModemLightsOffTipStep1),
              AppGap.sm(),
              _buildNumberedItem(2, loc(context).pnpModemLightsOffTipStep2),
              AppGap.sm(),
              _buildNumberedItem(3, loc(context).pnpModemLightsOffTipStep3,
                  isHtml: true, key: const Key('pnpModemLightsOffTipStep3')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedItem(int index, String text,
      {bool isHtml = false, Key? key}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium('$index. '),
        AppGap.sm(),
        Expanded(
          child: isHtml
              ? AppStyledText(key: key, text: '<b>$text</b>')
              : AppText.bodyMedium(text),
        ),
      ],
    );
  }
}
