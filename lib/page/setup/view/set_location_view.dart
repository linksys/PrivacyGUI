import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/setup/state.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/route/route.dart';

import '../../../bloc/setup/bloc.dart';
import '../../../bloc/setup/event.dart';
import '../../components/base_components/button/primary_button.dart';
import 'package:linksys_moab/route/model/model.dart';

class SetLocationView extends StatefulWidget {
  const SetLocationView({
    Key? key,
  }) : super(key: key);

  @override
  State<SetLocationView> createState() => _SetLocationViewState();
}

class _SetLocationViewState extends State<SetLocationView> {
  int _selected = -1;
  final List<String> data = locationList;
  final TextEditingController nameController = TextEditingController();

  void _nameOnChange(_) {
    setState(() {
      //TODO update select or custom name
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<SetupBloc>().add(const ResumePointChanged(status: SetupResumePoint.LOCATION));
    print('Set Location: initState!');
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
        child: _selected != 8
            ? BasicLayout(
                header: BasicHeader(
                  title: getAppLocalizations(context).name_node_view_title,
                  description: getAppLocalizations(context)
                      .name_node_view_title_description,
                ),
                content: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24.0, 0, 0),
                  child: ListView.builder(
                      itemCount: data.length, itemBuilder: _buildListItem),
                ),
                footer: Column(
                  children: [
                    if (_selected >= 0)
                      PrimaryButton(
                        text: getAppLocalizations(context).next,
                        onPress: _selected >= 0
                            ? () =>
                            NavigationCubit.of(context).push(SetupCustomizeSSIDPath())
                            : null,
                      ),
                  ],
                ),
                alignment: CrossAxisAlignment.start,
              )
            : BasicLayout(
                header: BasicHeader(
                  title: getAppLocalizations(context).name_node_view_title,
                ),
                content: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24.0, 0, 0),
                  child: InputField(
                    titleText: getAppLocalizations(context).name_node_view_custom_name,
                    hintText: getAppLocalizations(context).name_node_view_hint_text,
                    controller: nameController,
                    onChanged: _nameOnChange,
                  ),
                ),
                footer: Column(
                  children: [
                      PrimaryButton(
                        text: getAppLocalizations(context).save,
                        onPress: _selected >= 0
                            ? () =>
                            NavigationCubit.of(context).push(SetupCustomizeSSIDPath())
                            : null,
                      ),
                  ],
                ),
                alignment: CrossAxisAlignment.start,
              ));
  }

  Widget _buildListItem(BuildContext context, int index) {
    return ListTile(
      onTap: () {
        setState(() {
          if (index == _selected) {
            _selected = -1;
          } else {
            _selected = index;
          }
        });
      },
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(data[index]),
          )),
          index == _selected
              ? const Icon(
                  Icons.check,
                  color: MoabColor.listItemCheck,
                )
              : const Center()
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    print('Set Location: dispose!');
  }
}

const locationList = [
  'Bedroom',
  'Living Room',
  'Dining Room',
  'Kitchen',
  'Sitting Room',
  'Office',
  'Garage',
  'Studio',
  'Custom'
];
