import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/timezone/bloc/cubit.dart';
import 'package:linksys_moab/page/dashboard/view/administration/timezone/bloc/state.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/timezone.dart';

class TimezoneView extends ArgumentsStatelessView {
  const TimezoneView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimezoneCubit(context.read<RouterRepository>()),
      child: TimezoneContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class TimezoneContentView extends ArgumentsStatefulView {
  const TimezoneContentView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<TimezoneContentView> createState() => _TimezoneContentViewState();
}

class _TimezoneContentViewState extends State<TimezoneContentView> {
  late final TimezoneCubit _cubit;

  @override
  void initState() {
    _cubit = context.read<TimezoneCubit>();
    _cubit.fetch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimezoneCubit, TimezoneState>(builder: (context, state) {
      return BasePageView(
        scrollable: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // iconTheme:
          // IconThemeData(color: Theme.of(context).colorScheme.primary),
          elevation: 0,
          title: Text(
            getAppLocalizations(context).timezone,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            SimpleTextButton(
              text: getAppLocalizations(context).save,
              onPressed: () {
                _cubit.save().then((_) => showSuccessSnackBar(
                    context, getAppLocalizations(context).timezoneUpdated));
              },
            ),
          ],
        ),
        child: BasicLayout(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box24(),
              SettingTile(
                title: Text(
                  getAppLocalizations(context).daylight_savings_time,
                  style: const TextStyle(fontSize: 15),
                ),
                value: Switch.adaptive(
                  value: state.isDaylightSaving,
                  onChanged: _cubit.isSupportDaylightSaving()
                      ? (value) {
                          _cubit.setDaylightSaving(value);
                        }
                      : null,
                ),
              ),
              box36(),
              SizedBox(
                height: (38.0 + 26.0) * state.supportedTimezones.length,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.supportedTimezones.length,
                  itemBuilder: (context, index) => InkWell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getTimeZoneRegionName(context,
                                    state.supportedTimezones[index].timeZoneID),
                                style: const TextStyle(fontSize: 15),
                              ),
                              box4(),
                              Text(
                                getTimezoneGMT(state
                                    .supportedTimezones[index].description),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color.fromRGBO(102, 102, 102, 1.0),
                                ),
                              ),
                            ],
                          ),
                          if (_cubit.isSelectedTimezone(index)) ...[
                            const Spacer(),
                            Image.asset('assets/images/icon_check_black.png'),
                          ]
                        ],
                      ),
                    ),
                    onTap: () {
                      _cubit.setSelectedTimezone(index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
