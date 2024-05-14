import 'package:flutter/material.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';

class TzoDNSForm extends StatefulWidget {
  final TZOSettings? initialValue;
  final void Function(TZOSettings?) onFormChanged;

  const TzoDNSForm({
    super.key,
    this.initialValue,
    required this.onFormChanged,
  });

  @override
  State<TzoDNSForm> createState() => _TzoDNSFormState();
}

class _TzoDNSFormState extends State<TzoDNSForm> {
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
