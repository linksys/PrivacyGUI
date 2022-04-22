import 'package:flutter/material.dart';
import 'package:moab_poc/design_system/colors.dart';
import 'package:moab_poc/design_system/texts.dart';
import '../mesh/add_child_page.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              const Text(
                'SSID',
                style: primaryPageTitle,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AddChildPage.routeName);
                },
                child: const Text('Add child'),
              )
            ],
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
          color: MoabColor.white,
        ),
      ),
    );
  }
}
