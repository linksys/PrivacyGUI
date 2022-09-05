import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/profiles.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_home_view.dart';
import 'package:linksys_moab/route/model/dashboard_path.dart';
import 'package:linksys_moab/route/route.dart';

import '../../../../design/colors.dart';
import '../../../../localization/localization_hook.dart';
import '../../../components/views/arguments_view.dart';

class ProfileEditView extends ArgumentsStatefulView {
  const ProfileEditView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<ProfileEditView> createState() => _ProfileEditViewViewState();
}

class _ProfileEditViewViewState extends State<ProfileEditView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(builder: (context, state) {
      return BasePageView.onDashboardSecondary(
        scrollable: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(getAppLocalizations(context).profile_edit,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading: BackButton(onPressed: () {
            NavigationCubit.of(context).pop();
          }),
          actions: [
            Offstage(
              offstage: false,
              child: TextButton(
                  onPressed: () {},
                  child: Text(getAppLocalizations(context).save,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: MoabColor.textButtonBlue))),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box36(),
            SettingTile(
              title: Text(getAppLocalizations(context).name),
              value: profileTileShort(context, state.selectedProfile!),
              onPress: () {
                NavigationCubit.of(context).push(ProfileEditNameAvatarPath());
              },
            ),
            box16(),
            SettingTile(
              title: Text(getAppLocalizations(context).devices),
              value: Text('${state.selectedProfile!.devices.length}'),
              onPress: () {
                showPopup(
                    context: context,
                    config: CreateProfileDevicesSelectedPath()
                      ..args = {'return': true}).then((value) {
                        //TODO update selected devices
                });
              },
            ),
            box16(),
            SettingTile(
              title: Text(getAppLocalizations(context).title_content_filters),
              value: Text(state.selectedProfile!
                  .serviceOverallStatus(context, PService.contentFilter)),
              onPress: () {
                bool hasData = state.selectedProfile!
                    .hasServiceDetail(PService.contentFilter);
                if (hasData) {
                  NavigationCubit.of(context)
                      .push(ContentFilteringOverviewPath());
                } else {
                  NavigationCubit.of(context).push(CFPresetsPath());
                }
              },
            ),
            box16(),
            SettingTile(
              title: Text(getAppLocalizations(context).internet_schedules),
              value: Text(state.selectedProfile!
                  .serviceOverallStatus(context, PService.internetSchedule)),
              onPress: () {
                NavigationCubit.of(context)
                    .push(InternetScheduleOverviewPath());
              },
            ),
            box16(),
            SettingTile(
              title: Text(getAppLocalizations(context).enhanced_protection),
              value: Switch.adaptive(value: false, onChanged: (value) {}),
            ),
          ],
        ),
      );
    });
  }
}
