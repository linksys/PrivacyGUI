import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:linksys_app/provider/wifi_setting/_wifi_setting.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class EditWifiSecurityView extends ArgumentsConsumerStatefulView {
  const EditWifiSecurityView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<EditWifiSecurityView> createState() =>
      _EditWifiSecurityViewState();
}

class _EditWifiSecurityViewState extends ConsumerState<EditWifiSecurityView> {
  bool isLoading = false;
  late WifiSettingOption _wifiSettingOption;
  late List<WifiSecurityType> _typeList;
  late WifiSecurityType _selectedType;
  late WifiSecurityType _currentType;

  @override
  initState() {
    super.initState();

    WifiSecurityType currentType = ref
        .read(wifiSettingProvider.notifier)
        .state
        .selectedWifiItem
        .securityType;
    _selectedType = currentType;
    _currentType = currentType;
    _typeList = WifiSecurityType.allTypes;
    _wifiSettingOption = WifiSettingOption.securityTypeBelow6G;
    if (widget.args.containsKey('wifiSettingOption')) {
      _wifiSettingOption = WifiSettingOption.values.firstWhereOrNull(
              (element) => element.name == widget.args['wifiSettingOption']) ??
          WifiSettingOption.securityType;
    }
    if (_wifiSettingOption == WifiSettingOption.securityType6G) {
      _typeList = [
        WifiSecurityType.wpa3,
        WifiSecurityType.enhancedOpen,
      ];
      currentType = ref
          .read(wifiSettingProvider.notifier)
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
        ? AppFullScreenSpinner(text: getAppLocalizations(context).processing)
        : StyledAppPageView(
            child: AppBasicLayout(
              content: ListView.builder(
                itemCount: _typeList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _onTypeTapped(index),
                    child: AppPadding(
                      padding: const AppEdgeInsets.symmetric(
                          vertical: AppGapSize.regular),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText.headlineSmall(
                              _typeList[index].displayTitle,
                            ),
                          ),
                          const AppGap.regular(),
                          Visibility(
                            maintainAnimation: true,
                            maintainState: true,
                            maintainSize: true,
                            visible: _typeList[index] == _selectedType,
                            child: AppIcon(
                              icon: getCharactersIcons(context).checkDefault,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              footer: AppPrimaryButton(
                getAppLocalizations(context).save,
                onTap: _selectedType != _currentType ? _save : null,
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
    final wifiType = ref.read(wifiSettingProvider).selectedWifiItem.wifiType;
    ref
        .read(wifiSettingProvider.notifier)
        .updateSecurityType(_wifiSettingOption, _selectedType, wifiType)
        .then((value) {
      setState(() {
        isLoading = false;
        _currentType = _selectedType;
      });
      context.pop();
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
