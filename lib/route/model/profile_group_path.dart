
import 'package:flutter/widgets.dart';
import '../../page/dashboard/view/profile/_profile.dart';
import '_model.dart';
import 'package:linksys_moab/route/_route.dart';


class ProfileGroupPath extends DashboardPath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case ProfileListPath:
        return ProfileListView(
          args: args,
          next: next,
        );
      case CreateProfileNamePath:
        return CreateProfileNameView(
          args: args,
          next: next,
        );
      case CreateProfileDevicesSelectedPath:
        return ProfileSelectDevicesView(
          args: args,
          next: next,
        );
      case CreateProfileAvatarPath:
        return ProfileSelectAvatarView(
          args: args,
          next: next,
        );
      case ProfileOverviewPath:
        return ProfileOverviewView(
          args: args,
          next: next,
        );
      case ProfileEditPath:
        return ProfileEditView(
          args: args,
          next: next,
        );
      case ProfileEditNameAvatarPath:
        return ProfileEditNameAvatarView(
          args: args,
          next: next,
        );
      default:
        return Center();
    }
  }
}
class CreateProfileNamePath extends ProfileGroupPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class CreateProfileDevicesSelectedPath extends ProfileGroupPath
    with ReturnablePath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class CreateProfileAvatarPath extends ProfileGroupPath with ReturnablePath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class ProfileOverviewPath extends ProfileGroupPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class ProfileEditPath extends ProfileGroupPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class ProfileEditNameAvatarPath extends ProfileGroupPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class ProfileListPath extends ProfileGroupPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}
