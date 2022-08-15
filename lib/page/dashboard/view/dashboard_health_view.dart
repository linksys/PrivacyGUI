import 'dart:math';

import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';


class DashboardHealthView extends StatefulWidget {
  const DashboardHealthView({Key? key}) : super(key: key);

  @override
  State<DashboardHealthView> createState() => _DashboardHealthViewState();
}

class _DashboardHealthViewState extends State<DashboardHealthView> {
  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      scrollable: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          SizedBox(height: 32),
          _basicTiles(),
        ],
      ),
    );
  }

  Widget _header() {
    // TODO Unwrap container if there has no more changes
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Health',
                style: Theme.of(context)
                    .textTheme
                    .headline1
                    ?.copyWith(fontSize: 32, fontWeight: FontWeight.w400),
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _basicTiles() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _blockTile(
              'WIFI',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2',
                      style: Theme.of(context).textTheme.headline1?.copyWith(
                          fontSize: 32, fontWeight: FontWeight.w400)),
                  Text('active', style: Theme.of(context).textTheme.headline3)
                ],
              ),
            ),
            _blockTile(
              'NODES',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('3',
                      style: Theme.of(context).textTheme.headline1?.copyWith(
                          fontSize: 32, fontWeight: FontWeight.w400)),
                  Text('online', style: Theme.of(context).textTheme.headline3)
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _blockTile(String title, Widget content) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          SizedBox(
            height: 8,
          ),
          Container(
            width: double.infinity,
            child: Card(
              color: MoabColor.dashboardTileBackground,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
