import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

class MTUPickerView extends ArgumentsConsumerStatefulView {
  const MTUPickerView({super.key, super.next, super.args});

  @override
  ConsumerState<MTUPickerView> createState() => _MTUPickerViewState();
}

class _MTUPickerViewState extends ConsumerState<MTUPickerView> {
  final _valueController = TextEditingController();
  late final List<String> _items = ['Auto', 'Manual'];
  String _selected = '';

  @override
  void initState() {
    int _value = widget.args['selected'] ?? 0;
    if (_value > 0) {
      _valueController.text = '$_value';
      _selected = _items[1];
    } else {
      _selected = _items[0];
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledLinksysPageView(
      title: getAppLocalizations(context).connection_type,
      actions: [
        LinksysTertiaryButton(
          getAppLocalizations(context).done,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            ref.read(navigationsProvider.notifier).popWithResult(
                _selected == _items[0]
                    ? 0
                    : (int.tryParse(_valueController.text)) ?? 0);
          },
        ),
      ],
      child: LinksysBasicLayout(
        content: Column(
          children: [
            const LinksysGap.semiBig(),
            ..._items.map((item) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _selected = item;
                  });
                  if (_selected == item[0]) {}
                },
                child: AppPanelWithValueCheck(
                  title: _getTitle(item),
                  valueText: '',
                  isChecked: _selected == item,
                ),
              );
            }).toList(),
            _buildManualInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInput() {
    if (_selected == _items[1]) {
      return AppTextField(
        controller: _valueController,
        headerText: getAppLocalizations(context).mtu_size,
        hintText: getAppLocalizations(context).mtu_size,
        inputType: TextInputType.number,
      );
    } else {
      return const Center();
    }
  }

  _getTitle(String value) {
    if (value == _items[0]) {
      return getAppLocalizations(context).auto;
    } else {
      return getAppLocalizations(context).manual;
    }
  }
}
