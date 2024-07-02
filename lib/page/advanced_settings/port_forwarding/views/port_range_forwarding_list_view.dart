import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/_port_forwarding.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/views/widgets/_widgets.dart';

import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class PortRangeForwardingListView extends ArgumentsConsumerStatelessView {
  const PortRangeForwardingListView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortRangeForwardingListContentView(
      args: super.args,
    );
  }
}

class PortRangeForwardingListContentView extends ArgumentsConsumerStatefulView {
  const PortRangeForwardingListContentView({super.key, super.args});

  @override
  ConsumerState<PortRangeForwardingListContentView> createState() =>
      _PortRangeForwardingContentViewState();
}

class _PortRangeForwardingContentViewState
    extends ConsumerState<PortRangeForwardingListContentView> {
  late final PortRangeForwardingListNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(portRangeForwardingListProvider.notifier);
    _notifier.fetch();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portRangeForwardingListProvider);
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).portRangeForwarding,
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
                  context.pushNamed<bool?>(RouteNamed.portRangeForwardingRule,
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
                            RouteNamed.portRangeForwardingRule,
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
                    yield const AppGap.medium();
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
