import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/space/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/content_filtering/model.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';

import 'component.dart';

typedef ValueChanged<T> = void Function(T value);

final List<CFPreset> _presets = [
  CFPreset.child(),
  CFPreset.teen(),
  CFPreset.adult()
];

class ContentFilteringPresetsView extends ArgumentsStatefulView {
  const ContentFilteringPresetsView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<ContentFilteringPresetsView> createState() =>
      _ContentFilteringPresetsViewState();
}

class _ContentFilteringPresetsViewState
    extends State<ContentFilteringPresetsView> {
  late final Profile _profile;
  late CFPreset _preset;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profile = widget.args['profile'] as Profile;
    _preset = widget.args['selected'] as CFPreset;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(getAppLocalizations(context).content_filter_presets_title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          box16(),
          _presetsSelector(),
          box36(),
          Text(_preset.description),
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
                  _preset = _presets[index];
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
        Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: _preset.category == preset.category
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
        Text(preset.name)
      ],
    );
  }

  Widget _filterList() {
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) => InkWell(
            onTap: () {
              NavigationCubit.of(context).push(CFFilterCategoryPath()..args = {'selected': _preset.filters[index]});
            },
            child: FilterItem(
              name: _preset.filters[index].name,
              status: _preset.filters[index].status,
            )),
        separatorBuilder: (_, __) => SizedBox(
          width: 16,
        ),
        itemCount: _preset.filters.length,
        shrinkWrap: true,
      ),
    );
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
