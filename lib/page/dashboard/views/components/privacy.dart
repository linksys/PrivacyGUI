import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/label/status_label.dart';

class PrivacyWidget extends ConsumerStatefulWidget {
  const PrivacyWidget({super.key});

  @override
  ConsumerState<PrivacyWidget> createState() => _PrivacyWidgetState();
}

class _PrivacyWidgetState extends ConsumerState<PrivacyWidget> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(macFilteringProvider);
    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LinksysIcons.smartLock),
          const AppGap.medium(),
          AppText.titleMedium('Instant-Privacy'),
          const Spacer(),
          AppStatusLabel(
            isOff: state.mode == MacFilterMode.disabled,
          ),
        ],
      ),
    );
  }
}
