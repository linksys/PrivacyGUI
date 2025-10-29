import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_provider.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/util/timezone.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

class TimezoneView extends ArgumentsConsumerStatefulView {
  const TimezoneView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<TimezoneView> createState() => _TimezoneContentViewState();
}

class _TimezoneContentViewState extends ConsumerState<TimezoneView>
    with PageSnackbarMixin {
  late final TimezoneNotifier _notifier;

  @override
  void initState() {
    super.initState();

    _notifier = ref.read(timezoneProvider.notifier);
    doSomethingWithSpinner(
      context,
      _notifier.fetch(),
    ).onError((error, stackTrace) {
        showErrorMessageSnackBar(error);
      });
  }

  @override
  void dispose() {
    super.dispose();
    // _notifier.fetch(); // No need to fetch on dispose, as state is managed by Riverpod
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timezoneProvider);
    return StyledAppPageView(
      title: loc(context).timezone,
      scrollable: true,
      onBackTap: _notifier.isDirty()
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                _notifier.revert(); // Use notifier's revert
                context.pop();
              }
            }
          : null,
      bottomBar: PageBottomBar(
          isPositiveEnabled: _notifier.isDirty(),
          onPositiveTap: () {
            doSomethingWithSpinner(
              context,
              _notifier.save(),
              title: loc(context).savingChanges,
            ).then((value) {
              context.pop(true);
              showChangesSavedSnackBar();
            }).onError((error, stackTrace) {
              showErrorMessageSnackBar(error);
            });
          }),
      child: (context, constraints) => AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(loc(context).daylightSavingsTime),
                semanticLabel: 'daylight savings time',
                value: state.settings.current.isDaylightSaving,
                onChanged: _notifier.isSupportDaylightSaving()
                    ? (value) {
                        _notifier.setDaylightSaving(value);
                      }
                    : null,
              ),
            ),
            const AppGap.medium(),
            SizedBox(
              height: (70.0) * state.status.supportedTimezones.length +
                  17 * (state.status.supportedTimezones.length - 1),
              child: AppCard(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.status.supportedTimezones.length,
                  itemBuilder: (context, index) => ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 70.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: AppListCard(
                          showBorder: false,
                          padding: EdgeInsets.zero,
                          title: AppText.labelLarge(
                            getTimeZoneRegionName(context,
                                state.status.supportedTimezones[index].timeZoneID),
                            color: _notifier.isSelectedTimezone(index)
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          description: AppText.bodyMedium(
                            getTimezoneGMT(
                                state.status.supportedTimezones[index].description),
                            color: _notifier.isSelectedTimezone(index)
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          trailing: _notifier.isSelectedTimezone(index)
                              ? Icon(
                                  LinksysIcons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                  semanticLabel: 'check icon',
                                )
                              : null,
                          onTap: () {
                            _notifier.setSelectedTimezone(index);
                          }),
                    ),
                  ),
                  separatorBuilder: (BuildContext context, int index) {
                    return index != (state.status.supportedTimezones.length - 1)
                        ? const Divider()
                        : const Center();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> showUnsavedAlert(BuildContext context,
      {String? title, String? message}) {
    return showMessageAppDialog<bool>(
      context,
      title: title ?? loc(context).unsavedChangesTitle,
      message: message ?? loc(context).unsavedChangesDesc,
      actions: [
        AppTextButton(
          loc(context).goBack,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            context.pop();
          },
        ),
        AppTextButton(
          loc(context).discardChanges,
          color: Theme.of(context).colorScheme.error,
          onTap: () {
            context.pop(true);
          },
        ),
      ],
    );
  }
}
