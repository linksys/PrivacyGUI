import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/utils.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';

class SimpleModeView extends ConsumerStatefulWidget {
  const SimpleModeView({
    super.key,
    required this.simpleWifiNameController,
    required this.simpleWifiPasswordController,
    required this.simpleSecurityType,
    required this.onSecurityTypeChanged,
  });

  final TextEditingController simpleWifiNameController;
  final TextEditingController simpleWifiPasswordController;
  final WifiSecurityType? simpleSecurityType;
  final Function(WifiSecurityType) onSecurityTypeChanged;

  @override
  ConsumerState<SimpleModeView> createState() => _SimpleModeViewState();
}

class _SimpleModeViewState extends ConsumerState<SimpleModeView> {
  final InputValidator wifiSSIDValidator = InputValidator([
    RequiredRule(),
    NoSurroundWhitespaceRule(),
    LengthRule(min: 1, max: 32),
    WiFiSsidRule(),
  ]);
  final InputValidator wifiPasswordValidator = InputValidator([
    LengthRule(min: 8, max: 64),
    NoSurroundWhitespaceRule(),
    AsciiRule(),
    WiFiPSKRule(),
  ]);

  final _guestPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(wifiListProvider);
    _guestPasswordController.text = state.guestWiFi.password;
  }

  @override
  void dispose() {
    _guestPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiListProvider);
    final firstActiveWifi = state.mainWiFi.firstWhereOrNull((e) => e.isEnabled);
    if (firstActiveWifi == null) {
      return const SizedBox.shrink();
    }

    Set<WifiSecurityType> securityTypeSet =
        state.mainWiFi.first.availableSecurityTypes.toSet();
    for (var e in state.mainWiFi) {
      final availableSecurityTypesSet = e.availableSecurityTypes.toSet();
      securityTypeSet = securityTypeSet.intersection(availableSecurityTypesSet);
    }
    final securityTypeList = securityTypeSet.toList();

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.titleLarge(loc(context).quickSetup),
              const AppGap.medium(),
              AppText.labelMedium(loc(context).wifiName),
              const AppGap.small1(),
              AppTextField(
                controller: widget.simpleWifiNameController,
                border: const OutlineInputBorder(),
              ),
              const AppGap.medium(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelMedium(loc(context).wifiPassword),
                        const AppGap.small1(),
                        AppPasswordField(
                          controller: widget.simpleWifiPasswordController,
                          border: const OutlineInputBorder(),
                        ),
                      ],
                    ),
                  ),
                  const AppGap.medium(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelMedium(loc(context).securityMode),
                        const AppGap.small1(),
                        AppDropdownButton<WifiSecurityType>(
                          initial: widget.simpleSecurityType,
                          items: securityTypeList,
                          label: (e) => getWifiSecurityTypeTitle(context, e),
                          onChanged: (value) {
                            widget.onSecurityTypeChanged(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const AppGap.medium(),
              AppText.bodySmall(loc(context).quickSetupDesc),
            ],
          ),
        ),
        const AppGap.medium(),
        _guestWiFiCard(state.guestWiFi),
      ],
    );
  }

  Widget _guestWiFiCard(GuestWiFiItem state) {
    final isSupportGuestWiFi = serviceHelper.isSupportGuestNetwork();
    return isSupportGuestWiFi
        ? Padding(
            padding: EdgeInsets.only(
              right: 0,
              bottom: Spacing.medium,
            ),
            child: Column(
              children: [
                AppCard(
                    key: ValueKey('WiFiGuestCard'),
                    padding: const EdgeInsets.symmetric(
                        vertical: Spacing.small2, horizontal: Spacing.large2),
                    child: Column(children: [
                      _guestWiFiBandCard(state),
                      if (state.isEnabled) ...[
                        const Divider(),
                        _guestWiFiNameCard(state),
                        const Divider(),
                        _guestWiFiPasswordCard(state),
                      ],
                    ])),
              ],
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _guestWiFiBandCard(GuestWiFiItem state) => AppListCard(
        showBorder: false,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        title: AppText.labelLarge(loc(context).guestNetwork),
        trailing: AppSwitch(
          semanticLabel: 'guest',
          value: state.isEnabled,
          onChanged: (value) {
            ref.read(wifiListProvider.notifier).setWiFiEnabled(value);
          },
        ),
      );
  Widget _guestWiFiNameCard(GuestWiFiItem state) => AppSettingCard.noBorder(
        title: loc(context).guestWiFiName,
        description: state.ssid,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
        onTap: () {
          _showWiFiNameModal(state.ssid, (value) {
            ref.read(wifiListProvider.notifier).setWiFiSSID(value);
          });
        },
      );
  Widget _guestWiFiPasswordCard(GuestWiFiItem state) => AppListCard(
        showBorder: false,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        title: AppText.bodyMedium(loc(context).guestWiFiPassword),
        description: IntrinsicWidth(
            child: Theme(
                data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                        isDense: true, contentPadding: EdgeInsets.zero)),
                child: Semantics(
                  textField: false,
                  explicitChildNodes: true,
                  child: AppPasswordField(
                    semanticLabel: 'guest wifi password',
                    readOnly: true,
                    border: InputBorder.none,
                    controller: _guestPasswordController,
                    suffixIconConstraints: const BoxConstraints(),
                  ),
                ))),
        trailing: const Icon(LinksysIcons.edit),
        onTap: () {
          _showWifiPasswordModal(state.password, (value) {
            ref.read(wifiListProvider.notifier).setWiFiPassword(value);
            _guestPasswordController.text = value;
          });
        },
      );

  _showWiFiNameModal(String initValue, void Function(String) onEdited) async {
    TextEditingController controller = TextEditingController()
      ..text = initValue;
    final result = await showSubmitAppDialog<String>(
      context,
      title: loc(context).wifiName,
      contentBuilder: (context, setState, onSubmit) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _wifiNameInputField(
            controller,
            onChanged: (value) {
              setState(() {
                // Do setState to show error message
              });
            },
            onSubmitted: (_) {
              if (wifiSSIDValidator.validate(controller.text)) {
                context.pop(controller.text);
              }
            },
          ),
        ],
      ),
      event: () async => controller.text,
      checkPositiveEnabled: () => wifiSSIDValidator.validate(controller.text),
    );

    if (result != null) {
      onEdited.call(result);
    }
  }

  Widget _wifiNameInputField(TextEditingController controller,
      {String semanticLabel = '',
      Function(String)? onChanged,
      Function(String)? onSubmitted}) {
    return AppTextField(
      semanticLabel: '$semanticLabel wifi name',
      controller: controller,
      border: const OutlineInputBorder(),
      onChanged: onChanged,
      errorText: () {
        final errorKeys =
            wifiSSIDValidator.validateDetail(controller.text, onlyFailed: true);
        if (errorKeys.isEmpty) {
          return null;
        } else if (errorKeys.keys.first == NoSurroundWhitespaceRule().name) {
          return loc(context).routerPasswordRuleStartEndWithSpace;
        } else if (errorKeys.keys.first == WiFiSsidRule().name ||
            errorKeys.keys.first == RequiredRule().name) {
          return loc(context).theNameMustNotBeEmpty;
        } else if (errorKeys.keys.first == LengthRule().name) {
          return loc(context).wifiSSIDLengthLimit;
        } else {
          return null;
        }
      }(),
      onSubmitted: onSubmitted,
    );
  }

  _showWifiPasswordModal(
      String initValue, void Function(String) onEdited) async {
    TextEditingController controller = TextEditingController()
      ..text = initValue;
    bool isPasswordValid = true;
    bool isLength64 = initValue.length == 64;
    final result = await showSubmitAppDialog<String>(
      context,
      title: loc(context).wifiPassword,
      contentBuilder: (context, setState, onSubmit) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _wifiPasswordInputField(
              controller,
              isLength64: isLength64,
              onChanged: (value) {
                setState(() {
                  isLength64 = value.length == 64;
                });
              },
              onValidationChanged: (isValid) => setState(() {
                isPasswordValid =
                    wifiPasswordValidator.validate(controller.text);
              }),
              onSubmitted: (_) {
                if (wifiPasswordValidator.validate(controller.text)) {
                  context.pop(controller.text);
                }
              },
            ),
          ],
        ),
      ),
      event: () async => controller.text,
      checkPositiveEnabled: () => isPasswordValid,
    );

    if (result != null) {
      onEdited(result);
    }
  }

  Widget _wifiPasswordInputField(TextEditingController controller,
      {String semanticLabel = '',
      bool isLength64 = false,
      Function(String)? onChanged,
      Function(bool)? onValidationChanged,
      Function(String)? onSubmitted}) {
    return AppPasswordField.withValidator(
      semanticLabel: '$semanticLabel wifi password',
      autofocus: true,
      controller: controller,
      border: const OutlineInputBorder(),
      validations: [
        Validation(
          description: loc(context).wifiPasswordLimit,
          validator: ((text) =>
              wifiPasswordValidator.getRuleByIndex(0)?.validate(text) ?? false),
        ),
        Validation(
          description: loc(context).routerPasswordRuleStartEndWithSpace,
          validator: ((text) =>
              wifiPasswordValidator.getRuleByIndex(1)?.validate(text) ?? false),
        ),
        Validation(
          description: loc(context).routerPasswordRuleUnsupportSpecialChar,
          validator: ((text) =>
              wifiPasswordValidator.getRuleByIndex(2)?.validate(text) ?? false),
        ),
        if (isLength64)
          Validation(
            description: loc(context).wifiPasswordRuleHex,
            validator: ((text) =>
                wifiPasswordValidator.getRuleByIndex(3)?.validate(text) ??
                false),
          ),
      ],
      onChanged: onChanged,
      onValidationChanged: onValidationChanged,
      onSubmitted: onSubmitted,
    );
  }
}