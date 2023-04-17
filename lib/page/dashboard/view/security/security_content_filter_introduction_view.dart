import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/base_components/base_page_view.dart';
import '../../../components/base_components/button/simple_text_button.dart';
import '../../../components/layouts/basic_header.dart';
import '../../../components/layouts/basic_layout.dart';
import '../../../components/shortcuts/sized_box.dart';
import '../../../components/views/arguments_view.dart';

class SecurityContentFilterIntroductionView
    extends ArgumentsConsumerStatelessView {
  SecurityContentFilterIntroductionView({super.key, super.next, super.args});

  final Widget image = Image.asset('assets/images/icon_family_security.png');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Protection from unwanted content',
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              height: 90,
              child: image,
            ),
            box24(),
            const Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
            box24(),
            _checkItem('Age appropriate filters',
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit'),
            box24(),
            _checkItem('Millions of sites inspected ',
                'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'),
            box24(),
            _checkItem('Customize for your family’s needs',
                'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'),
            const SizedBox(
              height: 64,
            ),
            Image.asset('assets/images/secured_by_fortinet.png'),
            box24(),
            Row(
              children: [
                Image.asset('assets/images/icon_earth.png'),
                Flexible(
                  child: SimpleTextButton(
                      text:
                          'Watch Fortinet stop threats in real time around the world',
                      onPressed: () {
                        //TODO: Go to next page
                      }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkItem(String title, String description) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          box8(),
          Text(
            description,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
