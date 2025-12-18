import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/base_wan_form.dart';
import 'package:ui_kit_library/ui_kit.dart';

import './connection_mode_form.dart';

class PppoeForm extends BaseWanForm {
  const PppoeForm({
    Key? key,
    required super.isEditing,
  }) : super(key: key);

  @override
  ConsumerState<PppoeForm> createState() => _PppoeFormState();
}

class _PppoeFormState extends BaseWanFormState<PppoeForm> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _vlanIdController;
  late final TextEditingController _serviceNameController;

  bool _usernameTouched = false;
  bool _passwordTouched = false;

  static const inputPadding = EdgeInsets.symmetric(vertical: 8);

  @override
  void initState() {
    super.initState();
    final ipv4Setting = ref.read(internetSettingsProvider).current.ipv4Setting;
    _usernameController =
        TextEditingController(text: ipv4Setting.username ?? '');
    _passwordController =
        TextEditingController(text: ipv4Setting.password ?? '');
    _vlanIdController = TextEditingController(
        text: ipv4Setting.vlanId != null ? '${ipv4Setting.vlanId}' : '');
    _serviceNameController =
        TextEditingController(text: ipv4Setting.serviceName ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _vlanIdController.dispose();
    _serviceNameController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PppoeForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIpv4Setting =
        ref.read(internetSettingsProvider).settings.original.ipv4Setting;
    final newIpv4Setting =
        ref.read(internetSettingsProvider).settings.current.ipv4Setting;

    if (oldIpv4Setting.username != newIpv4Setting.username) {
      _usernameController.text = newIpv4Setting.username ?? '';
    }
    if (oldIpv4Setting.password != newIpv4Setting.password) {
      _passwordController.text = newIpv4Setting.password ?? '';
    }
    if (oldIpv4Setting.vlanId != newIpv4Setting.vlanId) {
      _vlanIdController.text =
          newIpv4Setting.vlanId != null ? '${newIpv4Setting.vlanId}' : '';
    }
    if (oldIpv4Setting.serviceName != newIpv4Setting.serviceName) {
      _serviceNameController.text = newIpv4Setting.serviceName ?? '';
    }
  }

  @override
  Widget buildDisplayFields(BuildContext context) {
    final ipv4Setting =
        ref.watch(internetSettingsProvider).settings.current.ipv4Setting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildInfoCard(
          loc(context).username,
          ipv4Setting.username ?? '-',
        ),
        buildInfoCard(
          loc(context).vlanIdOptional,
          (ipv4Setting.wanTaggingSettingsEnable ?? false)
              ? ipv4Setting.vlanId?.toString() ?? '-'
              : '-',
        ),
        buildInfoCard(
          loc(context).serviceNameOptional,
          ipv4Setting.serviceName ?? '-',
        ),
      ],
    );
  }

  @override
  Widget buildEditableFields(BuildContext context) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    final ipv4Setting =
        ref.watch(internetSettingsProvider).settings.current.ipv4Setting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) setState(() => _usernameTouched = true);
            },
            child: buildEditableField(
              label: loc(context).username,
              controller: _usernameController,
              errorText:
                  _usernameTouched && (ipv4Setting.username?.isEmpty ?? true)
                      ? loc(context).invalidUsername
                      : null,
              onChanged: (value) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  username: () => value,
                ));
              },
            ),
          ),
        ),
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) setState(() => _passwordTouched = true);
            },
            child: buildEditableField(
              label: loc(context).password,
              controller: _passwordController,
              obscureText: true,
              errorText:
                  _passwordTouched && (ipv4Setting.password?.isEmpty ?? true)
                      ? loc(context).invalidPassword
                      : null,
              onChanged: (value) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  password: () => value,
                ));
              },
            ),
          ),
        ),
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                final value = _vlanIdController.text;
                if (value.isNotEmpty && int.parse(value) < 5) {
                  _vlanIdController.text = '5';
                  notifier.updateIpv4Settings(ipv4Setting.copyWith(
                    vlanId: () => 5,
                  ));
                }
              }
            },
            child: AppMinMaxInput(
              min: 5,
              max: 4094,
              label: loc(context).vlanIdOptional,
              value: int.tryParse(_vlanIdController.text),
              onChanged: (value) {
                _vlanIdController.text = value?.toString() ?? '';
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  vlanId: () => value,
                ));
              },
            ),
          ),
        ),
        Padding(
          padding: inputPadding,
          child: buildEditableField(
            label: loc(context).serviceNameOptional,
            controller: _serviceNameController,
            onChanged: (value) {
              notifier.updateIpv4Settings(ipv4Setting.copyWith(
                serviceName: () => value,
              ));
            },
          ),
        ),
        AppGap.xs(),
        const Divider(),
        const ConnectionModeForm(),
      ],
    );
  }
}
