import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/content_filter/cubit.dart';
import 'package:linksys_moab/bloc/profiles/_profiles.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/model/secure_profile.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/content_filter_path.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/security/security_profile_manager.dart';


class ContentFilterOverviewView extends ArgumentsStatefulView {
  const ContentFilterOverviewView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<ContentFilterOverviewView> createState() =>
      _ContentFilterOverviewViewState();
}

class _ContentFilterOverviewViewState
    extends State<ContentFilterOverviewView> {
  ContentFilterData? _data;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(builder: (context, state) {
      _data = context.read<ProfilesCubit>().state.selectedProfile?.contentFilterConfig?.data;
      return BasePageView.onDashboardSecondary(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(state.selectedProfile?.name ?? '',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading: BackButton(onPressed: () {
            NavigationCubit.of(context).pop();
          }),
        ),
        child: Column(
          children: [
            box16(),
            _contentFilterToggle(_data?.isEnabled ?? false, _data?.profileId ?? ''),
            _contentFilterLevel(_data),
          ],
        ),
      );
    });
  }

  Widget _contentFilterToggle(bool isEnabled, String profileId) {
    return SettingTile(
        title: Text(getAppLocalizations(context).content_filter_toggle_title),
        value: Switch.adaptive(value: isEnabled, onChanged: (value) {
          context.read<ProfilesCubit>().updateContentFilterEnabled(profileId, value);
        }));
  }

  Widget _contentFilterLevel(ContentFilterData? data) {
    CFSecureProfile? _preset = data?.secureProfile;

    return SettingTile(
      title: Text(getAppLocalizations(context).content_filter_level_title),
      value: _preset == null
          ? CFPresetLabel(
              name: 'none',
              color: Colors.transparent,
            )
          : CFPresetLabel(
              name: _preset.name,
              color: SecurityProfileManager.colorMapping(_preset.id),
            ),
      onPress: () {
        context.read<ContentFilterCubit>().selectSecureProfile(_preset);
        NavigationCubit.of(context).push(CFPresetsPath()..args = {'profileId': data?.profileId});
      },
    );
  }
}

class CFPresetLabel extends StatelessWidget {
  const CFPresetLabel({Key? key, required this.name, required this.color})
      : super(key: key);

  const CFPresetLabel.child({Key? key})
      : name = 'Child',
        color = MoabColor.contentFilterChildPreset,
        super(key: key);

  const CFPresetLabel.teen({Key? key})
      : name = 'Teen',
        color = MoabColor.contentFilterTeenPreset,
        super(key: key);

  const CFPresetLabel.adult({Key? key})
      : name = 'Adult',
        color = MoabColor.contentFilterAdultPreset,
        super(key: key);

  const CFPresetLabel.none({Key? key})
      : name = 'none',
        color = Colors.transparent,
        super(key: key);

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Hero(
          tag: 'preset_$name',
          child: Icon(
            Icons.circle,
            size: 12,
            color: color,
          ),
        ),
        box8(),
        Text(name),
      ],
    );
  }
}
