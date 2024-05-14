import 'package:flutter/material.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';

class NoIPDNSForm extends StatefulWidget {
  final NoIPSettings? initialValue;
  final void Function(NoIPSettings?) onFormChanged;

  const NoIPDNSForm({
    super.key,
    this.initialValue,
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
      ..text = widget.initialValue?.username ?? '';
    _passwordController = TextEditingController()
      ..text = widget.initialValue?.password ?? '';
    _hostnameController = TextEditingController()
      ..text = widget.initialValue?.hostName ?? '';
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
        )
      ],
    );
  }
}
