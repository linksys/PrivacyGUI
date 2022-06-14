import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

import '../../components/base_components/button/primary_button.dart';
import '../../components/base_components/button/simple_text_button.dart';

class NodesSuccessView extends StatelessWidget {
  const NodesSuccessView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  @override
  Widget build(BuildContext context) {
    double width = 220;
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Good work',
        ),
        content: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/nodes_topology.png',
                  width: width,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 48, 0, 48), // TODO
                child: Center(
                  child: SimpleTextButton(
                      text: 'Add a node',
                      onPressed: () {
                        //TODO: onPressed Action
                      }),
                ),
              ),
              const DescriptionText(
                  text: 'You can edit nodes in the app after setup'),
            ],
          ),
        ),
        footer: Column(
          children: [
            PrimaryButton(
              text: 'Let\'s add a WiFi name',
              onPress: onNext,
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
