import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/utils.dart';

class WebUiAccessView extends ArgumentsStatefulView {
  const WebUiAccessView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<WebUiAccessView> createState() => _WebUiAccessViewState();
}

class _WebUiAccessViewState extends State<WebUiAccessView> {
  bool webUiAccess = false;

  @override
  void initState() {
    super.initState();

    // TODO: Get from cubit
    webUiAccess = false;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // iconTheme:
        // IconThemeData(color: Theme.of(context).colorScheme.primary),
        elevation: 0,
        title: Text(
          getAppLocalizations(context).web_ui_access,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          SimpleTextButton(
            text: getAppLocalizations(context).save,
            onPressed: () {},
          ),
        ],
      ),
      child: BasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box24(),
            SettingTile(
              title: Text(
                getAppLocalizations(context).automatic_firmware_update,
                style: const TextStyle(fontSize: 15),
              ),
              value: CupertinoSwitch(
                value: webUiAccess,
                onChanged: (value) {
                  // TODO: Update status
                  setState(() {
                    webUiAccess = value;
                  });
                },
              ),
            ),
            box16(),
            SizedBox(
              width: Utils.getScreenWidth(context) * 0.7,
              child: Text(
                webUiAccess
                    ? getAppLocalizations(context).web_ui_access_on_description
                    : getAppLocalizations(context)
                        .web_ui_access_off_description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color.fromRGBO(102, 102, 102, 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
