import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/wifi_settings/wifi_settings_view.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

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
    if (widget.args!.containsKey('info')) {
      _wifiItem = widget.args!['info'];
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
              onTap: () {
                setState(() => _wifiItem.securityType = _typeList[index]);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _typeList[index].displayTitle,
                        style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary
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