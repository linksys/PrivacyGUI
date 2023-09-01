import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/port_forwarding/port_range_triggering_list/port_range_triggering_list_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PortRangeTriggeringListView extends ArgumentsConsumerStatelessView {
  const PortRangeTriggeringListView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortRangeTriggeringListContentView(
      args: super.args,
    );
  }
}

class PortRangeTriggeringListContentView extends ArgumentsConsumerStatefulView {
  const PortRangeTriggeringListContentView({super.key, super.args});

  @override
  ConsumerState<PortRangeTriggeringListContentView> createState() =>
      _PortRangeTriggeringContentViewState();
}

class _PortRangeTriggeringContentViewState
    extends ConsumerState<PortRangeTriggeringListContentView> {
  late final PortRangeTriggeringListNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(portRangeTriggeringListProvider.notifier);
    _notifier.fetch();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portRangeTriggeringListProvider);
    return StyledAppPageView(
      scrollable: true,
      title: getAppLocalizations(context).port_range_triggering,
      actions: [
        AppTertiaryButton(
          getAppLocalizations(context).edit,
          onTap: () {
            // TODO
          },
        ),
      ],
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.semiBig(),
            AppText.bodyLarge(
                getAppLocalizations(context).port_range_triggering_description),
            if (!_notifier.isExceedMax())
              AppTertiaryButton(
                getAppLocalizations(context).add_rule,
                onTap: () {
                  context.pushNamed<bool?>(
                    RouteNamed.portRangeForwardingRule,
                    queryParameters: {'rules': state.rules},
                  ).then((value) {
                    if (value ?? false) {
                      _notifier.fetch();
                    }
                  });
                },
              ),
            const AppGap.semiBig(),
            ...state.rules.map(
              (e) => AppPanelWithInfo(
                title: e.description,
                infoText: e.isEnabled
                    ? getAppLocalizations(context).on
                    : getAppLocalizations(context).off,
                forcedHidingAccessory: true,
                onTap: () {
                  context.pushNamed<bool?>(
                    RouteNamed.singlePortForwardingRule,
                    queryParameters: {'rules': state.rules, 'edit': e},
                  ).then((value) {
                    if (value ?? false) {
                      _notifier.fetch();
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
