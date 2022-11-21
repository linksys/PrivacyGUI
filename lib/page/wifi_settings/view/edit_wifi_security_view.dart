import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/wifi_setting/_wifi_setting.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:linksys_moab/route/_route.dart';

class EditWifiSecurityView extends ArgumentsStatefulView {
  const EditWifiSecurityView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _EditWifiModeViewState createState() => _EditWifiModeViewState();
}

class _EditWifiModeViewState extends State<EditWifiSecurityView> {
  bool isLoading = false;
  late WifiSettingOption _wifiSettingOption;
  late List<WifiSecurityType> _typeList;
  late WifiSecurityType _selectedType;
  late WifiSecurityType _currentType;

  @override
  initState() {
    super.initState();

    WifiSecurityType currentType =
        context.read<WifiSettingCubit>().state.selectedWifiItem.securityType;
    _selectedType = currentType;
    _currentType = currentType;
    _typeList = WifiSecurityType.allTypes;
    _wifiSettingOption = WifiSettingOption.securityTypeBelow6G;
    if (widget.args.containsKey('wifiSettingOption')) {
      _wifiSettingOption = widget.args['wifiSettingOption'];
    }
    if (_wifiSettingOption == WifiSettingOption.securityType6G) {
      _typeList = [
        WifiSecurityType.wpa3,
        WifiSecurityType.enhancedOpen,
      ];
      currentType = context
          .read<WifiSettingCubit>()
          .state
          .selectedWifiItem
          .security6GType!;
      _selectedType = currentType;
      _currentType = currentType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? FullScreenSpinner(text: getAppLocalizations(context).processing)
        : BlocBuilder<WifiSettingCubit, WifiSettingState>(
            builder: (context, state) => BasePageView(
              child: BasicLayout(
                content: ListView.builder(
                  itemCount: _typeList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _onTypeTapped(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _typeList[index].displayTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline3
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                              ),
                            ),
                            const SizedBox(
                              width: 26,
                            ),
                            Visibility(
                              maintainAnimation: true,
                              maintainState: true,
                              maintainSize: true,
                              visible: _typeList[index] == _selectedType,
                              child: Image.asset(
                                'assets/images/icon_check_black.png',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                footer: PrimaryButton(
                  text: getAppLocalizations(context).save,
                  onPress: _selectedType != _currentType ? _save : null,
                ),
              ),
            ),
          );
  }

  void _onTypeTapped(int index) {
    WifiSecurityType selectedType = _typeList[index];
    if (selectedType == WifiSecurityType.open) {
      showOkCancelAlertDialog(
        context: context,
        title: "This is a risky security type",
        message:
            'Anyone can connect to your network. Are you sure you want to continue?',
        okLabel: getAppLocalizations(context).text_continue,
        cancelLabel: getAppLocalizations(context).cancel,
      ).then((result) {
        if (result == OkCancelResult.ok) {
          setState(() => _selectedType = selectedType);
        }
      });
    } else {
      setState(() => _selectedType = selectedType);
    }
  }

  void _save() {
    final wifiType =
        context.read<WifiSettingCubit>().state.selectedWifiItem.wifiType;
    context
        .read<WifiSettingCubit>()
        .updateSecurityType(_wifiSettingOption, _selectedType, wifiType)
        .then((value) {
      setState(() {
        isLoading = false;
        _currentType = _selectedType;
      });
      NavigationCubit.of(context).pop();
    }).onError((error, stackTrace) {
      setState(() => isLoading = false);
      showOkCancelAlertDialog(
        context: context,
        title: "Saving error",
        message: '',
      );
    });
    setState(() {
      isLoading = true;
    });
  }
}
