import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';

class NoIPDNSForm extends StatefulWidget {
  final NoIPDNSProviderUIModel? value;
  final void Function(NoIPDNSProviderUIModel?) onFormChanged;

  const NoIPDNSForm({
    super.key,
    this.value,
    required this.onFormChanged,
  });

  @override
  State<NoIPDNSForm> createState() => _NoIPDNSFormState();
}

class _NoIPDNSFormState extends State<NoIPDNSForm> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _hostnameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController()
      ..text = widget.value?.username ?? '';
    _passwordController = TextEditingController()
      ..text = widget.value?.password ?? '';
    _hostnameController = TextEditingController()
      ..text = widget.value?.hostName ?? '';
  }

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _hostnameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField.outline(
          headerText: loc(context).username,
          controller: _usernameController,
          errorText: _usernameController.text.isEmpty
              ? loc(context).invalidUsername
              : null,
          onChanged: (value) {
            widget.onFormChanged.call(widget.value?.copyWith(username: value));
          },
        ),
        const AppGap.medium(),
        AppTextField.outline(
          headerText: loc(context).password,
          controller: _passwordController,
          errorText: _passwordController.text.isEmpty
              ? loc(context).invalidPassword
              : null,
          onChanged: (value) {
            widget.onFormChanged.call(widget.value?.copyWith(password: value));
          },
        ),
        const AppGap.medium(),
        AppTextField.outline(
          headerText: loc(context).hostName,
          controller: _hostnameController,
          errorText: _hostnameController.text.isEmpty
              ? loc(context).invalidHostname
              : null,
          onChanged: (value) {
            widget.onFormChanged.call(widget.value?.copyWith(hostName: value));
          },
        )
      ],
    );
  }
}
