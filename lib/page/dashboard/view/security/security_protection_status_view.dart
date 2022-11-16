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
      scrollable: true,
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Enterprise-level cyberthreat protection',
          spacing: 0,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              height: 90,
              child: Image.asset('assets/images/security_good.png'),
            ),
            box24(),
            _checkItem('viruses', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
            box24(),
            _checkItem('Malware & Ransomware', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit'),
            box24(),
            _checkItem('Phishing Smishing', 'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'),
            box24(),
            _checkItem('Lorem Ipsum', 'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'),
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

  Widget _checkItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        ),
      ],
    );
  }
}
