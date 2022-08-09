import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';

class ProfileSettingsView extends StatelessWidget {
  const ProfileSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Timmy', style: TextStyle(fontSize: 15)),
        leading: Transform.translate(
            offset: const Offset(-15, 0), child: BackButton(onPressed: () {})),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          timeLimitSettingsItem(() {}),
          schedulePauseSettingsItem(() {})
        ],
      ),
    );
  }
}

Widget timeLimitSettingsItem(VoidCallback onTap) {
  return SizedBox(
      height: 64,
      child: GestureDetector(
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
          onTap: () => onTap
      )
  );
}

Widget schedulePauseSettingsItem(VoidCallback onTap) {
  return SizedBox(
      height: 64,
      child: GestureDetector(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Scheduled pauses'),
                    SizedBox(height: 4),
                    Text('none', style: TextStyle(color: Color(0xff666666)))
                  ]),
              Image.asset('assets/images/right_compact_wire.png')
            ],
          ), onTap: () => onTap
      )
  );
}
