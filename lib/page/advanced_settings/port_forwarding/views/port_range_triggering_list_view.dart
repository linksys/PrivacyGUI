import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/_port_forwarding.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/views/widgets/_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

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
    super.initState();
    _notifier = ref.read(portRangeTriggeringListProvider.notifier);
    doSomethingWithSpinner(
      context,
      _notifier.fetch(),
    );
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
      title: loc(context).portRangeTriggering,
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large2(),
            AppText.bodyLarge(loc(context).portRangeForwardingDescription),
            if (!_notifier.isExceedMax()) ...[
              const AppGap.large2(),
              AddRuleCard(
                onTap: () {
                  context.pushNamed<bool?>(RouteNamed.protRangeTriggeringRule,
                      extra: {'rules': state.rules}).then((value) {
                    if (value ?? false) {
                      _notifier.fetch();
                    }
                  });
                },
              ),
            ],
            const AppGap.large2(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).rules),
                const AppGap.medium(),
                if (state.rules.isNotEmpty)
                  ...state.rules
                      .map(
                    (e) => RuleItemCard(
                      title: e.description,
                      isEnabled: e.isEnabled,
                      onTap: () {
                        context.pushNamed<bool?>(
                            RouteNamed.protRangeTriggeringRule,
                            extra: {
                              'rules': state.rules,
                              'edit': e
                            }).then((value) {
                          if (value ?? false) {
                            _notifier.fetch();
                          }
                        });
                      },
                    ),
                  )
                      .expand((element) sync* {
                    yield element;
                    yield const AppGap.small2();
                  }),
                if (state.rules.isEmpty) const EmptyRuleCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
