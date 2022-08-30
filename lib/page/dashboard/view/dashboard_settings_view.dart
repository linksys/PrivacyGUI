import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

typedef OnMenuItemClick = void Function(int index, DashboardSettingsItem item);

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
              _networkSettingsSection(),
              (index, item) {
                logger.d('MenuItem click $index');
                NavigationCubit.of(context).push(item.path);
              },
            ),
            const SizedBox(
              height: 32,
            ),
            _section(
              _secureSettingsSection(),
              (index, item) {
                logger.d('MenuItem click $index');
                NavigationCubit.of(context).push(item.path);
              },
            ),
            const SizedBox(
              height: 32,
            ),
            _section(
              _youSettingsSection(),
              (index, item) {
                logger.d('MenuItem click $index');
              },
            ),
            const SizedBox(
              height: 32,
            ),
            SimpleTextButton(text: 'Log out', onPressed: () {}),
            SizedBox(
              height: 16,
            ),
            Text('Terms of Service',
                style: Theme.of(context).textTheme.headline4?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            SizedBox(
              height: 16,
            ),
            Text('Privacy Policy',
                style: Theme.of(context).textTheme.headline4?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            SizedBox(
              height: 16,
            ),
            FutureBuilder(
                future:
                    PackageInfo.fromPlatform().then((value) => value.version),
                initialData: '-',
                builder: (context, data) {
                  return Text('version ${data.data}',
                      style: Theme.of(context).textTheme.headline4?.copyWith(
                            fontWeight: FontWeight.w700,
                          ));
                }),
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
      DashboardSettingsSection sectionItem, OnMenuItemClick onItemClick) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionItem.title,
          style: Theme.of(context)
              .textTheme
              .headline4
              ?.copyWith(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        const SizedBox(
          height: 4,
        ),
        ...sectionItem.items.map((e) => InkWell(
              onTap: () => onItemClick(sectionItem.items.indexOf(e), e),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  e.title,
                  style: Theme.of(context).textTheme.button,
                ),
              ),
            )),
      ],
    );
  }
}

_networkSettingsSection() => DashboardSettingsSection(
      title: 'NETWORK',
      items: [
        DashboardSettingsItem(title: 'WiFi', path: WifiSettingsPath()),
        DashboardSettingsItem(title: 'Internet schedule', path: InternetSchedulePath()),
        DashboardSettingsItem(title: 'Priority', path: UnknownPath()),
        DashboardSettingsItem(title: 'Administration', path: UnknownPath()),
        DashboardSettingsItem(title: 'Smart home', path: UnknownPath()),
      ],
    );
//
_secureSettingsSection() => DashboardSettingsSection(
      title: 'LINKSYS SECURE',
      items: [
        DashboardSettingsItem(
            title: 'Cyberthreat protection', path: UnknownPath()),
        DashboardSettingsItem(title: 'Content filters', path: ContentFilteringPath()),
        DashboardSettingsItem(title: 'App blocking', path: UnknownPath()),
      ],
    );
//
_youSettingsSection() => DashboardSettingsSection(
      title: 'YOU',
      items: [
        DashboardSettingsItem(title: 'Account', path: UnknownPath()),
        DashboardSettingsItem(title: 'Notifications', path: UnknownPath()),
        DashboardSettingsItem(title: 'Privacy', path: UnknownPath()),
        DashboardSettingsItem(
            title: '+ Set up new product', path: UnknownPath()),
      ],
    );

class DashboardSettingsSection {
  DashboardSettingsSection({required this.title, required this.items});

  final String title;
  final List<DashboardSettingsItem> items;
}

class DashboardSettingsItem {
  DashboardSettingsItem({required this.title, required this.path});

  final String title;
  final BasePath path;
}
