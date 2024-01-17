import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/wifi_setting/_wifi_setting.dart';
import 'package:linksys_app/provider/wifi_setting/wifi_item.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class EditWifiModeView extends ArgumentsConsumerStatefulView {
  const EditWifiModeView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<EditWifiModeView> createState() => _EditWifiModeViewState();
}

class _EditWifiModeViewState extends ConsumerState<EditWifiModeView> {
  //// final List<WifiMode> _modeList = [WifiMode.mixed];
  late WifiItem _wifiItem;

  @override
  initState() {
    super.initState();

    _wifiItem = ref.read(wifiSettingProvider).selectedWifiItem;
  }

  void _save() {
    context.pop(_wifiItem);
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      child: AppBasicLayout(
        content: ListView.builder(
          itemCount: 0,//_modeList.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                // setState(() => _wifiItem.mode = _modeList[index]);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bodyLarge(
                          'XXXXX',//_modeList[index].value,
                        ),
                        const AppGap.small(),
                        const AppText.bodyMedium(
                          'Communicate to various network adapter standards. If you have a mixed network environment or if you are unsure of your network adapters on your wireless devices, this is the best network mode to choose.',
                        ),
                      ],
                    ),
                  ),
                  const AppGap.regular(),
                  Visibility(
                    maintainAnimation: true,
                    maintainState: true,
                    maintainSize: true,
                    visible: false,////_modeList[index] == _wifiItem.mode,
                    child:
                        AppIcon(icon: getCharactersIcons(context).checkDefault),
                  ),
                ],
              ),
            );
          },
        ),
        // footer: AppPrimaryButton(
        //   getAppLocalizations(context).save,
        //   onTap: _save,
        // ),
      ),
    );
  }
}
