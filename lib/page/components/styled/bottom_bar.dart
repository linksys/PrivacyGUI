import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class BottomBar extends ConsumerStatefulWidget {
  const BottomBar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BottomBarState();
}

class _BottomBarState extends ConsumerState<BottomBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      height: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Divider(
            height: 1,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText.bodySmall(
                    '© 2024 Linksys Holdings, Inc. and/or its affiliates. All rights reserved.'),
                AppGap.semiBig(),
                AppTextButton.noPadding(
                  'End User License Agreement',
                  onTap: () {},
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: AppText.bodySmall('|'),
                ),
                AppTextButton.noPadding(
                  'Terms of Service',
                  onTap: () {},
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: AppText.bodySmall('|'),
                ),
                AppTextButton.noPadding(
                  'Privacy Statement',
                  onTap: () {},
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: AppText.bodySmall('|'),
                ),
                AppTextButton.noPadding(
                  'Third Party License',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
