import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/route/model/internet_schedule_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import '../../../../design/colors.dart';

class DailyTimeLimitListView extends ConsumerWidget {
  const DailyTimeLimitListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return timeListItem(context, ref);
  }

  Widget timeListItem(BuildContext context, WidgetRef ref) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(builder: (context, state) {
      final profile = state.selectedProfile!;
      final data = profile.serviceDetails[PService.internetSchedule]
          as InternetScheduleData?;
      return StyledAppPageView(
          title: getAppLocalizations(context).daily_time_limit,
          actions: [
            AppTertiaryButton(
              getAppLocalizations(context).add,
              onTap: () {
                //TODO: There's no longer profileId!!
                ref.read(navigationsProvider.notifier).push(
                    AddDailyTimeLimitPath()
                      ..args = {'profileId': profile.name});
              },
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.regular(),
              ..._buildTimeLimitItems(context, ref, data),
            ],
          ));
    });
  }

  List<Widget> _buildTimeLimitItems(
      BuildContext context, WidgetRef ref, InternetScheduleData? data) {
    final rules = data?.dateTimeLimitRule ?? [];
    if (rules.isEmpty) {
      return [
        const Center(
          child: AppText.descriptionMain('No data!'),
        )
      ];
    } else {
      List<Widget> items = [
        for (DateTimeLimitRule item in rules) ...{
          DailyTimeLimitItem(
              item: item,
              onStatusChanged: (value) {
                // item.isEnabled = value;
                context.read<ProfilesCubit>().updateDailyTimeLimitEnabled(
                    data?.profileId ?? '', item, value);
              },
              onPress: () {
                ref.read(navigationsProvider.notifier).push(
                    AddDailyTimeLimitPath()
                      ..args = {
                        'rule': item.copyWith(),
                        'profileId': data?.profileId
                      });
              }),
          const AppGap.semiSmall(),
        }
      ];
      return items;
    }
  }
}

class DailyTimeLimitItem extends ConsumerStatefulWidget {
  DailyTimeLimitItem({
    Key? key,
    required this.item,
    required this.onStatusChanged,
    required this.onPress,
  }) : super(key: key);
  DateTimeLimitRule item;
  ValueChanged onStatusChanged;
  VoidCallback onPress;

  @override
  ConsumerState<DailyTimeLimitItem> createState() => _dailyTimeLimitItemState();
}

class _dailyTimeLimitItemState extends ConsumerState<DailyTimeLimitItem> {
  bool isOn = false;

  @override
  void initState() {
    super.initState();
    isOn = widget.item.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        color: const Color.fromRGBO(217, 217, 217, 1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPanelWithSwitch(
              value: widget.item.isEnabled,
              title: Utils.toWeeklyStringList(context, widget.item.weeklySet)
                  .join(' ,'),
              onChangedEvent: (value) {
                setState(() {
                  isOn = value;
                });
                widget.onStatusChanged(value);
              },
            ),
            const AppGap.semiBig(),
            InkWell(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.mainTitle(
                      Utils.formatTimeHM(widget.item.timeInSeconds),
                      color: const Color.fromRGBO(0, 0, 0, 0.5),
                    ),
                    Image.asset('assets/images/right_compact_wire.png')
                  ]),
              onTap: () {
                widget.onPress();
              },
            )
          ],
        ));
  }
}

class TimeLimit {
  TimeLimit(this.days, this.duration, this.status);

  String days;
  String duration;
  bool status;
}
