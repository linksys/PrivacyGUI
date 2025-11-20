import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/utils/internet_settings_form_validator.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/base_wan_form.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import './connection_mode_form.dart';

class L2tpForm extends BaseWanForm {
  const L2tpForm({
    Key? key,
    required super.isEditing,
  }) : super(key: key);

  @override
  ConsumerState<L2tpForm> createState() => _L2tpFormState();
}

class _L2tpFormState extends BaseWanFormState<L2tpForm> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _serverIpController;

  bool _usernameTouched = false;
  bool _passwordTouched = false;
  bool _serverIpTouched = false;

  final _validator = InternetSettingsFormValidator();
  static const inputPadding = EdgeInsets.symmetric(vertical: Spacing.small2);

  @override
  void initState() {
    super.initState();
    final ipv4Setting = ref.read(internetSettingsProvider).settings.current.ipv4Setting;
    _usernameController = TextEditingController(text: ipv4Setting.username ?? '');
    _passwordController = TextEditingController(text: ipv4Setting.password ?? '');
    _serverIpController = TextEditingController(text: ipv4Setting.serverIp ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverIpController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(L2tpForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIpv4Setting = ref.read(internetSettingsProvider).settings.original.ipv4Setting;
    final newIpv4Setting = ref.read(internetSettingsProvider).settings.current.ipv4Setting;

    if (oldIpv4Setting.username != newIpv4Setting.username) {
      _usernameController.text = newIpv4Setting.username ?? '';
    }
    if (oldIpv4Setting.password != newIpv4Setting.password) {
      _passwordController.text = newIpv4Setting.password ?? '';
    }
    if (oldIpv4Setting.serverIp != newIpv4Setting.serverIp) {
      _serverIpController.text = newIpv4Setting.serverIp ?? '';
    }
  }

  @override
  Widget buildDisplayFields(BuildContext context) {
    final ipv4Setting = ref.watch(internetSettingsProvider).settings.current.ipv4Setting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildInfoCard(
          loc(context).username,
          ipv4Setting.username ?? '-',
        ),
        buildInfoCard(
          loc(context).serverIpv4Address,
          ipv4Setting.serverIp ?? '-',
        ),
        buildInfoCard(
          '${loc(context).vlanIdOptional} (${loc(context).optional})',
          (ipv4Setting.wanTaggingSettingsEnable ?? false)
              ? ipv4Setting.vlanId?.toString() ?? '-'
              : '-',
        ),
      ],
    );
  }

  @override
  Widget buildEditableFields(BuildContext context) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    final ipv4Setting = ref.watch(internetSettingsProvider).settings.current.ipv4Setting;
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
              errorText: _usernameTouched && (ipv4Setting.username?.isEmpty ?? true) ? loc(context).invalidUsername : null,
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
              errorText: _passwordTouched && (ipv4Setting.password?.isEmpty ?? true) ? loc(context).invalidPassword : null,
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
              if (!hasFocus) setState(() => _serverIpTouched = true);
            },
            child: buildIpFormField(
              key: const ValueKey('serverIp'),
              semanticLabel: 'server ip address',
              header: loc(context).serverIpv4Address,
              controller: _serverIpController,
              errorText: _serverIpTouched ? getLocalizedErrorText(context, _validator.validateIpAddress(ipv4Setting.serverIp)) : null,
              onChanged: (value) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  serverIp: () => value,
                ));
              },
            ),
          ),
        ),
        if ((ipv4Setting.wanTaggingSettingsEnable ?? false) && ipv4Setting.vlanId != null)
          buildInfoCard(
            '${loc(context).vlanIdOptional} (${loc(context).optional})',
            ipv4Setting.vlanId?.toString() ?? '-',
          ),
        const Divider(),
        const ConnectionModeForm(),
      ],
    );
  }
}
