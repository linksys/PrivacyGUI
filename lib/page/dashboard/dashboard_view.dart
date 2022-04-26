import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/design_system/colors.dart';
import 'package:moab_poc/design_system/texts.dart';
import 'package:moab_poc/page/dashboard/state.dart';
import 'package:moab_poc/page/mesh/view.dart';

import 'cubit.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Container(
              child: Column(
                children: [
                  Text(
                    state.ssid,
                    style: primaryPageTitle,
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
              color: MoabColor.white,
            ),
          ),
        );
      },
    );
  }
}
