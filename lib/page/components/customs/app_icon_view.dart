import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/security/app_icon_manager.dart';

///
/// This widget is only used for the AppSignatures
///
class AppIconView extends ConsumerStatefulWidget {
  const AppIconView({
    Key? key,
    this.appId = '0',
  }) : super(key: key);

  final String appId;

  @override
  ConsumerState<AppIconView> createState() => _AppIconViewState();
}

class _AppIconViewState extends ConsumerState<AppIconView> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = AppIconManager.instance().getIconByte(widget.appId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: FutureBuilder<Uint8List>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.memory(snapshot.data!);
              } else if (snapshot.hasError) {
                return const Icon(Icons.cancel);
              } else {
                return CircularProgressIndicator(
                  color: MoabColor.placeholderGrey,
                );
              }
            }),
      ),
    );
  }
}
