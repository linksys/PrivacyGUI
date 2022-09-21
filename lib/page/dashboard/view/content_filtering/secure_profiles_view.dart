import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/content_filter_path.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/security/security_profile_manager.dart';

import 'component.dart';

class ContentFilteringPresetsView extends ArgumentsStatefulView {
  const ContentFilteringPresetsView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<ContentFilteringPresetsView> createState() =>
      _ContentFilteringPresetsViewState();
}

class _ContentFilteringPresetsViewState
    extends State<ContentFilteringPresetsView> {
  List<CFSecureProfile> _presets = const [];
  late final Profile? _profile;
  late CFSecureProfile? _preset;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _profile = context.read<ProfilesCubit>().state.selectedProfile;
    SecurityProfileManager.instance().fetchDefaultPresets().then((value) {
      setState(() {
        _presets = value;
        _preset = widget.args['preset'] as CFSecureProfile? ?? _presets[1];
        isLoading = false;
      });
    });
    setState(() {
      isLoading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading ? FullScreenSpinner(text: getAppLocalizations(context).processing,) : BasePageView.onDashboardSecondary(
      scrollable: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(getAppLocalizations(context).content_filter_presets_title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
        actions: [
          Offstage(
            offstage: _preset == null,
            child: TextButton(
                onPressed: _preset == null
                    ? null
                    : () {
                        context
                            .read<ProfilesCubit>()
                            .updateContentFilterDetails(_profile?.id ?? '',
                                _preset!)
                            .then((value) => NavigationCubit.of(context).pop());
                      },
                child: const Text('Save',
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
          box16(),
          _presetsSelector(),
          box36(),
          Offstage(
            offstage: _preset == null,
            child: Column(
              children: [
                Text(_preset?.description ?? ''),
                box36(),
                InkWell(
                  onTap: () {
                    NavigationCubit.of(context).push(CFAppSearchPath());
                  },
                  child: Container(
                    decoration: BoxDecoration(color: MoabColor.dashboardTileBackground),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(children: [Icon(Icons.search), Text('Search by app name')],),
                    ),
                  ),
                ),
                box36(),
                _filterList(),
              ],
            ),
          ),
          box36(),
          SimpleTextButton(text: 'Send feedback', onPressed: () {}, padding: EdgeInsets.zero,),
          Text('Suggest a category or app'),
        ],
      ),
    );
  }

  Widget _presetsSelector() {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Center(
        child: ListView.separated(
          itemBuilder: (context, index) => InkWell(
              onTap: () {
                setState(() {
                  int prevIndex = _presets.indexWhere(
                      (element) => element.id == _preset!.id);
                  if (prevIndex != -1) {
                    final latest = _presets
                        .firstWhere(
                            (element) => element.id == _preset!.id)
                        .copyWith(securityCategories: _preset!.securityCategories);
                    _presets[prevIndex] = latest;
                  }
                  if (_preset == _presets[index]) {
                    _preset = null;
                  } else {
                    _preset = _presets[index];
                  }
                });
              },
              child: _presetItem(_presets[index], true)),
          separatorBuilder: (_, __) => SizedBox(
            width: 16,
          ),
          itemCount: _presets.length,
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
        ),
      ),
    );
  }

  Widget _presetItem(CFSecureProfile preset, bool isSelected) {
    return Column(
      children: [
        Hero(
          tag: 'preset_${preset.name}',
          child: Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _preset?.id == preset.id
                        ? Colors.white
                        : SecurityProfileManager.colorMapping(preset.id),
                    width: 3)),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SecurityProfileManager.colorMapping(preset.id),
              ),
              width: 49,
              height: 49,
            ),
          ),
        ),
        Text(preset.name)
      ],
    );
  }

  Widget _filterList() {
    return Column(
      children: [
        ...?_preset?.securityCategories.map((e) => InkWell(
            onTap: () async {
              final newCategory = await showPopup(
                      context: context,
                      config: CFFilterCategoryPath()..args = {'selected': e})
                  as CFSecureCategory;
              if (newCategory != null) {
                final index = _preset?.securityCategories.indexOf(e) ?? -1;
                if (index != -1) {
                  final list =
                      List<CFSecureCategory>.from(_preset?.securityCategories ?? []);
                  setState(() {
                    list.replaceRange(index, index + 1, [newCategory]);
                    _preset = _preset?.copyWith(securityCategories: list);
                  });
                }
              }
            },
            child: FilterItem(
              name: e.name,
              status: _checkStatus(e),
            )))
      ],
    );
  }
  FilterStatus _checkStatus(CFSecureCategory category) {
    return category.apps.fold<FilterStatus>(
        category.status,
            (value, element) => (value != FilterStatus.force && value != element.status) ? FilterStatus.someAllowed : value);
  }
}

class FilterItem extends StatelessWidget {
  const FilterItem({Key? key, required this.name, required this.status})
      : super(key: key);

  final String name;
  final FilterStatus status;

  @override
  Widget build(BuildContext context) {
    return (Row(
      children: [
        Icon(Icons.add),
        box8(),
        Expanded(child: Text(name)),
        createStatusButton(context, status),
      ],
    ));
  }
}
