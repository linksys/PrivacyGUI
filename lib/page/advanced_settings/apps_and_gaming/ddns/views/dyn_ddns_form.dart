import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/composed/app_list_card.dart';

import 'package:ui_kit_library/ui_kit.dart';

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
  final DynDNSSettings? value;
  final void Function(DynDNSSettings?) onFormChanged;

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
              obscureText: true, // Assuming password should be obscured
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
        ),
        AppGap.lg(),
        AppDropdown<DynDDNSSystem>(
          value: DynDDNSSystem.values.firstWhereOrNull(
                  (e) => e.name == widget.value?.mode.toLowerCase()) ??
              DynDDNSSystem.dynamic,
          label: loc(context).system,
          items: DynDDNSSystem.values,
          itemAsString: (item) => item.resolve(context),
          onChanged: (value) {
            if (value == null) return;
            widget.onFormChanged.call(
                widget.value?.copyWith(mode: value.name.capitalizeWords()));
          },
        ),
        AppGap.lg(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).mailExchangeOptional),
            AppGap.xs(),
            AppTextField(
              controller: _mailExchangeController,
              onChanged: (value) {
                final mailExchangeSettings =
                    widget.value?.mailExchangeSettings ??
                        const DynDNSMailExchangeSettings(
                            hostName: '', isBackup: false);
                widget.onFormChanged.call(widget.value?.copyWith(
                    isMailExchangeEnabled: value.isNotEmpty,
                    mailExchangeSettings: () =>
                        mailExchangeSettings.copyWith(hostName: value)));
              },
            ),
          ],
        ),
        AppGap.lg(),
        Opacity(
          opacity: _mailExchangeController.text.isNotEmpty ? 1 : .6,
          child: AbsorbPointer(
            absorbing: _mailExchangeController.text.isNotEmpty ? false : true,
            child: AppListCard.setting(
              title: loc(context).backupMX,
              trailing: AppSwitch(
                value: widget.value?.mailExchangeSettings?.isBackup ?? false,
                onChanged: (value) {
                  final mailExchangeSettings =
                      widget.value?.mailExchangeSettings ??
                          const DynDNSMailExchangeSettings(
                              hostName: '', isBackup: false);
                  widget.onFormChanged.call(widget.value?.copyWith(
                      mailExchangeSettings: () =>
                          mailExchangeSettings.copyWith(isBackup: value)));
                },
              ),
            ),
          ),
        ),
        AppGap.lg(),
        AppListCard.setting(
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
