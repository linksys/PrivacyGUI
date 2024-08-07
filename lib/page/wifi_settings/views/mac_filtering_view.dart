import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';

class MacFilteringView extends ArgumentsConsumerStatefulView {
  const MacFilteringView({
    super.key,
    super.args,
  });

  @override
  ConsumerState<MacFilteringView> createState() => _MacFilteringViewState();
}

class _MacFilteringViewState extends ConsumerState<MacFilteringView> {
  late final MacFilteringNotifier _notifier;
  MacFilteringState? _preservedState;
  @override
  void initState() {
    _notifier = ref.read(macFilteringProvider.notifier);
    doSomethingWithSpinner(
      context,
      _notifier.fetch().then(
        (state) {
          ref.read(wifiViewProvider.notifier).setChanged(false);
          _preservedState = state;
        },
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(macFilteringProvider);
    ref.listen(macFilteringProvider, (previous, next) {
      ref.read(wifiViewProvider.notifier).setChanged(next != _preservedState);
    });
    return StyledAppPageView(
      scrollable: true,
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      title: loc(context).macFiltering,
      bottomBar: PageBottomBar(
          isPositiveEnabled: _preservedState != state,
          onPositiveTap: () {
            doSomethingWithSpinner(
                context,
                _notifier
                    .save()
                    .then((value) {
                      ref.read(wifiViewProvider.notifier).setChanged(false);
                      setState(() {
                        _preservedState = ref.read(macFilteringProvider);
                      });
                    })
                    .then((value) =>
                        showSuccessSnackBar(context, loc(context).saved))
                    .onError((error, stackTrace) => showFailedSnackBar(
                        context, loc(context).generalError)));
          }),
      child: AppBasicLayout(
        content: Column(
          children: [
            AppCard(
              child: AppSwitchTriggerTile(
                value: state.mode != MacFilterMode.disabled,
                title: AppText.labelLarge(loc(context).wifiMacFilters),
                onChanged: (value) {
                  _notifier.setEnable(value);
                },
              ),
            ),
            const AppGap.small2(),
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
                    AppText.labelLarge(state.mode == MacFilterMode.allow
                        ? loc(context).allow
                        : loc(context).deny),
                    const AppGap.medium(),
                    const Icon(LinksysIcons.chevronRight)
                  ],
                ),
                onTap: () async {
                  _selectAccessModal();
                }),
            const AppGap.small2(),
            AppListCard(
              title: AppText.labelLarge(loc(context).filteredDevices),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppText.labelLarge('${state.macAddresses.length}'),
                  const AppGap.medium(),
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
              withDivider: true,
              items: [
                AppRadioListItem(
                  title: loc(context).allowAccess,
                  titleWidget: AppText.bodyLarge(loc(context).allowAccess),
                  subTitleWidget: AppText.bodyMedium(
                    loc(context).allowAccessDesc,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  value: MacFilterMode.allow,
                ),
                AppRadioListItem(
                  title: loc(context).denyAccess,
                  titleWidget: AppText.bodyLarge(loc(context).denyAccess),
                  subTitleWidget: AppText.bodyMedium(
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
