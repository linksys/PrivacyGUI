
import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/group_profile.dart';

class ProfilesState extends Equatable {
  final Map<String, UserProfile> profiles;
  final UserProfile? createdProfile;
  final UserProfile? selectedProfile;
  final String? error;

  const ProfilesState({
    this.profiles = const {},
    this.createdProfile,
    this.selectedProfile,
    this.error,
  });

  List<UserProfile> get profileList => List.from(profiles.values);

  ProfilesState copyWith({
    Map<String, UserProfile>? profiles,
    UserProfile? createdProfile,
    UserProfile? selectedProfile,
    String? error,
  }) {
    return ProfilesState(
      profiles: profiles ?? this.profiles,
      createdProfile: createdProfile ?? this.createdProfile,
      selectedProfile: selectedProfile ?? this.selectedProfile,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        profiles,
        createdProfile,
        selectedProfile,
        error,
      ];
}
