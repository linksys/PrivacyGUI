import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
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

class SimpleItemPickerView extends ArgumentsConsumerStatefulView {
  const SimpleItemPickerView({super.key, super.args});

  @override
  ConsumerState<SimpleItemPickerView> createState() =>
      _SimpleItemPickerViewState();
}

class _SimpleItemPickerViewState extends ConsumerState<SimpleItemPickerView> {
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
    return StyledAppPageView(
      title: getAppLocalizations(context).connectionType,
      child: AppBasicLayout(
        content: Column(
          children: [
            const AppGap.semiBig(),
            ..._items.map((item) {
              return InkWell(
                onTap: _disabled.contains(item.id)
                    ? null
                    : () {
                        setState(() {
                          _selected = item.id;
                        });
                        context.pop(_selected);
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
