import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart';

class SpeedTestExternalWidget extends ConsumerStatefulWidget {
  const SpeedTestExternalWidget({super.key});

  @override
  ConsumerState<SpeedTestExternalWidget> createState() =>
      _SpeedTestExternalWidgetState();
}

class _SpeedTestExternalWidgetState
    extends ConsumerState<SpeedTestExternalWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon.font(
              AppFontIcons.infoCircle,
              color: Theme.of(context).colorScheme.primary,
            ),
            AppGap.xxl(),
            Expanded(
                child:
                    AppText.labelSmall(loc(context).speedTestExternalTileLabel))
          ],
        ),
        AppGap.lg(),
        context.isMobileLayout
            ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: AppButton.primary(
                    label: loc(context).speedTestExternalTileCloudFlare,
                    onTap: () {
                      openUrl('https://speed.cloudflare.com/');
                    },
                  ),
                ),
                AppGap.xxl(),
                Expanded(
                  child: AppButton.primary(
                    label: loc(context).speedTestExternalTileFast,
                    onTap: () {
                      openUrl('https://www.fast.com');
                    },
                  ),
                ),
              ])
            : SizedBox(
                width: 184,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.primary(
                          label: loc(context).speedTestExternalTileCloudFlare,
                          onTap: () {
                            openUrl('https://speed.cloudflare.com/');
                          },
                        ),
                      ),
                      AppGap.sm(),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.primary(
                          label: loc(context).speedTestExternalTileFast,
                          onTap: () {
                            openUrl('https://www.fast.com');
                          },
                        ),
                      ),
                    ]),
              ),
        AppGap.sm(),
        AppText.bodySmall(
          loc(context).speedTestExternalOthers,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
