import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/utils/internet_settings_form_validator.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/ipv6/base_ipv6_wan_form.dart';
import 'package:privacy_gui/page/components/composed/app_setting_card.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/components/composed/app_dropdown_button.dart';
import 'package:privacy_gui/page/components/composed/app_min_max_number_text_field.dart';

class AutomaticIPv6Form extends BaseIPv6WanForm {
  const AutomaticIPv6Form({
    Key? key,
    required super.isEditing,
  }) : super(key: key);

  @override
  ConsumerState<AutomaticIPv6Form> createState() => _AutomaticIPv6FormState();
}

class _AutomaticIPv6FormState extends BaseIPv6WanFormState<AutomaticIPv6Form> {
  late final TextEditingController _ipv6PrefixController;
  late final TextEditingController _ipv6PrefixLengthController;
  late final TextEditingController _ipv6BorderRelayController;
  late final TextEditingController _ipv6BorderRelayPrefixLengthController;

  bool _prefixTouched = false;
  bool _borderRelayTouched = false;

  final _validator = InternetSettingsFormValidator();

  static const inputPadding = EdgeInsets.symmetric(vertical: 8);

  @override
  void initState() {
    super.initState();
    final ipv6Setting = ref.read(internetSettingsProvider).current.ipv6Setting;
    _ipv6PrefixController =
        TextEditingController(text: ipv6Setting.ipv6Prefix ?? '');
    _ipv6PrefixLengthController = TextEditingController(
        text: ipv6Setting.ipv6PrefixLength?.toString() ?? '');
    _ipv6BorderRelayController =
        TextEditingController(text: ipv6Setting.ipv6BorderRelay ?? '');
    _ipv6BorderRelayPrefixLengthController = TextEditingController(
        text: ipv6Setting.ipv6BorderRelayPrefixLength?.toString() ?? '');
  }

  @override
  void dispose() {
    _ipv6PrefixController.dispose();
    _ipv6PrefixLengthController.dispose();
    _ipv6BorderRelayController.dispose();
    _ipv6BorderRelayPrefixLengthController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AutomaticIPv6Form oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIpv6Setting =
        ref.read(internetSettingsProvider).settings.original.ipv6Setting;
    final newIpv6Setting =
        ref.read(internetSettingsProvider).settings.current.ipv6Setting;

    if (oldIpv6Setting.ipv6Prefix != newIpv6Setting.ipv6Prefix) {
      _ipv6PrefixController.text = newIpv6Setting.ipv6Prefix ?? '';
    }
    if (oldIpv6Setting.ipv6PrefixLength != newIpv6Setting.ipv6PrefixLength) {
      _ipv6PrefixLengthController.text =
          newIpv6Setting.ipv6PrefixLength?.toString() ?? '';
    }
    if (oldIpv6Setting.ipv6BorderRelay != newIpv6Setting.ipv6BorderRelay) {
      _ipv6BorderRelayController.text = newIpv6Setting.ipv6BorderRelay ?? '';
    }
    if (oldIpv6Setting.ipv6BorderRelayPrefixLength !=
        newIpv6Setting.ipv6BorderRelayPrefixLength) {
      _ipv6BorderRelayPrefixLengthController.text =
          newIpv6Setting.ipv6BorderRelayPrefixLength?.toString() ?? '';
    }
  }

  @override
  Widget buildDisplayFields(BuildContext context) {
    final state = ref.watch(internetSettingsProvider);
    final ipv6Setting = state.settings.current.ipv6Setting;
    return Column(
      children: [
        buildInfoCard(
          loc(context).ipv6Automatic,
          ipv6Setting.isIPv6AutomaticEnabled
              ? loc(context).enabled
              : loc(context).disabled,
        ),
        if (state.status.duid.isNotEmpty)
          buildInfoCard(
            loc(context).duid,
            state.status.duid,
          ),
        _divider(),
        _sixrdTunnel(ipv6Setting, context),
      ],
    );
  }

  @override
  Widget buildEditableFields(BuildContext context) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    final state = ref.watch(internetSettingsProvider);
    final ipv6Setting = state.settings.current.ipv6Setting;
    return Column(
      children: [
        AppGap.md(),
        AppCard(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            children: [
              AppCheckbox(
                value: ipv6Setting.isIPv6AutomaticEnabled,
                onChanged: (value) {
                  if (value == true) {
                    notifier.updateIpv6Settings(Ipv6Setting(
                      ipv6ConnectionType: ipv6Setting.ipv6ConnectionType,
                      isIPv6AutomaticEnabled: true,
                    ));
                  } else {
                    notifier.updateIpv6Settings(ipv6Setting.copyWith(
                        isIPv6AutomaticEnabled: value,
                        ipv6rdTunnelMode: () =>
                            ipv6Setting.ipv6rdTunnelMode ??
                            IPv6rdTunnelMode.disabled));
                  }
                },
              ),
              AppGap.lg(),
              AppText.bodyLarge(loc(context).ipv6Automatic),
            ],
          ),
        ),
        AppSettingCard.noBorder(
          title: loc(context).duid,
          description: state.status.duid,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
        AppGap.xs(),
        _divider(),
        _sixrdTunnel(ipv6Setting, context),
      ],
    );
  }

  Widget _sixrdTunnel(Ipv6Setting ipv6Setting, BuildContext context) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: inputPadding,
            child: AppDropdownButton<IPv6rdTunnelMode>(
              key: const ValueKey('ipv6TunnelDropdown'),
              title: loc(context).sixrdTunnel,
              selected:
                  ipv6Setting.ipv6rdTunnelMode ?? IPv6rdTunnelMode.disabled,
              items: const [
                IPv6rdTunnelMode.disabled,
                IPv6rdTunnelMode.automatic,
                IPv6rdTunnelMode.manual,
              ],
              label: (item) {
                return getIpv6rdTunnelModeLoc(context, item);
              },
              onChanged: widget.isEditing && !ipv6Setting.isIPv6AutomaticEnabled
                  ? (value) {
                      notifier.updateIpv6Settings(
                          ipv6Setting.copyWith(ipv6rdTunnelMode: () => value));
                    }
                  : null,
            ),
          ),
          _manualSixrdTunnel(ipv6Setting, context),
        ],
      ),
    );
  }

  Widget _manualSixrdTunnel(Ipv6Setting ipv6Setting, BuildContext context) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    final isEnable = !ipv6Setting.isIPv6AutomaticEnabled &&
        ipv6Setting.ipv6rdTunnelMode == IPv6rdTunnelMode.manual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
            padding: inputPadding,
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) setState(() => _prefixTouched = true);
              },
              child: buildEditableField(
                label: loc(context).prefix,
                controller: _ipv6PrefixController,
                enable: isEnable,
                errorText: _prefixTouched
                    ? getLocalizedErrorText(context,
                        _validator.validateIpv6Prefix(ipv6Setting.ipv6Prefix))
                    : null,
                onChanged: (value) {
                  notifier.updateIpv6Settings(
                      ipv6Setting.copyWith(ipv6Prefix: () => value));
                },
              ),
            )),
        Padding(
          padding: inputPadding,
          child: AppMinMaxNumberTextField(
            label: loc(context).prefixLength,
            max: 64,
            controller: _ipv6PrefixLengthController,
            enable: isEnable,
            onChanged: (value) {
              notifier.updateIpv6Settings(ipv6Setting.copyWith(
                  ipv6PrefixLength: () => int.parse(value)));
            },
          ),
        ),
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) setState(() => _borderRelayTouched = true);
            },
            child: buildIpFormField(
              semanticLabel: 'border relay',
              header: loc(context).borderRelay,
              controller: _ipv6BorderRelayController,
              enable: isEnable,
              errorText: _borderRelayTouched
                  ? getLocalizedErrorText(
                      context,
                      _validator
                          .validateBorderRelay(ipv6Setting.ipv6BorderRelay))
                  : null,
              onChanged: (value) {
                notifier.updateIpv6Settings(
                    ipv6Setting.copyWith(ipv6BorderRelay: () => value));
              },
            ),
          ),
        ),
        Padding(
          padding: inputPadding,
          child: AppMinMaxNumberTextField(
            key: const Key('borderRelayLength'),
            label: loc(context).borderRelayLength,
            max: 32,
            controller: _ipv6BorderRelayPrefixLengthController,
            enable: isEnable,
            onChanged: (value) {
              notifier.updateIpv6Settings(ipv6Setting.copyWith(
                  ipv6BorderRelayPrefixLength: () => int.parse(value)));
            },
          ),
        ),
      ],
    );
  }

  String getIpv6rdTunnelModeLoc(
      BuildContext context, IPv6rdTunnelMode ipv6rdTunnelMode) {
    return switch (ipv6rdTunnelMode) {
      IPv6rdTunnelMode.automatic => loc(context).automatic,
      IPv6rdTunnelMode.disabled => loc(context).disabled,
      IPv6rdTunnelMode.manual => loc(context).manual,
    };
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Divider(),
    );
  }
}
