import 'package:flutter/material.dart';
import 'package:moab_poc/page/poc/mesh/view.dart';

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
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, MeshPage.routeName);
                },
                child: const Text('Add child'),
              )
            ],
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
          color: Colors.white,
        ),
      ),
    );
  }
}