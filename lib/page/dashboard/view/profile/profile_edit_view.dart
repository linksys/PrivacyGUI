import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/content_filter/cubit.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/shortcuts/profiles.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/route/model/content_filter_path.dart';
import 'package:linksys_moab/route/model/internet_schedule_path.dart';
import 'package:linksys_moab/route/model/profile_group_path.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

import '../../../../design/colors.dart';
import '../../../../localization/localization_hook.dart';
import '../../../components/views/arguments_view.dart';

class ProfileEditView extends ArgumentsConsumerStatefulView {
  const ProfileEditView({Key? key, super.args, super.next}) : super(key: key);

  @override
  ConsumerState<ProfileEditView> createState() => _ProfileEditViewViewState();
}

class _ProfileEditViewViewState extends ConsumerState<ProfileEditView> {
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
            ref.read(navigationsProvider.notifier).pop();
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
                ref
                    .read(navigationsProvider.notifier)
                    .push(ProfileEditNameAvatarPath());
              },
            ),
            box16(),
            SettingTile(
              title: Text(getAppLocalizations(context).devices),
              value: Text('${state.selectedProfile!.devices.length}'),
              onPress: () {
                showPopup(
                        ref: ref,
                        config: CreateProfileDevicesSelectedPath()
                          ..args = {'return': true})
                    .then((value) {
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
                  ref
                      .read(navigationsProvider.notifier)
                      .push(ContentFilteringOverviewPath());
                } else {
                  context.read<ContentFilterCubit>().selectSecureProfile(null);
                  //TODO: There's no longer profileId!!
                  ref.read(navigationsProvider.notifier).push(CFPresetsPath()
                    ..args = {'profileId': state.selectedProfile?.name});
                }
              },
            ),
            box16(),
            SettingTile(
              title: Text(getAppLocalizations(context).internet_schedules),
              value: Text(state.selectedProfile!
                  .serviceOverallStatus(context, PService.internetSchedule)),
              onPress: () {
                ref
                    .read(navigationsProvider.notifier)
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
