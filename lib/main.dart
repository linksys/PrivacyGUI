import 'package:flutter/material.dart';
import 'package:moab_poc/page/login/view.dart';

void main() {
  runApp(const Moab());
}

class Moab extends StatelessWidget {
  const Moab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var appBarTitle = const Text('Moab');

    var appBar = AppBar(
      title: appBarTitle,
    );

    var moabApp = MaterialApp(
      home: Scaffold(
        appBar: appBar,
        body: LoginPage(),
      ),
    );

    return moabApp;
  }
}
