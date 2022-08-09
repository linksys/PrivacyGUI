import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import '../../../localization/localization_hook.dart';
import '../../components/base_components/base_page_view.dart';

class InternetScheduleView extends StatefulWidget {
  const InternetScheduleView({Key? key}) : super(key: key);

  @override
  State<InternetScheduleView> createState() => _InternetScheduleViewState();
}

class _InternetScheduleViewState extends State<InternetScheduleView> {
  List<Profile> profiles = [
    Profile('assets/images/sparker.png', 'Timmy'),
    Profile('assets/images/hat.png', 'Mandy')
  ];

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title:
              const Text('Internet Schedule', style: TextStyle(fontSize: 15)),
          leading: Transform.translate(
              offset: const Offset(-15, 0),
              child: BackButton(onPressed: () {})),
          actions: [
            TextButton(
                onPressed: () {},
                child: const Text('AddProfile',
                    style:
                        TextStyle(fontSize: 13, color: MoabColor.primaryBlue))),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(getAppLocalizations(context)
                .internet_schedule_view_description),
            const SizedBox(height: 24),
            profileList(profiles)
          ],
        ));
  }
}

Widget profileList(List<Profile> list) {
  return Column(
    children: [
      ...list.map((item) {
        return Column(children: [
          GestureDetector(
              child: profileCard(Image.asset(item.imagePath), Text(item.name)),
              onTap: () => print('You tapped on ${item.name}')),
          const SizedBox(height: 8)
        ]);
      })
    ],
  );
}

Widget profileCard(Widget image, Widget text) {
  return Container(
    height: 82,
    decoration: BoxDecoration(border: Border.all(color: Colors.black)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 16),
        image,
        const SizedBox(width: 21),
        Expanded(child: text),
        const SizedBox(width: 8),
        const Text("OFF"),
        const SizedBox(width: 6),
        Image.asset('assets/images/right_compact_wire.png'),
        const SizedBox(width: 12),
      ],
    ),
  );
}

class Profile {
  String imagePath;
  String name;

  Profile(this.imagePath, this.name);
}
