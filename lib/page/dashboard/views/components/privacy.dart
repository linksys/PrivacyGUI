import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/views/components/shimmer.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/label/status_label.dart';

class PrivacyWidget extends ConsumerStatefulWidget {
  const PrivacyWidget({super.key});

  @override
  ConsumerState<PrivacyWidget> createState() => _PrivacyWidgetState();
}

class _PrivacyWidgetState extends ConsumerState<PrivacyWidget> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantPrivacyProvider);
    final isLoading = ref.watch(deviceManagerProvider).deviceList.isEmpty;

    return ShimmerContainer(
      isLoading: isLoading,
      child: AppCard(
        padding: const EdgeInsets.all(Spacing.large2),
        onTap: () {
          context.pushNamed(RouteNamed.menuInstantPrivacy);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LinksysIcons.smartLock),
            const AppGap.medium(),
            AppText.titleMedium(loc(context).instantPrivacy),
            const Spacer(),
            AppStatusLabel(
              isOff: state.mode == MacFilterMode.disabled,
            ),
          ],
        ),
      ),
    );
  }
}
