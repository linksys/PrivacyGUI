import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

typedef OnMenuItemClick = void Function(int index);

class DashboardSettingsView extends StatefulWidget {
  const DashboardSettingsView({Key? key}) : super(key: key);

  @override
  State<DashboardSettingsView> createState() => _DashboardSettingsViewState();
}

class _DashboardSettingsViewState extends State<DashboardSettingsView> {
  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      scrollable: true,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(),
            const SizedBox(
              height: 32,
            ),
            _section(
              'NETWORK',
              [
                'WiFi',
                'WiFi schedule'
                'Priority',
                'Administration',
                'Smart home',
                'Advanced settings'
              ],
              (index) {logger.d('MenuItem click $index');},
            ),
            const SizedBox(
              height: 32,
            ),
            _section(
              'LINKSYS SECURE',
              [
                'Cyberthreat protection',
                'Content filters',
                'App blocking'
              ],
                  (index) {logger.d('MenuItem click $index');},
            ),
            const SizedBox(
              height: 32,
            ),
            _section(
              'YOU',
              [
                'Account',
                'Notifications',
                'Privacy',
              ],
              (index) {logger.d('MenuItem click $index');},
            ),
            const SizedBox(
              height: 32,
            ),
            SimpleTextButton(text: 'Log out', onPressed: () {}),
            SizedBox(height: 16,),
            Text('Terms of Service', style: Theme.of(context).textTheme.headline4),
            SizedBox(height: 16,),
            Text('Privacy Policy', style: Theme.of(context).textTheme.headline4),
            SizedBox(height: 16,),
            FutureBuilder(
              future: PackageInfo.fromPlatform().then((value) => value.version),
              initialData: '-',
              builder: (context, data) {
                return Text('version ${data.data}', style: Theme.of(context).textTheme.headline4);
              }
            ),

          ],
        ),
      ),
    );
  }

  Widget _title() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Settings',
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(fontSize: 32, fontWeight: FontWeight.w400),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ],
    );
  }

  Widget _section(
      String title, List<String> items, OnMenuItemClick onItemClick) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headline4,),
        const SizedBox(height: 4,),
        ...items.map((e) => InkWell(
          onTap: () => onItemClick(items.indexOf(e)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(e, style: Theme.of(context).textTheme.button,),
          ),
        )),
      ],
    );
  }
}
