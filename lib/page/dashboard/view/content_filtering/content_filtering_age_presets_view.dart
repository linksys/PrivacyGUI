import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';

import 'component.dart';

typedef ValueChanged<T> = void Function(T value);

List<CFPreset> _presets = [CFPreset.child(), CFPreset.teen(), CFPreset.adult()];

class ContentFilteringPresetsView extends ArgumentsStatefulView {
  const ContentFilteringPresetsView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<ContentFilteringPresetsView> createState() =>
      _ContentFilteringPresetsViewState();
}

class _ContentFilteringPresetsViewState
    extends State<ContentFilteringPresetsView> {
  late final Profile? _profile;
  late CFPreset? _preset;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profile = context.read<ProfilesCubit>().state.selectedProfile;
    _preset = widget.args['preset'] as CFPreset? ?? _presets[1];
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
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
                                _preset!.category, _preset!.filters)
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
                InputField(
                  titleText: '',
                  hintText: 'Search by app name',
                  controller: _controller,
                  prefixIcon: Icon(Icons.search),
                  customPrimaryColor: Colors.black,
                ),
                box36(),
                _filterList(),
              ],
            ),
          ),
          box36(),
          SimpleTextButton(text: 'Send feedback', onPressed: () {}),
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
                      (element) => element.category == _preset!.category);
                  if (prevIndex != -1) {
                    final latest = _presets
                        .firstWhere(
                            (element) => element.category == _preset!.category)
                        .copyWith(filters: _preset!.filters);
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

  Widget _presetItem(CFPreset preset, bool isSelected) {
    return Column(
      children: [
        Hero(
          tag: 'preset_${preset.name}',
          child: Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _preset?.category == preset.category
                        ? Colors.white
                        : preset.color,
                    width: 3)),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: preset.color,
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
        ...?_preset?.filters.map((e) => InkWell(
            onTap: () async {
              final newCategory = await showPopup(
                      context: context,
                      config: CFFilterCategoryPath()..args = {'selected': e})
                  as CFFilterCategory;
              if (newCategory != null) {
                final index = _preset?.filters.indexOf(e) ?? -1;
                if (index != -1) {
                  final list =
                      List<CFFilterCategory>.from(_preset?.filters ?? []);
                  setState(() {
                    list.replaceRange(index, index + 1, [newCategory]);
                    _preset = _preset?.copyWith(filters: list);
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
  FilterStatus _checkStatus(CFFilterCategory category) {
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
