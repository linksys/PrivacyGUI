import 'package:flutter/material.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_menu.dart';

enum DynDDNSSystem {
  dynamic,
  static,
  custom,
  ;
}

class DynDNSForm extends StatefulWidget {
  final DynDNSSettings? initialValue;
  final void Function(DynDNSSettings?) onFormChanged;

  const DynDNSForm({
    super.key,
    this.initialValue,
    required this.onFormChanged,
  });

  @override
  State<DynDNSForm> createState() => _DynDNSFormState();
}

class _DynDNSFormState extends State<DynDNSForm> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _hostnameController;
  late TextEditingController _mailExchangeController;
  bool _isBackup = false;
  bool _wildcard = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController()
      ..text = widget.initialValue?.username ?? '';
    _passwordController = TextEditingController()
      ..text = widget.initialValue?.password ?? '';
    _hostnameController = TextEditingController()
      ..text = widget.initialValue?.hostName ?? '';
    _mailExchangeController = TextEditingController()
      ..text = widget.initialValue?.mailExchangeSettings?.hostName ?? '';
    _isBackup = widget.initialValue?.mailExchangeSettings?.isBackup ?? false;
    _wildcard = widget.initialValue?.isWildcardEnabled ?? false;
  }

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _hostnameController.dispose();
    _mailExchangeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          headerText: 'User Name',
          controller: _usernameController,
          onChanged: (value) {
            widget.onFormChanged
                .call(widget.initialValue?.copyWith(username: value));
          },
        ),
        AppTextField(
          headerText: 'No-IP Password',
          controller: _passwordController,
          onChanged: (value) {
            widget.onFormChanged
                .call(widget.initialValue?.copyWith(password: value));
          },
        ),
        AppTextField(
          headerText: 'Host name',
          controller: _hostnameController,
          onChanged: (value) {
            widget.onFormChanged
                .call(widget.initialValue?.copyWith(hostName: value));
          },
        ),
        const AppGap.medium(),
        Row(
          children: [
            AppText.labelMedium('System:'),
            const AppGap.large3(),
            AppDropdownMenu(
              items: DynDDNSSystem.values,
              label: (item) => item.name.capitalizeWords(),
              onChanged: (value) {
                widget.onFormChanged.call(widget.initialValue
                    ?.copyWith(mode: value.name.capitalizeWords()));
              },
            ),
          ],
        ),
        AppTextField(
          headerText: 'Mail exchange',
          hintText: '(Optional)',
          controller: _mailExchangeController,
          onChanged: (value) {
            final mailExchangeSettings = widget
                    .initialValue?.mailExchangeSettings ??
                const DynDNSMailExchangeSettings(hostName: '', isBackup: false);
            widget.onFormChanged.call(widget.initialValue?.copyWith(
                mailExchangeSettings:
                    mailExchangeSettings.copyWith(hostName: value)));
          },
        ),
        Row(
          children: [
            AppText.labelMedium('Backup MX:'),
            const AppGap.large3(),
            AppCheckbox(
              value: _isBackup,
              text: 'Enabled',
              onChanged: (value) {
                setState(() {
                  _isBackup = value ?? false;
                });
                final mailExchangeSettings =
                    widget.initialValue?.mailExchangeSettings ??
                        const DynDNSMailExchangeSettings(
                            hostName: '', isBackup: false);
                widget.onFormChanged.call(widget.initialValue?.copyWith(
                    mailExchangeSettings:
                        mailExchangeSettings.copyWith(isBackup: value)));
              },
            ),
          ],
        ),
        Row(
          children: [
            AppText.labelMedium('Wildcard:'),
            const AppGap.large3(),
            AppCheckbox(
              value: _wildcard,
              text: 'Enabled',
              onChanged: (value) {
                setState(() {
                  _wildcard = value ?? false;
                });
                widget.onFormChanged.call(
                    widget.initialValue?.copyWith(isWildcardEnabled: value));
              },
            ),
          ],
        ),
      ],
    );
  }
}
