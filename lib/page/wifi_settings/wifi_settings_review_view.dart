import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/wifi_settings/wifi_settings_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

class WifiSettingsReviewView extends ArgumentsStatefulView {

  const WifiSettingsReviewView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _WifiSettingsReviewViewState createState() => _WifiSettingsReviewViewState();

}

class _WifiSettingsReviewViewState extends State<WifiSettingsReviewView> {
  late WifiListItem _wifiItem;

  @override
  initState() {
    super.initState();
    if (widget.args!.containsKey('info')) {
      _wifiItem = widget.args!['info'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _wifiItem.wifiType.displayTitle,
                  style: Theme.of(context).textTheme.headline3?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary
                  ),
                ),
                const Spacer(),
                Switch.adaptive(value: _wifiItem.isWifiEnabled, onChanged: (enabled) {
                  setState(() => _wifiItem.isWifiEnabled = enabled);
                  //TODO: How to send data back when tapping the back button
                })
              ],
            ),
            Text(
              'Where most of your devices connect.',
              style: Theme.of(context).textTheme.headline4?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 24),
              child: Text(
                '6 GHz, 5 GHz, 2.4 GHz',  //TODO: Remove the dummy recent bands
                style: Theme.of(context).textTheme.headline4?.copyWith(
                    color: Theme.of(context).colorScheme.surface
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: _wifiItem.wifiType.settingOptions.length,
                itemBuilder: _buildListCell,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCell(BuildContext context, int index) {
    String content;

    final currentOption = _wifiItem.wifiType.settingOptions[index];
    switch (currentOption) {
      case WifiSettingOption.nameAndPassword:
        content = _wifiItem.ssid;
        break;
      case WifiSettingOption.securityType6G:
        content = _wifiItem.securityType.displayTitle;
        break;
      case WifiSettingOption.securityTypeBelow6G:
        content = _wifiItem.securityType.displayTitle;
        break;
      case WifiSettingOption.securityType:
        content = _wifiItem.securityType.displayTitle;
        break;
      case WifiSettingOption.mode:
        content = _wifiItem.mode.displayTitle;
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _onSettingTap(index),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentOption.displayTitle,
                  style: Theme.of(context).textTheme.headline3?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  content,
                  style: Theme.of(context).textTheme.headline4?.copyWith(
                      color: Theme.of(context).colorScheme.surface
                  ),
                ),
              ],
            )
          ),
          const Spacer(),
          Image.asset(
            'assets/images/arrow_point_to_right.png',
            height: 12,
          ),
        ],
      ),
    );
  }

  void _onSettingTap(int index) {
    final currentOption = _wifiItem.wifiType.settingOptions[index];
    switch (currentOption) {
      case WifiSettingOption.nameAndPassword:
        NavigationCubit.of(context).pushAndWait(
          EditWifiNamePasswordPath()..args = {'info': _wifiItem}
        ).then((updatedInfo) {
          setState(() => _wifiItem = updatedInfo);
        });
        break;
      case WifiSettingOption.securityType6G:
      case WifiSettingOption.securityTypeBelow6G:
      case WifiSettingOption.securityType:
        NavigationCubit.of(context).pushAndWait(
          EditWifiSecurityPath()..args = {'info': _wifiItem}
        ).then((updatedInfo) {
          setState(() => _wifiItem = updatedInfo);
        });
        break;
      case WifiSettingOption.mode:
        NavigationCubit.of(context).pushAndWait(
          EditWifiModePath()..args = {'info': _wifiItem}
        ).then((updatedInfo) {
          setState(() => _wifiItem = updatedInfo);
        });
        break;
    }
  }

}
