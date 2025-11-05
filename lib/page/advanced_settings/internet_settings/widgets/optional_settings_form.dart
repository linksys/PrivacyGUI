import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/utils/internet_settings_form_validator.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/utils/validation_error.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class OptionalSettingsForm extends ConsumerStatefulWidget {
  final bool isEditing;
  final bool isBridgeMode;

  const OptionalSettingsForm({
    Key? key,
    required this.isEditing,
    required this.isBridgeMode,
  }) : super(key: key);

  @override
  ConsumerState<OptionalSettingsForm> createState() =>
      _OptionalSettingsFormState();
}

class _OptionalSettingsFormState extends ConsumerState<OptionalSettingsForm> {
  late final TextEditingController _domainNameController;
  late final TextEditingController _mtuSizeController;
  late final TextEditingController _macAddressCloneController;

  bool _macAddressTouched = false;
  bool _mtuSizeTouched = false;

  bool isMtuAuto = true;
  final _validator = InternetSettingsFormValidator();

  @override
  void initState() {
    super.initState();
    final state = ref.read(internetSettingsProvider);
    _domainNameController = TextEditingController(
        text: state.settings.current.ipv4Setting.domainName ?? '');
    _mtuSizeController = TextEditingController(
        text: '${state.settings.current.ipv4Setting.mtu}');
    _macAddressCloneController = TextEditingController(
        text: state.settings.current.macCloneAddress ?? '');
    isMtuAuto = state.settings.current.ipv4Setting.mtu == 0;
  }

  @override
  void dispose() {
    _domainNameController.dispose();
    _mtuSizeController.dispose();
    _macAddressCloneController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OptionalSettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldState = ref.read(internetSettingsProvider).settings.original;
    final newState = ref.read(internetSettingsProvider).settings.current;

    if (oldState.ipv4Setting.domainName != newState.ipv4Setting.domainName) {
      _domainNameController.text = newState.ipv4Setting.domainName ?? '';
    }
    if (oldState.ipv4Setting.mtu != newState.ipv4Setting.mtu) {
      _mtuSizeController.text = '${newState.ipv4Setting.mtu}';
      isMtuAuto = newState.ipv4Setting.mtu == 0;
    }
    if (oldState.macCloneAddress != newState.macCloneAddress) {
      _macAddressCloneController.text = newState.macCloneAddress ?? '';
    }
  }

  String? getLocalizedErrorText(BuildContext context, ValidationError? error) {
    if (error == null) return null;
    switch (error) {
      case ValidationError.fieldCannotBeEmpty:
        return loc(context).invalidInput;
      case ValidationError.invalidIpAddress:
        return loc(context).invalidIpAddress;
      case ValidationError.invalidMACAddress:
        return loc(context).invalidMACAddress;
      case ValidationError.invalidSubnetMask:
        return loc(context).invalidSubnetMask;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(internetSettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.titleMedium(loc(context).optional),
        const AppGap.medium(),
        _optionalCard(state.settings.current.ipv4Setting),
        const AppGap.medium(),
        _macAddressCloneCard(state.settings.current),
      ],
    );
  }

  Widget _optionalCard(Ipv4Setting ipv4Setting) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.small1,
        horizontal: Spacing.large2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _domainName(ipv4Setting),
          _divider(),
          _mtu(ipv4Setting),
          _divider(),
          _mtuSize(ipv4Setting),
        ],
      ),
    );
  }

  Widget _domainName(Ipv4Setting ipv4Setting) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    final type = WanType.resolve(ipv4Setting.ipv4ConnectionType);
    final isDomainNameEditable = type == WanType.static;

    return widget.isEditing && isDomainNameEditable
        ? Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: AppTextField(
              headerText: loc(context).domainName,
              hintText: '',
              semanticLabel: 'domain name',
              controller: _domainNameController,
              border: const OutlineInputBorder(),
              onChanged: (value) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  domainName: () => value.isEmpty ? null : value,
                ));
              },
            ),
          )
        : _internetSettingInfoCard(
            title: loc(context).domainName.capitalizeWords(),
            description: ipv4Setting.domainName ?? '-',
          );
  }

  Widget _mtu(Ipv4Setting ipv4Setting) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    return widget.isEditing && !widget.isBridgeMode
        ? Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: AppDropdownButton<String>(
              key: const ValueKey('mtuDropdown'),
              title: loc(context).mtu,
              selected: isMtuAuto ? loc(context).auto : loc(context).manual,
              items: [loc(context).auto, loc(context).manual],
              label: (item) => item,
              onChanged: (value) {
                final maxMtu = _getMaxMtu(ipv4Setting.ipv4ConnectionType);
                setState(() {
                  isMtuAuto = value == loc(context).auto;
                  _mtuSizeController.text = isMtuAuto ? '0' : '$maxMtu';
                });
                notifier.updateMtu(isMtuAuto ? 0 : maxMtu);
              },
            ),
          )
        : _internetSettingInfoCard(
            title: loc(context).mtu,
            description: isMtuAuto ? loc(context).auto : loc(context).manual,
          );
  }

  Widget _mtuSize(Ipv4Setting ipv4Setting) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    return widget.isEditing && !widget.isBridgeMode
        ? Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  setState(() => _mtuSizeTouched = true);
                  if (int.parse(_mtuSizeController.text) < 576) {
                    _mtuSizeController.text = '576';
                    notifier.updateMtu(576);
                  }
                }
              },
              child: AppTextField.minMaxNumber(
                key: const ValueKey('mtuManualSizeText'),
                controller: _mtuSizeController,
                enable: !isMtuAuto,
                border: const OutlineInputBorder(),
                headerText: loc(context).size,
                inputType: TextInputType.number,
                min: 576,
                max: _getMaxMtu(ipv4Setting.ipv4ConnectionType),
                errorText: _mtuSizeTouched &&
                        !isMtuAuto &&
                        int.tryParse(_mtuSizeController.text) == null
                    ? loc(context).invalidInput
                    : null,
                onChanged: (value) {
                  notifier.updateMtu(value.isEmpty ? 0 : int.parse(value));
                },
              ),
            ),
          )
        : isMtuAuto
            ? AppListCard(
                showBorder: false,
                padding: const EdgeInsets.symmetric(
                  vertical: Spacing.small3,
                ),
                title: AppText.bodyMedium(
                  loc(context).size,
                  color: Theme.of(context).colorScheme.outline,
                ),
                description: AppText.labelLarge(
                  '0',
                  color: Theme.of(context).colorScheme.outline,
                ),
              )
            : _internetSettingInfoCard(
                title: loc(context).size,
                description: "${ipv4Setting.mtu}",
              );
  }

  Widget _macAddressCloneCard(InternetSettings settings) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    final state = ref.watch(internetSettingsProvider);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.small1,
        horizontal: Spacing.large2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppText.titleMedium(
                      loc(context).macAddressClone.capitalizeWords()),
                ),
                AppGap.small1(),
                AppSwitch(
                  semanticLabel: 'mac address clone',
                  value: settings.macClone,
                  onChanged: widget.isEditing && !widget.isBridgeMode
                      ? (value) {
                          notifier.updateMacAddressCloneEnable(value);
                          notifier.updateMacAddressClone(value
                              ? state.settings.original.macCloneAddress ?? ''
                              : null);
                          setState(() {
                            _macAddressCloneController.text = value
                                ? state.settings.original.macCloneAddress ?? ''
                                : '';
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
          _divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) setState(() => _macAddressTouched = true);
              },
              child: AppTextField.macAddress(
                semanticLabel: 'mac address',
                controller: _macAddressCloneController,
                border: const OutlineInputBorder(),
                errorText: _macAddressTouched && settings.macClone
                    ? getLocalizedErrorText(context,
                        _validator.validateMacAddress(settings.macCloneAddress))
                    : null,
                enable: widget.isEditing &&
                    settings.macClone &&
                    !widget.isBridgeMode,
                onChanged: (value) {
                  notifier.updateMacAddressClone(value);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.small3,
            ),
            child: AppTextButton.noPadding(
              loc(context).cloneCurrentClientMac,
              icon: LinksysIcons.duplicateControl,
              onTap:
                  widget.isEditing && settings.macClone && !widget.isBridgeMode
                      ? () {
                          notifier.getMyMACAddress().then((value) {
                            notifier.updateMacAddressClone(value);
                            setState(() {
                              _macAddressCloneController.text = value ?? '';
                            });
                          });
                        }
                      : null,
            ),
          ),
          const AppGap.small2(),
        ],
      ),
    );
  }

  Widget _internetSettingInfoCard({
    required String title,
    required String description,
  }) {
    return AppSettingCard.noBorder(
      title: title,
      description: description,
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.small3,
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: Spacing.small3,
      ),
      child: Divider(),
    );
  }

  int _getMaxMtu(String wanType) {
    return NetworkUtils.getMaxMtu(wanType);
  }
}
