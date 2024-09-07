import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_provider.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/util/timezone.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    _notifier = ref.read(timezoneProvider.notifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timezoneProvider);
    return _isLoading
        ? AppFullScreenSpinner(
            title: loc(context).savingChanges,
          )
        : StyledAppPageView(
            // scrollable: true,
            title: getAppLocalizations(context).timezone,
            bottomBar: PageBottomBar(
                isPositiveEnabled: true,
                onPositiveTap: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _notifier.save().then((_) {
                    _isLoading = false;
                    context.pop(true);
                  });
                }),
            child: AppBasicLayout(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppGap.large2(),
                  AppCard(
                    child: AppPanelWithSwitch(
                      title: loc(context).daylightSavingsTime,
                      value: state.isDaylightSaving,
                      onChangedEvent: _notifier.isSupportDaylightSaving()
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
                                getTimezoneGMT(state
                                    .supportedTimezones[index].description),
                                color: _notifier.isSelectedTimezone(index)
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              trailing: _notifier.isSelectedTimezone(index)
                                  ? Icon(
                                      LinksysIcons.check,
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
}
