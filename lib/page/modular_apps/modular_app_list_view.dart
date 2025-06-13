import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/sse/modular_apps_sse/modular_apps_sse_provider.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/modular_apps/widgets/modular_app_category_layout.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/modular_apps/provider/modular_app_list_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class ModularAppListView extends ArgumentsConsumerStatefulView {
  const ModularAppListView({super.key});

  @override
  ConsumerState<ModularAppListView> createState() => _ModularAppListViewState();
}

class _ModularAppListViewState extends ConsumerState<ModularAppListView> {
  @override
  void initState() {
    super.initState();
    doSomethingWithSpinner(
        context, ref.read(sseConnectionProvider.notifier).connect());
  }

  @override
  void dispose() {
    ref.read(sseConnectionProvider.notifier).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modularAppListState = ref.watch(modularAppListProvider);
    return StyledAppPageView(
      scrollable: true,
      title: 'Modular App List',
      child: (context, constraints) => AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModularAppCategoryLayout(
              title: 'Default Apps',
              apps: modularAppListState.defaultApps,
            ),
            AppGap.medium(),
            ModularAppCategoryLayout(
              title: 'User Apps',
              apps: modularAppListState.userApps,
            ),
            AppGap.medium(),
            ModularAppCategoryLayout(
              title: 'Premium Apps',
              apps: modularAppListState.premiumApps,
            ),
            AppGap.medium(),
          ],
        ),
        footer: Row(
          children: [
            AppText.labelLarge('Version: ${modularAppListState.version}'),
            AppGap.medium(),
            AppText.labelLarge(
                'Last Updated: ${DateTime.fromMillisecondsSinceEpoch((modularAppListState.lastUpdated ?? 0) * 1000).toIso8601String()}'),
          ],
        ),
      ),
    );
  }
}
