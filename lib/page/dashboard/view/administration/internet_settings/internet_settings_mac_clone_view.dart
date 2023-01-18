import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/mac_input_field.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

import '../common_widget.dart';

class MACCloneView extends ArgumentsStatefulView {
  const MACCloneView({super.key, super.next, super.args});

  @override
  State<MACCloneView> createState() => _MACCloneViewState();
}

class _MACCloneViewState extends State<MACCloneView> {
  final _valueController = TextEditingController();
  late final List<String> _items = ['Auto', 'Manual'];

  final InputValidator _macValidator = InputValidator([MACAddressRule()]);
  bool _isValid = false;
  bool _isEnabled = false;

  @override
  void initState() {
    _isEnabled = widget.args['enabled'] ?? false;
    String macAddress = widget.args['macAddress'] ?? '';
    _valueController.text = macAddress;
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
          getAppLocalizations(context).mac_address_clone,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          SimpleTextButton(
            text: getAppLocalizations(context).save,
            onPressed: _isValid
                ? () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    NavigationCubit.of(context).popWithResult(
                        _isEnabled ? _valueController.value : '');
                  }
                : null,
          ),
        ],
      ),
      child: BasicLayout(
        content: Column(
          children: [
            box24(),
            administrationTile(
                title: title(getAppLocalizations(context).enabled),
                value: Switch.adaptive(
                    value: true,
                    onChanged: (value) {
                      setState(() {
                        _isEnabled = value;
                      });
                    })),
            _buildMACInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMACInput() {
    if (_isEnabled) {
      return MACInputField(
        titleText: getAppLocalizations(context).enter_mac_address,
        controller: _valueController,
        onChanged: (value) {
          setState(() {
            _isValid = _macValidator.validate(value);
          });
        },
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
