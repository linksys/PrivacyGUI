import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

class DHCPReservationsEditView extends ArgumentsConsumerStatefulView {
  const DHCPReservationsEditView({super.key, super.args});

  @override
  ConsumerState<DHCPReservationsEditView> createState() =>
      _DHCPReservationsEditViewState();
}

class _DHCPReservationsEditViewState
    extends ConsumerState<DHCPReservationsEditView> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _macController = TextEditingController();
  late final String _viewType;
  late final DHCPReservation _item;
  bool enableSave = false;
  bool isMacValid = false;
  bool isIpValid = false;
  bool isMacFocused = false;
  bool isIpFocused = false;
  final InputValidator _macValidator = InputValidator([MACAddressRule()]);
  late final InputValidator _localIpValidator;
  late final String _routerIp;
  late final String _subnetMask;

  @override
  void initState() {
    super.initState();

    _viewType = widget.args['viewType'] ?? 'add';
    _routerIp = widget.args['routerIp'] ?? '';
    _subnetMask = widget.args['subnetMask'] ?? '';

    _item = widget.args['item'] ??
        const DHCPReservation(
          description: '',
          ipAddress: '',
          macAddress: '',
        );
    _deviceNameController.text = _item.description;
    final ipPrefix = NetworkUtils.getIpPrefix(_routerIp, _subnetMask);
    _ipController.text = _viewType == 'add' ? ipPrefix : _item.ipAddress;
    _macController.text = _item.macAddress;

    _localIpValidator = InputValidator([
      HostValidForGivenRouterIPAddressAndSubnetMaskRule(_routerIp, _subnetMask)
    ]);
    _updateEnableSave();
  }

  @override
  void dispose() {
    super.dispose();

    _deviceNameController.dispose();
    _ipController.dispose();
    _macController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subnetToken = _subnetMask.split('.');
    return StyledAppPageView(
      scrollable: true,
      title: viewTitle(_viewType),
      bottomBar: bottomBar(_viewType),
      child: AppBasicLayout(
        content: Column(
          children: [
            AppTextField(
              headerText: loc(context).deviceName,
              controller: _deviceNameController,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                setState(() {
                  enableSave = _updateEnableSave();
                });
              },
            ),
            const AppGap.large3(),
            AppIPFormField(
              header: AppText.bodySmall(loc(context).assignIpAddress),
              semanticLabel: 'assign ip address',
              controller: _ipController,
              errorText: (isIpValid | !isIpFocused)
                  ? null
                  : loc(context).invalidIpAddress,
              border: const OutlineInputBorder(),
              octet1ReadOnly: subnetToken[0] == '255',
              octet2ReadOnly: subnetToken[1] == '255',
              octet3ReadOnly: subnetToken[2] == '255',
              octet4ReadOnly: subnetToken[3] == '255',
              onChanged: (value) {
                setState(() {
                  enableSave = _updateEnableSave();
                });
              },
              onFocusChanged: (value) {
                if (value) {
                  setState(() {
                    isIpFocused = value;
                  });
                }
              },
            ),
            const AppGap.large3(),
            AppTextField.macAddress(
              headerText: loc(context).macAddress,
              semanticLabel: 'mac address',
              controller: _macController,
              errorText: (isMacValid | !isMacFocused)
                  ? null
                  : loc(context).invalidMACAddress,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                setState(() {
                  enableSave = _updateEnableSave();
                });
              },
              onFocusChanged: (value) {
                if (value) {
                  setState(() {
                    isMacFocused = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String viewTitle(String viewType) {
    return switch (viewType) {
      'add' => loc(context).addDHCPReservation,
      _ => loc(context).editDHCPReservation,
    };
  }

  PageBottomBar bottomBar(String viewType) {
    return switch (viewType) {
      'add' => PageBottomBar(
          isPositiveEnabled: enableSave,
          onPositiveTap: () {
            final result = DHCPReservation(
              description: _deviceNameController.text,
              ipAddress: _ipController.text,
              macAddress: _macController.text.toUpperCase(),
            );
            context.pop(result);
          },
        ),
      _ => PageBottomBar(
          isPositiveEnabled: enableSave,
          isNegitiveEnabled: true,
          negitiveLable: loc(context).delete,
          onPositiveTap: () {
            final result = DHCPReservation(
              description: _deviceNameController.text,
              ipAddress: _ipController.text,
              macAddress: _macController.text.toUpperCase(),
            );
            context.pop(result);
          },
          onNegitiveTap: () {
            _showDeleteAlert();
          },
        ),
    };
  }

  bool _updateEnableSave() {
    final name = _deviceNameController.text;
    final ip = _ipController.text;
    final mac = _macController.text;
    bool allFilled = name.isNotEmpty && ip.isNotEmpty && mac.isNotEmpty;
    bool edited = name != _item.description ||
        ip != _item.ipAddress ||
        mac != _item.macAddress;
    isMacValid = _macValidator.validate(mac);
    isIpValid = _localIpValidator.validate(ip);
    return allFilled && edited && isMacValid && isIpValid;
  }

  _showDeleteAlert() {
    showSimpleAppDialog(
      context,
      title: loc(context).deleteReservation,
      content: AppText.bodyMedium(loc(context).thisActionCannotBeUndone),
      actions: [
        AppTextButton(
          loc(context).cancel,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            context.pop();
          },
        ),
        AppTextButton(
          loc(context).delete,
          color: Theme.of(context).colorScheme.error,
          onTap: () {
            context.pop();
            _delete();
          },
        ),
      ],
    );
  }

  _delete() {
    const result = DHCPReservation(
      description: '',
      ipAddress: 'DELETE',
      macAddress: '',
    );
    context.pop(result);
  }
}
