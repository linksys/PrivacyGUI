import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/space/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/content_filtering/content_filtering_age_presets_view.dart';
import 'package:linksys_moab/page/dashboard/view/content_filtering/content_filtering_view.dart';
import 'package:linksys_moab/page/dashboard/view/content_filtering/model.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';

typedef ValueChanged<T> = void Function(T value);

class ContentFilteringProfileSettingsView extends ArgumentsStatefulView {
  const ContentFilteringProfileSettingsView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<ContentFilteringProfileSettingsView> createState() =>
      _ContentFilteringProfileSettingsViewState();
}

class _ContentFilteringProfileSettingsViewState
    extends State<ContentFilteringProfileSettingsView> {
  late final Profile _profile;
  late final CFPreset _preset;

  @override
  void initState() {
    super.initState();
    _profile = widget.args['profile'] as Profile;
    _preset = CFPreset.teen();
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_profile.name,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
      ),
      child: Column(
        children: [
          box16(),
          _contentFilterToggle(),
          _contentFilterLevel(),
        ],
      ),
    );
  }

  Widget _contentFilterToggle() {
    return SettingTile(
        title: Text(getAppLocalizations(context).content_filter_toggle_title),
        value: Switch.adaptive(value: true, onChanged: (value) {}));
  }

  Widget _contentFilterLevel() {
    return SettingTile(
      title: Text(getAppLocalizations(context).content_filter_level_title),
      value: CFPresetLabel(name: _preset.name, color: _preset.color,),
      onPress: () {
        NavigationCubit.of(context).push(CFPresetsPath()..args = {'profile': _profile, 'selected': _preset});
      },
    );
  }
}

class CFPresetLabel extends StatelessWidget {
  const CFPresetLabel({Key? key, required this.name, required this.color}) : super(key: key);

  const CFPresetLabel.child({Key? key}): name = 'Child', color = MoabColor.contentFilterChildPreset, super(key: key);
  const CFPresetLabel.teen({Key? key}): name = 'Teen', color = MoabColor.contentFilterTeenPreset, super(key: key);
  const CFPresetLabel.adult({Key? key}): name = 'Adult', color = MoabColor.contentFilterAdultPreset, super(key: key);
  const CFPresetLabel.none({Key? key}): name = 'none', color = Colors.transparent, super(key: key);


  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(
          Icons.circle,
          size: 12,
          color: color,
        ),
        box8(),
        Text(name),
      ],
    );
  }
}
