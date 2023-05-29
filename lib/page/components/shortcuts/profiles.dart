
import 'package:flutter/material.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';

Widget profileTileShort(BuildContext context, UserProfile profile) {
  return Hero(
    tag: 'profile-${profile.name}',
    child: Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Image.asset(
            profile.icon,
            width: 32,
            height: 32,
          ),
          box8(),
          Text(
            profile.name,
            style: Theme.of(context).textTheme.bodyLarge,
          )
        ],
      ),
    ),
  );
}