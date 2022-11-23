import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/util/string_mapping.dart';

class MTUPickerView extends ArgumentsStatefulView {
  const MTUPickerView({super.key, super.next, super.args});

  @override
  State<MTUPickerView> createState() => _MTUPickerViewState();
}

class _MTUPickerViewState extends State<MTUPickerView> {
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
        actions: [
          SimpleTextButton(
            text: getAppLocalizations(context).done,
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              NavigationCubit.of(context).popWithResult(_selected == _items[0]
                  ? 0
                  : (int.tryParse(_valueController.text)) ?? 0);
            },
          ),
        ],
      ),
      child: BasicLayout(
        content: Column(
          children: [
            box24(),
            ..._items.map((item) {
              return ListTile(
                title: Text(_getTitle(item)),
                trailing: SizedBox(
                  child: item == _selected
                      ? Image.asset('assets/images/icon_check_black.png')
                      : null,
                  height: 36,
                  width: 36,
                ),
                contentPadding: const EdgeInsets.only(bottom: 24),
                onTap: () {
                  setState(() {
                    _selected = item;
                  });
                  if (_selected == item[0]) {}
                },
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
      return InputField(
        titleText: getAppLocalizations(context).mtu_size,
        controller: _valueController,
        inputType: TextInputType.number,
        customPrimaryColor: Colors.black,
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
