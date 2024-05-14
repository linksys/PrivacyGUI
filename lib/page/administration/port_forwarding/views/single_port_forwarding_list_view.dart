import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/administration/port_forwarding/_port_forwarding.dart';
import 'package:privacy_gui/page/administration/port_forwarding/views/widgets/_widgets.dart';

import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class SinglePortForwardingListView extends ArgumentsConsumerStatelessView {
  const SinglePortForwardingListView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SinglePortForwardingListContentView(
      args: super.args,
    );
  }
}

class SinglePortForwardingListContentView
    extends ArgumentsConsumerStatefulView {
  const SinglePortForwardingListContentView({super.key, super.args});

  @override
  ConsumerState<SinglePortForwardingListContentView> createState() =>
      _SinglePortForwardingContentViewState();
}

class _SinglePortForwardingContentViewState
    extends ConsumerState<SinglePortForwardingListContentView> {
  late final SinglePortForwardingListNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(singlePortForwardingListProvider.notifier);
    _notifier.fetch();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singlePortForwardingListProvider);
    return StyledAppPageView(
      title: loc(context).singlePortForwarding,
      scrollable: true,
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.semiBig(),
            AppText.bodyLarge(loc(context).singlePortForwardingDescription),
            if (!_notifier.isExceedMax()) ...[
              const AppGap.semiBig(),
              AddRuleCard(
                onTap: () {
                  context.pushNamed<bool?>(RouteNamed.singlePortForwardingRule,
                      extra: {'rules': state.rules}).then((value) {
                    if (value ?? false) {
                      _notifier.fetch();
                    }
                  });
                },
              ),
            ],
            const AppGap.semiBig(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).rules),
                const AppGap.regular(),
                if (state.rules.isNotEmpty)
                  ...state.rules.map(
                    (e) => RuleItemCard(
                      title: e.description,
                      isEnabled: e.isEnabled,
                      onTap: () {
                        context.pushNamed<bool?>(
                            RouteNamed.singlePortForwardingRule,
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
                  ),
                if (state.rules.isEmpty) const EmptyRuleCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
