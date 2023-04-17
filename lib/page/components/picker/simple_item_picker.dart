import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

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
  const SimpleItemPickerView({super.key, super.next, super.args});

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
    return BasePageView.onDashboardSecondary(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // iconTheme:
        // IconThemeData(color: Theme.of(context).colorScheme.primary),
        elevation: 0,
        title: Text(
          getAppLocalizations(context).connection_type,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: BasicLayout(
        content: Column(
          children: [
            box24(),
            ..._items.map((item) {
              return ListTile(
                title: Text(item.title),
                subtitle: Text(item.description),
                trailing: SizedBox(
                  child: item.id == _selected
                      ? Image.asset('assets/images/icon_check_black.png')
                      : null,
                  height: 36,
                  width: 36,
                ),
                contentPadding: const EdgeInsets.only(bottom: 24),
                enabled: !_disabled.contains(item.id),
                onTap: _disabled.contains(item.id)
                    ? null
                    : () {
                        setState(() {
                          _selected = item.id;
                        });
                        ref
                            .read(navigationsProvider.notifier)
                            .popWithResult(_selected);
                      },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
