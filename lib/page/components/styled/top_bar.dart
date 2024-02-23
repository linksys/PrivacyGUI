import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:linksys_app/page/components/styled/general_settings_widget/general_settings_widget.dart';
import 'package:linksys_widgets/theme/custom_theme.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

class TopBar extends ConsumerStatefulWidget {
  const TopBar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<TopBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: 24.0, right: 24, top: 14, bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ResponsiveLayout.isMobile(context)
                    ? SvgPicture(
                        CustomTheme.of(context).images.linksysLogoBlack,
                        width: 20,
                        height: 20,
                      )
                    : const Center(),
                const GeneralSettingsWidget(),
              ],
            ),
          ),
          Divider(
            thickness: 1,
          )
        ],
      ),
    );
  }
}
