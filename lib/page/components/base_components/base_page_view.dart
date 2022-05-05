import 'package:flutter/material.dart';

class BasePageView extends StatelessWidget {
  final AppBar? appBar;
  final Widget? child;

  const BasePageView({
    Key? key,
    this.appBar,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
          child: child,
        ),),
    );
  }

}