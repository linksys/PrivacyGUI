import 'package:flutter/material.dart';
import 'package:moab_poc/design/colors.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

import '../../components/base_components/button/primary_button.dart';

class SetLocationView extends StatefulWidget {
  const SetLocationView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  @override
  State<SetLocationView> createState() => _SetLocationViewState();
}

class _SetLocationViewState extends State<SetLocationView> {
  int _selected = -1;
  final List<String> data = locationList;

  @override
  void initState() {
    super.initState();
    print('Set Location: initState!');
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Give your node a name',
          description: 'This helps when telling your nodes apart.',
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
                text: 'Next',
                onPress: _selected >= 0 ? widget.onNext : null,
              ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
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
