import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/logger.dart';

import 'dhcp_reservations_state.dart';

class DHCPReservationsCubit extends Cubit<DHCPReservationsState> {
  DHCPReservationsCubit({required RouterRepository repository})
      : _repository = repository,
        super(DHCPReservationsState.init());

  final RouterRepository _repository;

  Future<DHCPReservationsState> fetch() async {
    return state;
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    if (error is JNAPError) {
      // TODO handle error
      // emit(state.copyWith(errors: error.error));
    }
  }

  @override
  void onChange(Change<DHCPReservationsState> change) {
    super.onChange(change);
    if (!kReleaseMode) {
      logger.d(change);
    }
  }
}
