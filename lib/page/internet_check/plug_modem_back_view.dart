import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class PlugModemBackView extends StatelessWidget {
  const PlugModemBackView({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Plug your modem back in',
        ),
        content: const Center(), //TODO: Add the central picture
        footer: PrimaryButton(
          text: 'Next',
          onPress: () {
            //TODO: Go to next page
          },
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}