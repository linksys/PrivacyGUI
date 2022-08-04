import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';

class DashboardHomeView extends StatefulWidget {
  const DashboardHomeView({Key? key}) : super(key: key);

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView> {
  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      scrollable: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _homeTitle(),
          SizedBox(height: 32),
          _basicTiles(),
        ],
      ),
    );
  }

  Widget _homeTitle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Image.asset('assets/images/dashboard_home.png'),
            SizedBox(
              width: 8,
            ),
            Text(
              'Home',
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(fontSize: 32, fontWeight: FontWeight.w400),
              textAlign: TextAlign.center,
            )
          ],
        ),
        Text(
          'Internet looks good!',
          style: Theme.of(context)
              .textTheme
              .headline2
              ?.copyWith(fontWeight: FontWeight.w700),
        )
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
                      style: Theme.of(context)
                          .textTheme
                          .headline1
                          ?.copyWith(
                              fontSize: 32, fontWeight: FontWeight.w400)),
                  Text('active',
                      style: Theme.of(context).textTheme.headline3)
                ],
              ),
            ),
            _blockTile(
              'NODES',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('3',
                      style: Theme.of(context)
                          .textTheme
                          .headline1
                          ?.copyWith(
                          fontSize: 32, fontWeight: FontWeight.w400)),
                  Text('online',
                      style: Theme.of(context).textTheme.headline3)
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
