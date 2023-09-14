import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';

class NoInternetConnectionModal extends ConsumerWidget {
  const NoInternetConnectionModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: AppPageView.bottomSheetModalBlur(
        padding: const AppEdgeInsets.only(),
        bottomSheet: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          height: 240,
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              AppPadding(
                padding: const AppEdgeInsets.semiBig(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyLarge(
                      getAppLocalizations(context)
                          .prompt_no_internet_connection,
                    ),
                    const AppGap.big(),
                    AppText.bodyMedium(
                      getAppLocalizations(context)
                          .prompt_no_internet_connection_description,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
