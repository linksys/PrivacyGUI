import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/wan_status.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/batch_extension.dart';
import 'package:linksys_moab/repository/router/router_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';

import 'state.dart';

class PortForwardingCubit extends Cubit<PortForwardingState> {
  PortForwardingCubit(RouterRepository repository)
      : _repository = repository,
        super(PortForwardingState.init());

  final RouterRepository _repository;

  fetch() async {

  }


  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    if (error is JnapError) {
      // handle error
      emit(state.copyWith(error: error.error));
    }
  }

  @override
  void onChange(Change<PortForwardingState> change) {
    super.onChange(change);
    if (!kReleaseMode) {
      logger.d(change);
    }
  }
}
