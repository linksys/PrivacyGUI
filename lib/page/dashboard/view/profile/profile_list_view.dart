import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/content_filter/cubit.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';


class ProfileListView extends ArgumentsConsumerStatefulView {
  const ProfileListView({Key? key, super.args, super.next}) : super(key: key);

  @override
  ConsumerState<ProfileListView> createState() => _ProfileListViewState();
}

class _ProfileListViewState extends ConsumerState<ProfileListView> {
  late PService _category;

  @override
  void initState() {
    _category = widget.args['category'] ?? PService.all;
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
            title: _buildTitle(),
            leading: BackButton(onPressed: () {
              ref.read(navigationsProvider.notifier).pop();
            }),
            actions: [
              TextButton(
                  onPressed: () {
                    ref.read(navigationsProvider.notifier).push(
                        CreateProfileNamePath()..next = ProfileListPath());
                  },
                  child: Text(getAppLocalizations(context).add_profile,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: MoabColor.textButtonBlue))),
            ],
          ),
          child: Container(
              color: const Color.fromARGB(1, 221, 221, 221),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _buildDescriptions(),
                  const SizedBox(height: 24),
                  profileList(context, state.profileList)
                ],
              )));
    });
  }

  Widget _buildTitle() {
    String title = getAppLocalizations(context).title_content_filters;
    if (_category == PService.internetSchedule) {
      title = getAppLocalizations(context).internet_schedules;
    } else if (_category == PService.contentFilter) {
      title = getAppLocalizations(context).title_content_filters;
    }
    return Text(title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700));
  }

  Widget _buildDescriptions() {
    String desc = '';
    if (_category == PService.internetSchedule) {
      desc = getAppLocalizations(context).internet_schedule_view_description;
    } else if (_category == PService.contentFilter) {
      desc = getAppLocalizations(context).content_filters_description;
    }
    return desc.isEmpty
        ? const Center()
        : Text(desc,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500));
  }

  Widget profileList(BuildContext context, List<UserProfile> list) {
    return Column(
      children: [
        ...list.map((item) {
          return Column(children: [
            GestureDetector(
              child: Hero(
                tag: 'profile-${item.name}',
                child: profileCard(
                  Image.asset(
                    item.icon,
                    width: 32,
                    height: 32,
                  ),
                  Text(
                    item.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  _profileValue(item),
                ),
              ),
              onTap: () {
                _onProfileClick(item);
              },
            ),
            const SizedBox(height: 8)
          ]);
        })
      ],
    );
  }

  _onProfileClick(UserProfile profile) {
    BasePath path = ProfileOverviewPath();
    if (_category == PService.internetSchedule) {
      path = InternetScheduleOverviewPath();
    } else if (_category == PService.contentFilter) {
      bool hasData = profile.hasServiceDetail(_category);
      if (hasData) {
        path = ContentFilteringOverviewPath();
      } else {
        context.read<ContentFilterCubit>().selectSecureProfile(null);
        //TODO: There's no longer profileId!!
        path = CFPresetsPath()..args = {'profileId': profile.name};
      }
    }
    context.read<ProfilesCubit>().selectProfile(profile);
    ref.read(navigationsProvider.notifier).push(path);
  }

  Widget _profileValue(UserProfile profile) {
    return Text(profile.serviceOverallStatus(context, _category),
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color.fromRGBO(102, 102, 102, 1.0)));
  }

  Widget profileCard(Widget image, Widget text, Widget value) {
    return Container(
      height: 82,
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 16),
          image,
          const SizedBox(width: 21),
          Expanded(child: text),
          const SizedBox(width: 8),
          value,
          const SizedBox(width: 6),
          Image.asset('assets/images/right_compact_wire.png'),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
