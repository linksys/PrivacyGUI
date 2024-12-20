import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class MACCloneView extends ArgumentsConsumerStatefulView {
  const MACCloneView({super.key, super.args});

  @override
  ConsumerState<MACCloneView> createState() => _MACCloneViewState();
}

class _MACCloneViewState extends ConsumerState<MACCloneView> {
  final _valueController = TextEditingController();
  final InputValidator _macValidator = InputValidator([MACAddressRule()]);
  bool _isValid = false;
  bool _isEnabled = false;
  late InternetSettingsState state;

  @override
  void initState() {
    state = ref.read(internetSettingsProvider);
    _isEnabled = state.macClone;
    String macAddress = state.macCloneAddress ?? '';
    _valueController.text = macAddress;
    _isValid = _macValidator.validate(macAddress);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    _valueController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: loc(context).macAddressClone,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _isValid &&
            ((_isEnabled != state.macClone) ||
                (_valueController.text != state.macCloneAddress)),
        onPositiveTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          doSomethingWithSpinner(
            context,
            ref
                .read(internetSettingsProvider.notifier)
                .setMacAddressClone(_isEnabled, _valueController.text)
                .then((value) {
              showSuccessSnackBar(context, loc(context).saved);
              setState(() {
                state = ref.read(internetSettingsProvider);
              });
            }).catchError((error) {
              final _error = error as JNAPError;
              final errorMsg = switch (_error.result) {
                'ErrorInvalidMACAddress' => loc(context).invalidMACAddress,
                _ => _error.result,
              };

              showFailedSnackBar(context, errorMsg);
            }, test: (error) => error is JNAPError).onError(
                    (error, stackTrace) {
              showFailedSnackBar(context, loc(context).generalError);
            }),
          );
        },
      ),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.large2, vertical: Spacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSettingCard.noBorder(
              padding: EdgeInsets.zero,
              title: loc(context).macAddressClone,
              trailing: AppSwitch(
                semanticLabel: 'mac address clone',
                value: _isEnabled,
                onChanged: (value) {
                  setState(() {
                    _isEnabled = value;
                  });
                },
              ),
            ),
            if (_isEnabled) ...[
              const Divider(
                thickness: 1,
                height: Spacing.large2 * 2 + 1,
              ),
              AppTextField.macAddress(
                semanticLabel: 'mac address',
                controller: _valueController,
                border: const OutlineInputBorder(),
                onChanged: (value) {
                  setState(() {
                    _isValid = _macValidator.validate(value);
                  });
                },
              ),
              const AppGap.large2(),
              AppTextButton.noPadding(
                loc(context).cloneCurrentClientMac,
                onTap: () {
                  ref
                      .read(internetSettingsProvider.notifier)
                      .getMyMACAddress()
                      .then((value) {
                    _valueController.text = value ?? '';
                    setState(() {
                      _isValid = _macValidator.validate(value ?? '');
                    });
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
