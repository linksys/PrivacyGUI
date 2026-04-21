import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/sysinfo_email_service.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class StillNeedHelpWidget extends ConsumerWidget {
  const StillNeedHelpWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.all(Spacing.large2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LinksysIcons.technician,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: Spacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium(loc(context).stillNeedHelp),
                    const AppGap.small2(),
                    AppText.bodyMedium(
                      loc(context).stillNeedHelpDescription,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const AppGap.large2(),
          Row(
            children: [
              Expanded(
                child: AppOutlinedButton(
                  loc(context).sendSystemInfo,
                  icon: LinksysIcons.send,
                  onTap: () {
                    SysinfoEmailService.showSendSystemInfoDialog(context, ref);
                  },
                ),
              ),
            ],
          ),
          const AppGap.medium(),
          AppText.bodySmall(
            loc(context).systemInfoPrivacyNotice,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
