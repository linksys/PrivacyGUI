import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/internet_settings/_internet_settings.dart';
import 'package:linksys_app/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class MACCloneView extends ArgumentsConsumerStatefulView {
  const MACCloneView({super.key, super.args});

  @override
  ConsumerState<MACCloneView> createState() => _MACCloneViewState();
}

class _MACCloneViewState extends ConsumerState<MACCloneView> {
  final _valueController = TextEditingController();
  late final List<String> _items = ['Auto', 'Manual'];

  final InputValidator _macValidator = InputValidator([MACAddressRule()]);
  bool _isValid = false;
  bool _isEnabled = false;
  late InternetSettingsState state;

  @override
  void initState() {
    state = ref.read(internetSettingsProvider);
    _isEnabled = widget.args['enabled'] ?? false;
    String macAddress = widget.args['macAddress'] ?? '';
    _valueController.text = macAddress;
    _isValid = _macValidator.validate(macAddress);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: getAppLocalizations(context).mac_address_clone,
      actions: [
        AppTextButton(
          getAppLocalizations(context).save,
          onTap: _isValid &&
                  ((_isEnabled != state.macClone) ||
                      (_valueController.text != state.macCloneAddress))
              ? () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  context.pop(_isEnabled ? _valueController.text : '');
                }
              : null,
        ),
      ],
      child: AppBasicLayout(
        content: Column(
          children: [
            const AppGap.semiBig(),
            AppPanelWithSwitch(
              value: _isEnabled,
              title: getAppLocalizations(context).enabled,
              onChangedEvent: (value) {
                setState(() {
                  _isEnabled = value;
                });
              },
            ),
            _buildMACInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMACInput() {
    if (_isEnabled) {
      return AppTextField.macAddress(
        controller: _valueController,
        headerText: getAppLocalizations(context).enter_mac_address,
        hintText: getAppLocalizations(context).mac_address,
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
}
