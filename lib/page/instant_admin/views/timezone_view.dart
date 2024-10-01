import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/timezone.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
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

class _TimezoneContentViewState extends ConsumerState<TimezoneView> {
  late final TimezoneNotifier _notifier;
  late final String previousTimezoneId;

  @override
  void initState() {
    super.initState();

    _notifier = ref.read(timezoneProvider.notifier);
    previousTimezoneId = ref.read(timezoneProvider).timezoneId;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timezoneProvider);
    return StyledAppPageView(
      title: getAppLocalizations(context).timezone,
      onBackTap: _isEdited(state.timezoneId)
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                _discardChanges(state.supportedTimezones);
                context.pop();
              }
            }
          : null,
      bottomBar: PageBottomBar(
          isPositiveEnabled: true,
          onPositiveTap: () {
            doSomethingWithSpinner(
              context,
              _notifier.save().then((value) {
                context.pop(true);
              }).catchError(
                (error, stackTrace) {
                  showFailedSnackBar(
                      context, loc(context).unknownErrorCode(error ?? ''));
                },
                test: (error) => error is JNAPError,
              ).onError((error, stackTrace) {
                showFailedSnackBar(context, loc(context).generalError);
              }),
              title: loc(context).savingChanges,
            );
          }),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(loc(context).daylightSavingsTime),
                semanticLabel: 'daylight savings time',
                value: state.isDaylightSaving,
                onChanged: _notifier.isSupportDaylightSaving()
                    ? (value) {
                        _notifier.setDaylightSaving(value);
                      }
                    : null,
              ),
            ),
            const AppGap.medium(),
            Expanded(
              // height: (70.0) * state.supportedTimezones.length +
              //     16 * (state.supportedTimezones.length - 1),
              child: AppCard(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemCount: state.supportedTimezones.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AppListCard(
                        showBorder: false,
                        padding: EdgeInsets.zero,
                        title: AppText.labelLarge(
                          getTimeZoneRegionName(context,
                              state.supportedTimezones[index].timeZoneID),
                          color: _notifier.isSelectedTimezone(index)
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        description: AppText.bodyMedium(
                          getTimezoneGMT(
                              state.supportedTimezones[index].description),
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
                  separatorBuilder: (BuildContext context, int index) {
                    return index != (state.supportedTimezones.length - 1)
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

  bool _isEdited(String timezoneId) {
    return timezoneId != previousTimezoneId;
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

  void _discardChanges(List<SupportedTimezone> supportedTimezones) {
    final index = supportedTimezones
        .indexWhere((timezone) => timezone.timeZoneID == previousTimezoneId);
    _notifier.setSelectedTimezone(index);
  }
}
