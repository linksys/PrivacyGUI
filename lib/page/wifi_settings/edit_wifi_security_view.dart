import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/wifi_settings/wifi_settings_view.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

class EditWifiSecurityView extends ArgumentsStatefulView {
  const EditWifiSecurityView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _EditWifiModeViewState createState() => _EditWifiModeViewState();

}

class _EditWifiModeViewState extends State<EditWifiSecurityView> {
  late WifiListItem _wifiItem;
  final List<WifiSecurityType> _typeList = WifiSecurityType.allTypes;

  @override
  initState() {
    super.initState();
    if (widget.args.containsKey('info')) {
      _wifiItem = widget.args['info'];
    }
  }

  void _onTypeTapped(int index) {
    WifiSecurityType selectedType = _typeList[index];
    if (selectedType == WifiSecurityType.open) {
      showOkCancelAlertDialog(
        context: context,
        title: "This is a risky security type",
        message: 'Anyone can connect to your network. Are you sure you want to continue?',
        okLabel: getAppLocalizations(context).text_continue,
        cancelLabel: getAppLocalizations(context).cancel,
      ).then((result) {
        if (result == OkCancelResult.ok) {
          setState(() => _wifiItem.securityType = selectedType);
        }
      });
    } else {
      setState(() => _wifiItem.securityType = selectedType);
    }
  }

  void _save() {
    NavigationCubit.of(context).popWithResult(_wifiItem);
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
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
                        style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: Theme.of(context).colorScheme.primary
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 26,
                    ),
                    Visibility(
                      maintainAnimation: true,
                      maintainState: true,
                      maintainSize: true,
                      visible: _typeList[index] == _wifiItem.securityType,
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
          onPress: _save,
        ),
      ),
    );
  }

}