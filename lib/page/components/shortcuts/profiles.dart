import 'package:flutter/material.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

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
          const AppGap.semiSmall(),
          Text(
            profile.name,
            style: Theme.of(context).textTheme.bodyLarge,
          )
        ],
      ),
    ),
  );
}
