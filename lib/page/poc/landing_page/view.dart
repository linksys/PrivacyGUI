import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/page/poc/landing_page/bloc.dart';
import 'package:moab_poc/page/poc/landing_page/landing_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  static const routeName = '/Landing';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => LandingBloc(),
      child: Builder(builder: (context) => _buildPage(context)),
    );
  }

  Widget _buildPage(BuildContext context) {
    return const LandingView();
  }
}
