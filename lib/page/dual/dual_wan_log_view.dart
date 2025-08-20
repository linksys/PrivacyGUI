import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dual/models/log.dart';
import 'package:privacy_gui/page/dual/models/log_level.dart';
import 'package:privacy_gui/page/dual/models/log_type.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_filtered_config_provider.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_filtered_logs_provider.dart';

import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/information_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_log_provider.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/label/text_label.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

class DualWANLogView extends ArgumentsConsumerStatefulView {
  const DualWANLogView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<DualWANLogView> createState() => _DualWANLogViewState();
}

class _DualWANLogViewState extends ConsumerState<DualWANLogView>
    with PageSnackbarMixin {
  late final DualWANLogNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(dualWANLogProvider.notifier);

    doSomethingWithSpinner(
      context,
      _notifier.fetch(),
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(dualWANFilteredLogsProvider);
    final totalLogInfoList = [
      _smallInfoCard(DualWANLogLevel.error,
          logs.getLogCountByLevel(DualWANLogLevel.error)),
      _smallInfoCard(DualWANLogLevel.warning,
          logs.getLogCountByLevel(DualWANLogLevel.warning)),
      _smallInfoCard(
          DualWANLogLevel.info, logs.getLogCountByLevel(DualWANLogLevel.info)),
      _smallInfoCard(
          DualWANLogLevel.none, logs.getLogCountByLevel(DualWANLogLevel.none)),
    ];
    return StyledAppPageView(
        // scrollable: true,
        pageContentType: PageContentType.fit,
        title: loc(context).dualWanLogsTitle,
        child: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.large1,
              children: [
                _logFilters(),
                _logEntries(),
                ResponsiveLayout.isMobileLayout(context)
                    ? Column(
                        spacing: Spacing.medium,
                        children: totalLogInfoList,
                      )
                    : Row(
                        spacing: Spacing.medium,
                        children: totalLogInfoList
                            .map((e) => Expanded(child: e))
                            .toList(),
                      ),
                const AppGap.large1(),
              ],
            ),
          );
        });
  }

  Widget _logFilters() {
    return AppInformationCard(
      title: loc(context).logFiltersAndActions,
      description: loc(context).filterAndManageDualWanLogs,
      content: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Spacing.medium,
        runSpacing: Spacing.medium,
        children: [
          Icon(Icons.filter_alt_outlined),
          const AppGap.small2(),
          SizedBox(
            width: 200,
            height: 40,
            child: AppDropdownButton<DualWANLogType>(
              label: (item) {
                return item.getFilterDisplayString(context);
              },
              initial: DualWANLogType.all,
              items: DualWANLogType.values,
              onChanged: (value) {
                ref
                    .read(dualWANLogFilterConfigProvider.notifier)
                    .setLogType([value]);
              },
            ),
          ),
          const AppGap.medium(),
          AppOutlinedButton(
            loc(context).refresh,
            icon: Icons.autorenew,
            onTap: () {
              doSomethingWithSpinner(
                context,
                _notifier.fetch(),
              );
            },
          ),
          const AppGap.medium(),
          AppOutlinedButton(
            loc(context).exportLogs,
            icon: Icons.file_download_outlined,
            onTap: () {
              final String fileName =
                  'dual-wan-logs-${DateFormat("yyyy-MM-dd_HH_mm_ss").format(DateTime.now())}.txt';
              final String content = ref
                  .watch(dualWANFilteredLogsProvider)
                  .logs
                  .map((e) => e.toString())
                  .join('\n');
              Utils.export(context,
                  content: content,
                  fileName: fileName,
                  text: 'Dual-WAN Log',
                  subject: 'Dual-WAN Log');
            },
          ),
        ],
      ),
    );
  }

  Widget _logEntries() {
    final logs = ref.watch(dualWANFilteredLogsProvider);
    return AppInformationCard(
      title: loc(context).logEntries,
      description: loc(context).showingNLogEntries(logs.logs.length),
      content: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: logs.logs.length,
        itemBuilder: (context, index) {
          return _logCard(logs.logs[index]);
        },
        separatorBuilder: (context, index) {
          return const AppGap.medium();
        },
      ),
    );
  }

  Widget _smallInfoCard(DualWANLogLevel type, int count) {
    return AppCard(
        child: Container(
      constraints: const BoxConstraints(minWidth: 120),
      child: Row(
        mainAxisSize: ResponsiveLayout.isMobileLayout(context)
            ? MainAxisSize.max
            : MainAxisSize.min,
        children: [
          Icon(type.getIcon(), color: type.getColor()),
          const AppGap.medium(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelLarge(type.getDisplayString(context) ?? 'Total'),
              const AppGap.small2(),
              AppText.titleLarge(count.toString(), color: type.getColor()),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _logCard(DualWANLog log) {
    return AppCard(
        child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(log.level.getIcon(), color: log.level.getColor()),
        const AppGap.medium(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: Spacing.small2,
                runSpacing: Spacing.small2,
                children: [
                  AppText.bodyLarge(
                      DateTime.fromMillisecondsSinceEpoch(log.timestamp)
                          .toIso8601String()),
                  AppLabelText(
                      label: log.level.getLabelDisplayString(context) ?? '',
                      labelColor: log.level.getColor(),
                      color: log.level.getColor().withAlpha(0x80)),
                  AppLabelText(
                      label: log.type.getDisplayString(context),
                      color: Theme.of(context).colorScheme.surface,
                      borderColor: Theme.of(context).colorScheme.onSurface),
                ],
              ),
              AppText.bodyLarge(log.message),
              AppText.bodyMedium('${loc(context).source}: ${log.source}',
                  color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ],
    ));
  }
}
