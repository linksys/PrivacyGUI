import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';

class MTUPickerView extends ArgumentsConsumerStatefulView {
  const MTUPickerView({super.key, super.args});

  @override
  ConsumerState<MTUPickerView> createState() => _MTUPickerViewState();
}

class _MTUPickerViewState extends ConsumerState<MTUPickerView> {
  final _valueController = TextEditingController();
  late final List<String> _items = ['Auto', 'Manual'];
  String _selected = '';
  String _wanType = '';

  @override
  void initState() {
    _wanType = widget.args['wanType'] ?? '';
    int value = widget.args['selected'] ?? 0;
    if (value > 0) {
      _valueController.text = '$value';
      _selected = _items[1];
    } else {
      _selected = _items[0];
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    _valueController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: loc(context).connectionType,
      bottomBar: PageBottomBar(
        isPositiveEnabled: true,
        onPositiveTap: save,
      ),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppRadioList(
              initial: _selected,
              itemHeight: 56,
              items: [
                AppRadioListItem(
                  title: loc(context).auto,
                  value: _items[0],
                ),
                AppRadioListItem(
                  title: loc(context).manual,
                  value: _items[1],
                ),
              ],
              onChanged: (index, item) {
                setState(() {
                  _selected = _items[index];
                });
              },
            ),
            _buildManualInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInput() {
    if (_selected == _items[1]) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: AppTextField.minMaxNumber(
          controller: _valueController,
          border: const OutlineInputBorder(),
          headerText: loc(context).size,
          hintText: loc(context).size,
          inputType: TextInputType.number,
          min: 0,
          max: _getMaxMtu(_wanType),
        ),
      );
    } else {
      return const Center();
    }
  }

  int _getMaxMtu(String wanType) {
    switch (WanType.resolve(wanType)) {
      case WanType.dhcp:
        return 1500;
      case WanType.pppoe:
        return 1492;
      case WanType.static:
        return 1500;
      case WanType.pptp:
        return 1460;
      case WanType.l2tp:
        return 1460;
      default:
        return 0;
    }
  }

  void save() {
    FocusManager.instance.primaryFocus?.unfocus();
    context.pop(_selected == _items[0]
        ? 0
        : (int.tryParse(_valueController.text)) ?? 0);
  }
}
