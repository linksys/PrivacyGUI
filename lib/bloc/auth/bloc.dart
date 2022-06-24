import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/event.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/repository/authenticate/auth_repository.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:moab_poc/util/logger.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repo})
      : _repository = repo,
        super(AuthState.unknownAuth()) {
    on<InitAuth>(_onInitAuth);
  }

  _onInitAuth(InitAuth event, Emitter<AuthState> emit) {
    // TODO check authorize from local
    emit(AuthState.unAuthorized());
    // emit(AuthState.authorized(method: AuthMethod.remote));
  }

  @override
  void onTransition(Transition<AuthEvent, AuthState> transition) {
    super.onTransition(transition);
    logger.d("AuthBloc:: onTransition: $transition");
  }
}

extension AuthBlocExts on AuthBloc {
  Future<List<OtpInfo>> testUsername(String username) async {
    return await _repository
        .testUsername(username)
        .then((value) => _handleTestUsername(value));
  }

  Future<String> passwordLessLogin(String username, String method) async {
    return await _repository.passwordLessLogin(username, method).then((value) => value['token']);
  }

  Future<void> resendCode(String token, String method) async {
    return await _repository.resendCode(token, method);
  }


  Future<List<OtpInfo>> _handleTestUsername(DummyModel data) async {
    logger.d("handle test user name");
    final List<DummyModel> methodList =
        data['method'] as List<DummyModel>? ?? [];
    List<OtpInfo> list = [];
    for (var data in methodList) {
      final method = OtpMethod.values
          .firstWhere((element) => element.name == data.entries.first.key);
      final String target = data.entries.first.value;
      list.add(OtpInfo(method: method, data: target));
    }
    return list;
  }

  _handleError(Object? error, StackTrace stackTrace, emit) {
    logger.d("error handler: $error, $stackTrace");
  }
}
