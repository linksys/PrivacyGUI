import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';

import '../../../components/shortcuts/sized_box.dart';
import '../../../components/views/arguments_view.dart';

class SecurityFreeTrailPromotionView extends ArgumentsStatelessView {
  SecurityFreeTrailPromotionView({super.key, super.args, super.next});

  final Widget image = Image.asset('assets/images/security_checked_icon.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You get 30 days free!',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color.fromARGB(255, 0, 139, 89)),
          ),
          box16(),
          const Text(
            'Enterprise-level cyberthreat protection and family controls',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          box8(),
          Center(
            child: image,
          ),
          box24(),
          sectionTile(
              'You have protection from latest security threats from day 1',
              ['Malware, ransomware, botnet', 'identity theft', 'lorem ipsum']),
          box48(),
          sectionTile('Protect your family unwanted content and apps', [
            'Web content filtering',
            'Block apps',
            'Create healthy digital habits'
          ]),
          box48(),
          const Text(
            'Customize your family today. ',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(
            height: 83,
          ),
          PrimaryButton(
            text: 'Got it',
            onPress: () {},
          ),
        ],
      ),
    );
  }

  Widget sectionTile(String title, List<String> bulletStringList) {
    final Widget icon =
        Image.asset('assets/images/security_tile_checkmark.png');
    const String bullet = "\u2022 ";
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
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
            for (var item in bulletStringList)
              Text(
                bullet + item,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
              )
          ],
        )),
      ],
    );
  }
}
