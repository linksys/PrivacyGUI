import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/timezone/timezone_provider.dart';
import 'package:linksys_app/util/timezone.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class TimezoneView extends ArgumentsConsumerStatelessView {
  const TimezoneView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TimezoneContentView(
      args: super.args,
    );
  }
}

class TimezoneContentView extends ArgumentsConsumerStatefulView {
  const TimezoneContentView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<TimezoneContentView> createState() =>
      _TimezoneContentViewState();
}

class _TimezoneContentViewState extends ConsumerState<TimezoneContentView> {
  late final TimezoneNotifier _notifier;

  @override
  void initState() {
    ref.read(timezoneProvider.notifier).fetch();
    _notifier = ref.read(timezoneProvider.notifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timezoneProvider);
    return StyledAppPageView(
      scrollable: true,
      title: getAppLocalizations(context).timezone,
      actions: [
        AppTertiaryButton(
          getAppLocalizations(context).save,
          onTap: () {
            _notifier.save().then((_) => showSuccessSnackBar(
                context, getAppLocalizations(context).timezone_updated));
          },
        ),
      ],
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.semiBig(),
            AppPanelWithSwitch(
              title: getAppLocalizations(context).daylight_savings_time,
              value: state.isDaylightSaving,
              onChangedEvent: _notifier.isSupportDaylightSaving()
                  ? (value) {
                      _notifier.setDaylightSaving(value);
                    }
                  : null,
            ),
            const AppGap.big(),
            SizedBox(
              height: (70.0) * state.supportedTimezones.length,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.supportedTimezones.length,
                itemBuilder: (context, index) => InkWell(
                  child: AppPanelWithValueCheck(
                    title: getTimeZoneRegionName(
                        context, state.supportedTimezones[index].timeZoneID),
                    description: getTimezoneGMT(
                        state.supportedTimezones[index].description),
                    valueText: '',
                    isChecked: _notifier.isSelectedTimezone(index),
                  ),
                  onTap: () {
                    _notifier.setSelectedTimezone(index);
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
