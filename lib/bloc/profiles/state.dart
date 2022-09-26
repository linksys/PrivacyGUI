import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/group_profile.dart';

class ProfilesState extends Equatable {
  final Map<String, GroupProfile> profiles;
  final GroupProfile? createdProfile;
  final GroupProfile? selectedProfile;

  const ProfilesState({
    this.profiles = const {},
    this.createdProfile,
    this.selectedProfile,
  });

  List<GroupProfile> get profileList => List.from(profiles.values);

  ProfilesState copyWith({
    Map<String, GroupProfile>? profiles,
    GroupProfile? createdProfile,
    GroupProfile? selectedProfile,
  }) {
    return ProfilesState(
      profiles: profiles ?? this.profiles,
      createdProfile: createdProfile ?? this.createdProfile,
      selectedProfile: selectedProfile ?? this.selectedProfile,
    );
  }

  ProfilesState addOrUpdateProfile(GroupProfile profile) {
    var copy = Map<String, GroupProfile>.from(profiles);
    copy[profile.id] = profile;
    if (selectedProfile?.id == profile.id) {
      return copyWith(profiles: copy, selectedProfile: profile);
    }
    return copyWith(profiles: copy);
  }

  @override
  List<Object?> get props =>
      [
        profiles,
        createdProfile,
        selectedProfile,
      ];
}
