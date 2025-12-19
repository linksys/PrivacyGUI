import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';

enum DynDDNSSystem {
  dynamic,
  static,
  custom,
  ;

  String resolve(BuildContext context) => switch (this) {
        dynamic => loc(context).systemDynamic,
        static => loc(context).systemStatic,
        custom => loc(context).systemCustom,
      };
}

class DynDNSForm extends ConsumerStatefulWidget {
  final DynDNSProviderUIModel? value;
  final void Function(DynDNSProviderUIModel?) onFormChanged;

  const DynDNSForm({
    super.key,
    this.value,
    required this.onFormChanged,
  });

  @override
  ConsumerState<DynDNSForm> createState() => _DynDNSFormState();
}

class _DynDNSFormState extends ConsumerState<DynDNSForm> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _hostnameController;
  late TextEditingController _mailExchangeController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController()
      ..text = widget.value?.username ?? '';
    _passwordController = TextEditingController()
      ..text = widget.value?.password ?? '';
    _hostnameController = TextEditingController()
      ..text = widget.value?.hostName ?? '';
    _mailExchangeController = TextEditingController()
      ..text = widget.value?.mailExchangeSettings?.hostName ?? '';
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
        ),
        const AppGap.medium(),
        AppDropdownButton<DynDDNSSystem>(
          initial: DynDDNSSystem.values.firstWhereOrNull(
                  (e) => e.name == widget.value?.mode.toLowerCase()) ??
              DynDDNSSystem.dynamic,
          title: loc(context).system,
          items: DynDDNSSystem.values,
          label: (item) => item.resolve(context),
          onChanged: (value) {
            widget.onFormChanged.call(
                widget.value?.copyWith(mode: value.name.capitalizeWords()));
          },
        ),
        const AppGap.medium(),
        AppTextField.outline(
          headerText: loc(context).mailExchangeOptional,
          controller: _mailExchangeController,
          onChanged: (value) {
            final mailExchangeSettings = widget.value?.mailExchangeSettings ??
                const DynDNSMailExchangeUIModel(hostName: '', isBackup: false);
            widget.onFormChanged.call(widget.value?.copyWith(
                isMailExchangeEnabled: value.isNotEmpty,
                mailExchangeSettings: () =>
                    mailExchangeSettings.copyWith(hostName: value)));
          },
        ),
        const AppGap.medium(),
        Opacity(
          opacity: _mailExchangeController.text.isNotEmpty ? 1 : .6,
          child: AbsorbPointer(
            absorbing: _mailExchangeController.text.isNotEmpty ? false : true,
            child: AppSettingCard(
              title: loc(context).backupMX,
              trailing: AppSwitch(
                value: widget.value?.mailExchangeSettings?.isBackup ?? false,
                onChanged: (value) {
                  final mailExchangeSettings =
                      widget.value?.mailExchangeSettings ??
                          const DynDNSMailExchangeUIModel(
                              hostName: '', isBackup: false);
                  widget.onFormChanged.call(widget.value?.copyWith(
                      mailExchangeSettings: () =>
                          mailExchangeSettings.copyWith(isBackup: value)));
                },
              ),
            ),
          ),
        ),
        const AppGap.medium(),
        AppSettingCard(
          title: loc(context).wildcard,
          trailing: AppSwitch(
            value: widget.value?.isWildcardEnabled ?? false,
            onChanged: (value) {
              widget.onFormChanged
                  .call(widget.value?.copyWith(isWildcardEnabled: value));
            },
          ),
        ),
      ],
    );
  }
}
