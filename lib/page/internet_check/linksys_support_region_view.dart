import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class LinksysSupportRegionView extends StatelessWidget {
  LinksysSupportRegionView({Key? key}): super(key: key);

  final regions = [
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
        header: const BasicHeader(
          title: 'Select your region',
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