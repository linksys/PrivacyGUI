import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';

class WiFiView extends ArgumentsStatelessView {
  const WiFiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: TextButton(
            onPressed: () {
              NavigationCubit.of(context).push(ShareWifiPath());
            },
            child: Text('click me')));
  }
}
