import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/route/route.dart';
import '../../../localization/localization_hook.dart';
import '../../../route/model/dashboard_path.dart';
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
          title: const Text('Internet Schedule',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading: BackButton(onPressed: () {
            NavigationCubit.of(context).pop();
          }),
          actions: [
            TextButton(
                onPressed: () {
                  NavigationCubit.of(context).push(CreateProfileNamePath()
                    ..next = InternetSchedulePath());
                },
                child: const Text('Add Profile',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: MoabColor.textButtonBlue))),
          ],
        ),
        child: Container(
            color: const Color.fromARGB(1, 221, 221, 221),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Text(
                    getAppLocalizations(context)
                        .internet_schedule_view_description,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 24),
                profileList(context, profiles)
              ],
            )));
  }
}

Widget profileList(BuildContext context, List<Profile> list) {
  return Column(
    children: [
      ...list.map((item) {
        return Column(children: [
          GestureDetector(
              child: profileCard(
                  Image.asset(item.imagePath),
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700))),
              onTap: () =>
                  NavigationCubit.of(context).push(ProfileSettingsPath())),
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
        const Text("OFF", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color.fromRGBO(102, 102, 102, 1.0))),
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
