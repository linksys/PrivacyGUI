import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class Item {
  final String title;
  final String description;
  final String id;

  const Item({
    required this.title,
    this.description = '',
    required this.id,
  });

  Item copyWith({
    String? title,
    String? description,
    String? id,
  }) {
    return Item(
      title: title ?? this.title,
      description: description ?? this.description,
      id: id ?? this.id,
    );
  }
}

class SimpleItemPickerView extends ArgumentsStatefulView {
  const SimpleItemPickerView({super.key, super.next, super.args});

  @override
  State<SimpleItemPickerView> createState() => _SimpleItemPickerViewState();
}

class _SimpleItemPickerViewState extends State<SimpleItemPickerView> {
  late final List<Item> _items;
  late final List<String> _disabled;
  String _selected = '';

  @override
  void initState() {
    _items = widget.args['items'] ?? [];
    _disabled = widget.args['disabled'] ?? [];
    _selected = widget.args['selected'] ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledLinksysPageView(
      title: getAppLocalizations(context).connection_type,
      child: LinksysBasicLayout(
        content: Column(
          children: [
            const LinksysGap.semiBig(),
            ..._items.map((item) {
              return InkWell(
                onTap: _disabled.contains(item.id)
                    ? null
                    : () {
                        setState(() {
                          _selected = item.id;
                        });
                        NavigationCubit.of(context).popWithResult(_selected);
                      },
                child: AppPanelWithValueCheck(
                  title: item.title,
                  description: item.description,
                  valueText: ' ',
                  isChecked: item.id == _selected,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
