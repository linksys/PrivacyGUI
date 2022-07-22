import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class InternetConnectedView extends StatelessWidget {
  InternetConnectedView({Key? key}) : super(key: key);

  // TODO: Replace this to svg
  final Widget image = Image.asset('assets/images/connected_check.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Connected to internet!',
        ),
        content: Center(
          child: image,
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
