import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/model/secure_profile.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:collection/collection.dart';

import 'state.dart';

class ContentFilterCubit extends Cubit<ContentFilterState> {
  ContentFilterCubit()
      : super(
          const ContentFilterState(),
        );

  selectSecureProfile(CFSecureProfile? secureProfile) {
    emit(state.copyWith(selectedSecureProfile: secureProfile));
  }

  Future<void> updateSearchAppSignature(CFAppSignature signature) async {
    final copy = Set<CFAppSignature>.from(state.searchAppSignatureSet);
    final target = state.searchAppSignatureSet.firstWhereOrNull(
        (element) => element.raw.first.id == signature.raw.first.id);
    if (target != null) {
      copy
        ..remove(target)
        ..add(signature);
    } else {
      copy.add(signature);
    }
    logger.d('Search App Signature Size: ${copy.length}');
    emit(state.copyWith(searchAppSignatureSet: copy));
  }

  FilterStatus checkSearchAppSignatureStatus(String appId) {
    CFAppSignature? target = state.searchAppSignatureSet
        .firstWhereOrNull((app) => app.raw.first.id == appId);
    if (target != null) {
      return target.status;
    }
    return state.selectedSecureProfile?.securityCategories
            .firstWhereOrNull(
                (category) => category.getRawAppById(appId) != null)
            ?.getAppById(appId)
            ?.status ??
        FilterStatus.notAllowed;
  }

  @override
  void onChange(Change<ContentFilterState> change) {
    super.onChange(change);
    logger.i(
        'Content Filter Cubit changed: ${change.currentState} -> ${change.nextState}');
  }
}
