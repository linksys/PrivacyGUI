import 'package:flutter/material.dart';

class ProfileSettingsView extends StatelessWidget {
  const ProfileSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        settingsItem(),
        settingsItem()
      ],
    );
  }
}

Widget settingsItem() {
  return SizedBox(
    height: 64,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Daily time limit'),
              SizedBox(height: 4),
              Text('none', style: TextStyle(color: Color(0xff666666)))
            ]),
        Image.asset('assets/images/right_compact_wire.png')
      ],
    ),
  );
}
