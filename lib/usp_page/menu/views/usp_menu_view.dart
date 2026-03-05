import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Menu page — simplified version without JNAP-dependent features.
///
/// Placeholder menu items for features that will be implemented in the USP
/// flow. Items without USP support are omitted entirely rather than disabled.
class UspMenuView extends StatelessWidget {
  const UspMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backState: UiKitBackState.none,
      child: (childContext, constraints) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.headlineSmall(loc(context).menu),
              AppGap.xl(),
              AppText.bodyMedium(
                'USP menu items will be available as more features are implemented.',
              ),
            ],
          ),
        );
      },
    );
  }
}
