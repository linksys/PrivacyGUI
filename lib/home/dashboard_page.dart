import 'package:flutter/material.dart';
import 'package:moab_poc/home/add_child_page.dart';

import '../design_system/colors.dart';
import '../design_system/texts.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          const Text('SSID', style: primaryPageTitle,),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AddChildPage()));
            },
            child: const Text('Add child'),
          )
        ],
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      color: MoabColor.lightGrey2,
    );
  }

}