import 'package:flutter/material.dart';

import '../../design_system/colors.dart';
import '../../design_system/texts.dart';
import '../mesh/add_child_page.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
      child: Column(
        children: [
          const Text(
            'SSID',
            style: primaryPageTitle,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddChildPage()));
            },
            child: const Text('Add child'),
          )
        ],
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      color: MoabColor.lightGrey2,
    ));
  }
}
