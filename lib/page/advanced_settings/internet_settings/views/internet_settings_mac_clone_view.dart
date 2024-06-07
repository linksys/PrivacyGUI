import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

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
  bool _isLoading = false;
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
    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            title: loc(context).macAddressClone,
            bottomBar: PageBottomBar(
              isPositiveEnabled: _isValid &&
                  ((_isEnabled != state.macClone) ||
                      (_valueController.text != state.macCloneAddress)),
              onPositiveTap: () async {
                setState(() {
                  _isLoading = true;
                });
                FocusManager.instance.primaryFocus?.unfocus();
                await ref
                    .read(internetSettingsProvider.notifier)
                    .setMacAddressClone(_isEnabled, _valueController.text)
                    .whenComplete(() {
                  setState(() {
                    _isLoading = false;
                  });
                  context.pop();
                });
              },
            ),
            child: AppBasicLayout(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSettingCard.noBorder(
                    title: loc(context).macAddressClone,
                    color: Theme.of(context).colorScheme.background,
                    trailing: AppSwitch(
                      value: _isEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isEnabled = value;
                        });
                      },
                    ),
                  ),
                  if (_isEnabled)
                    AppTextField.macAddress(
                      controller: _valueController,
                      border: const OutlineInputBorder(),
                      onChanged: (value) {
                        setState(() {
                          _isValid = _macValidator.validate(value);
                        });
                      },
                    ),
                  const AppGap.big(),
                  if (_isEnabled)
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
              ),
            ),
          );
  }
}
