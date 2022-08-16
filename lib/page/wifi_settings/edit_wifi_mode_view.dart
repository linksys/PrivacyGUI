import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/wifi_settings/wifi_settings_view.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

class EditWifiModeView extends ArgumentsStatefulView {
  const EditWifiModeView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _EditWifiModeViewState createState() => _EditWifiModeViewState();

}

class _EditWifiModeViewState extends State<EditWifiModeView> {
  final List<WifiMode> _modeList = WifiMode.allModes;
  late WifiListItem _wifiItem;

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
          itemCount: _modeList.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                setState(() => _wifiItem.mode = _modeList[index]);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _modeList[index].displayTitle,
                          style: Theme.of(context).textTheme.headline3?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          'Communicate to various network adapter standards. If you have a mixed network environment or if you are unsure of your network adapters on your wireless devices, this is the best network mode to choose.',
                          style: Theme.of(context).textTheme.headline4?.copyWith(
                              color: Theme.of(context).colorScheme.surface
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 26,
                  ),
                  Visibility(
                    maintainAnimation: true,
                    maintainState: true,
                    maintainSize: true,
                    visible: _modeList[index] == _wifiItem.mode,
                    child: Image.asset(
                      'assets/images/icon_check_black.png',
                    ),
                  ),
                ],
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