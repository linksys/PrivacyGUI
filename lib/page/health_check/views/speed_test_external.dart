import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart';

class SpeedTestExternalView extends StatelessWidget {
  const SpeedTestExternalView({super.key});

  @override
  Widget build(BuildContext context) {
    return UiKitPageView(
      scrollable: true,
      title: loc(context).externalSpeedText,
      child: (context, constraints) => SizedBox(
        width: context.colWidth(6),
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 0, vertical: AppSpacing.xxl),
                child: SizedBox(
                  width: 224,
                  height: 56,
                  child: AppSvg.asset(
                    svg: Assets.images.internetToDevice,
                  ),
                ),
              ),
              AppText.labelLarge(loc(context).speedTestExternalDesc),
              AppGap.lg(),
              // Numbered list using Column instead of AppBulletList
              _buildNumberedList(context),
              context.isMobileLayout
                  ? _externalButtonsMobile(context)
                  : _externalButtonsDesktop(context),
              AppGap.lg(),
              AppText.bodyMedium(loc(context).speedTestExternalOthers)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberedList(BuildContext context) {
    final steps = [
      loc(context).speedTestExternalStep1,
      loc(context).speedTestExternalStep2,
      loc(context).speedTestExternalStep3,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: entry.key < steps.length - 1 ? AppSpacing.lg : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: AppText.bodyMedium('${entry.key + 1}.'),
              ),
              Expanded(
                child: AppText.bodyMedium(entry.value),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _externalButtonsMobile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppButton.primary(
          label: loc(context).speedTestExternalCloudFlare,
          onTap: () {
            openUrl('https://speed.cloudflare.com/');
          },
        ),
        AppGap.md(),
        AppButton.primary(
          label: loc(context).speedTestExternalFast,
          onTap: () {
            openUrl('https://www.fast.com');
          },
        ),
      ],
    );
  }

  Widget _externalButtonsDesktop(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AppButton.primary(
            label: loc(context).speedTestExternalCloudFlare,
            onTap: () {
              openUrl('https://speed.cloudflare.com/');
            },
          ),
        ),
        AppGap.md(),
        Expanded(
          child: AppButton.primary(
            label: loc(context).speedTestExternalFast,
            onTap: () {
              openUrl('https://www.fast.com');
            },
          ),
        ),
      ],
    );
  }
}
