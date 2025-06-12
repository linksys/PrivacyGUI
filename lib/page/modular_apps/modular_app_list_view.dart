import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/sse/modular_apps_sse/modular_apps_sse_provider.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/modular_apps/models/modular_app_data.dart';
import 'package:privacy_gui/page/modular_apps/provider/modular_app_list_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
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

  Widget _buildAppCategory(String title, List<ModularAppData> apps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleSmall('$title (${apps.length})'),
        AppGap.medium(),
        if (apps.isEmpty)
          AppText.labelMedium('No apps available')
        else
          SizedBox(
            height: 200,
            child: CarouselView(
              itemExtent: 200,
              children: apps.map((app) => _buildAppCard(app)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildAppCard(ModularAppData app) {
    return AppCard(
      color: app.color.color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              app.icon.toIcon(),
              AppGap.small2(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelLarge(app.name),
                    AppText.labelSmall(app.description),
                  ],
                ),
              ),
            ],
          ),
          AppGap.small2(),
          AppText.labelSmall('Version: ${app.version}'),
        ],
      ),
    );
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
            _buildAppCategory('Default Apps', modularAppListState.defaultApps),
            AppGap.medium(),
            _buildAppCategory('User Apps', modularAppListState.userApps),
            AppGap.medium(),
            _buildAppCategory('Premium Apps', modularAppListState.premiumApps),
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
