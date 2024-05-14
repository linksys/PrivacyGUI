import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/widgets/base/gap.dart';
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
  final InputValidator _macValidator = InputValidator([MACAddressRule()]);

  @override
  void initState() {
    super.initState();

    _viewType = widget.args['viewType'] ?? 'add';
    _item = widget.args['item'] ??
        const DHCPReservation(
          description: '',
          ipAddress: '',
          macAddress: '',
        );
    _deviceNameController.text = _item.description;
    _ipController.text = _item.ipAddress;
    _macController.text = _item.macAddress;
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
            const AppGap.big(),
            AppIPFormField(
              header: AppText.bodySmall(loc(context).assignIpAddress),
              controller: _ipController,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                setState(() {
                  enableSave = _updateEnableSave();
                });
              },
            ),
            const AppGap.big(),
            AppTextField.macAddress(
              headerText: loc(context).macAddress,
              controller: _macController,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                setState(() {
                  enableSave = _updateEnableSave();
                });
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
    return allFilled && edited && isMacValid;
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
