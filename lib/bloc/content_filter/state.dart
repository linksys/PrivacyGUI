import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/model/secure_profile.dart';

class ContentFilterState extends Equatable {
  final CFSecureProfile? selectedSecureProfile;
  final Set<CFAppSignature> searchAppSignatureSet;

  const ContentFilterState({
    this.selectedSecureProfile,
    this.searchAppSignatureSet = const {},
  });

  ContentFilterState copyWith({
    CFSecureProfile? selectedSecurePreset,
    Set<CFAppSignature>? searchAppSignatureSet,
  }) {
    return ContentFilterState(
      selectedSecureProfile: selectedSecurePreset ?? this.selectedSecureProfile,
      searchAppSignatureSet:
          searchAppSignatureSet ?? this.searchAppSignatureSet,
    );
  }

  @override
  List<Object?> get props => [
        selectedSecureProfile,
        searchAppSignatureSet,
      ];
}
