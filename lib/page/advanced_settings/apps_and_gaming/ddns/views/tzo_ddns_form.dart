import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';
import 'package:ui_kit_library/ui_kit.dart';

class TzoDNSForm extends StatefulWidget {
  final TzoDNSProviderUIModel? value;
  final void Function(TzoDNSProviderUIModel?) onFormChanged;

  const TzoDNSForm({
    super.key,
    this.value,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).username),
            AppGap.xs(),
            AppTextField(
              controller: _usernameController,
              errorText: _usernameController.text.isEmpty
                  ? loc(context).invalidUsername
                  : null,
              onChanged: (value) {
                widget.onFormChanged
                    .call(widget.value?.copyWith(username: value));
              },
            ),
          ],
        ),
        AppGap.lg(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).password),
            AppGap.xs(),
            AppTextField(
              controller: _passwordController,
              obscureText: true,
              errorText: _passwordController.text.isEmpty
                  ? loc(context).invalidPassword
                  : null,
              onChanged: (value) {
                widget.onFormChanged
                    .call(widget.value?.copyWith(password: value));
              },
            ),
          ],
        ),
        AppGap.lg(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).hostName),
            AppGap.xs(),
            AppTextField(
              controller: _hostnameController,
              errorText: _hostnameController.text.isEmpty
                  ? loc(context).invalidHostname
                  : null,
              onChanged: (value) {
                widget.onFormChanged
                    .call(widget.value?.copyWith(hostName: value));
              },
            ),
          ],
        )
      ],
    );
  }
}
