import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';

class SecurityProtectionStatusView extends StatelessWidget {
  const SecurityProtectionStatusView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'You’re protected',
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              height: 150,
              child: Image.asset('assets/images/security_good.png'),
            ),
            _checkItem(),
            box24(),
            _checkItem(),
            box24(),
            _checkItem(),
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
                    text: 'Watch Fortinet stop threats in real time around the world',
                    onPressed: () {
                      //TODO: Go to next page
                    }
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkItem() {
    return Row(
      children: [
        Image.asset(
          'assets/images/icon_checked_circle.png',
          height: 25,
          width: 25,
        ),
        box8(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lorem ipsum dolor sit',
              ),
              box8(),
              const Text(
                'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
