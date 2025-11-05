import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:privacy_gui/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/url_helper/url_helper_web.dart';

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
            Icon(
              LinksysIcons.infoCircle,
              color: Theme.of(context).colorScheme.primary,
            ),
            AppGap.large2(),
            Expanded(child: AppText.labelSmall(loc(context).speedTestExternalTileLabel))
          ],
        ),
        AppGap.medium(),
        ResponsiveLayout.isMobileLayout(context)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: Spacing.large2,
                children: [
                    Expanded(
                      child: AppFilledButton(
                        loc(context).speedTestExternalTileCloudFlare,
                        fitText: true,
                        onTap: () {
                          openUrl('https://speed.cloudflare.com/');
                        },
                      ),
                    ),
                    Expanded(
                      child: AppFilledButton(
                        loc(context).speedTestExternalTileFast,
                        fitText: true,
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
                    spacing: Spacing.small2,
                    children: [
                      AppFilledButton.fillWidth(
                        loc(context).speedTestExternalTileCloudFlare,
                        fitText: true,
                        onTap: () {
                          openUrl('https://speed.cloudflare.com/');
                        },
                      ),
                      AppFilledButton.fillWidth(
                        loc(context).speedTestExternalTileFast,
                        fitText: true,
                        onTap: () {
                          openUrl('https://www.fast.com');
                        },
                      ),
                    ]),
              ),
        AppGap.small2(),
        AppText.bodyExtraSmall(
          loc(context).speedTestExternalOthers,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
