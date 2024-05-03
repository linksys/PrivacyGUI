import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/picker/simple_item_picker.dart';
import 'package:linksys_app/page/components/shortcuts/dialogs.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/administration/mac_filtering/providers/_providers.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';

import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/card/list_card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/panel/switch_trigger_tile.dart';
import 'package:linksys_widgets/widgets/radios/radio_list.dart';

class MacFilteringView extends ArgumentsConsumerStatelessView {
  const MacFilteringView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MacFilteringContentView(
      args: super.args,
    );
  }
}

class MacFilteringContentView extends ArgumentsConsumerStatefulView {
  const MacFilteringContentView({super.key, super.args});

  @override
  ConsumerState<MacFilteringContentView> createState() =>
      _MacFilteringContentViewState();
}

class _MacFilteringContentViewState
    extends ConsumerState<MacFilteringContentView> {
  late final MacFilteringNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(macFilteringProvider.notifier);
    _notifier.fetch();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(macFilteringProvider);
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).macFiltering,
      child: AppBasicLayout(
        content: Column(
          children: [
            const AppGap.semiBig(),
            AppCard(
              child: AppSwitchTriggerTile(
                value: state.mode != MacFilterMode.disabled,
                title: AppText.labelLarge(loc(context).wifiMacFilters),
                onChanged: (value) {
                  _notifier.setEnable(value);
                },
              ),
            ),
            const AppGap.semiBig(),
            ..._buildEnabledContent(state)
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEnabledContent(MacFilteringState state) {
    return state.mode != MacFilterMode.disabled
        ? [
            AppListCard(
                title: AppText.labelLarge(loc(context).access),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.labelLarge(state.mode.name),
                    const AppGap.regular(),
                    const Icon(LinksysIcons.chevronRight)
                  ],
                ),
                onTap: () async {
                  _selectAccessModal();
                }),
            AppListCard(
              title: AppText.labelLarge(loc(context).filteredDevices),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppText.labelLarge('${state.macAddresses.length}'),
                  const AppGap.regular(),
                  const Icon(LinksysIcons.chevronRight)
                ],
              ),
              onTap: () async {
                context.pushNamed(RouteNamed.macFilteringInput);
              },
            ),
          ]
        : [];
  }

  void _selectAccessModal() async {
    final initValue = ref.read(macFilteringProvider).mode;
    MacFilterMode? selected;
    final result = await showSimpleAppDialog<MacFilterMode?>(context,
        title: loc(context).access,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppRadioList(
              initial: initValue,
              mainAxisSize: MainAxisSize.min,
              items: [
                AppRadioListItem(
                  title: loc(context).allowAccess,
                  subtitleWidget: AppText.bodyMedium(
                    loc(context).allowAccessDesc,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  value: MacFilterMode.allow,
                ),
                AppRadioListItem(
                  title: loc(context).denyAccess,
                  subtitleWidget: AppText.bodyMedium(
                    loc(context).denyAccessDesc,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  value: MacFilterMode.deny,
                ),
              ],
              onChanged: (index, selectedType) {
                selected = selectedType;
              },
            ),
          ],
        ),
        actions: [
          AppTextButton(
            loc(context).cancel,
            onTap: () {
              context.pop();
            },
          ),
          AppTextButton(
            loc(context).ok,
            onTap: () {
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      _notifier.setAccess(result.name);
    }
  }
}
