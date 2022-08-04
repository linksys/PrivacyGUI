import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';

class LinksysSupportRegionView extends StatelessWidget {
  LinksysSupportRegionView({Key? key}): super(key: key);

  final regions = [
    //TODO: Check the localization
    'United States',
    'Canada',
    'Latin America',
    'Europe',
    'Middle East and Africa',
    'Asia Pacific',
  ];

  @override
  Widget build(BuildContext context) {
    return BasePageView.withCloseButton(
      context,
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).linksys_support_region_title,
        ),
        content: ListView.builder(
          itemCount: regions.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                regions[index],
                style: Theme.of(context).textTheme.headline3?.copyWith(
                  color: Theme.of(context).primaryColor
                ),
              ),
              onTap: () {
                print('Tap region: ${regions[index]}'); //TODO: Go to next page
              },
            );
          },
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}