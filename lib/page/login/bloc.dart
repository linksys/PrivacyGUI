import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/page/login/event.dart';
import 'package:moab_poc/repository/authenticate/auth_repository.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:moab_poc/util/logger.dart';

import 'state.dart';

enum OtpMethod {
  text, email
}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _repository;

  LoginBloc({required AuthRepository repo})
      : _repository = repo,
        super(const LoginInitial()) {
    on<GoForgotEmail>(_oGoForgotEmail);
    on<GoLocalLogin>(_onGoLocalLogin);
    on<TestUserName>(_onTestUsername);
    on<Initial>(_init);
  }

  _init(Initial event, Emitter<LoginState> emit) {
    emit(const LoginInitial());
  }
  _oGoForgotEmail(GoForgotEmail event, Emitter<LoginState> emit) {
    emit(const ForgotEmail());
  }

  _onGoLocalLogin(GoLocalLogin event, Emitter<LoginState> emit) {
    emit(const LocalLogin());
  }

  _onTestUsername(TestUserName event, Emitter<LoginState> emit) async {
    await _repository
        .testUsername(event.username)
        .then((value) => _handleTestUsername(value, emit))
        .onError((error, stackTrace) => _handleError(error, stackTrace, emit));
  }

  _handleTestUsername(DummyModel data, emit) {
    logger.d("handle test user name");
    final List<DummyModel> methodList = data['method'] as List<DummyModel>? ?? [];
    if (methodList.isEmpty) {
      // no account exist
    } else if (methodList.length == 1) {
      final methodObj = methodList[0] as Map<String, String>;
      final method = OtpMethod.values.firstWhere((element) => element.name == methodObj.entries.first.key);
      final target = methodObj.entries.first.value;
      emit(WaitForOTP(method, target));
    } else { //2
      emit(ChoosePasswordLessMethod(methodList));
    }
  }

  _handleError(Object? error, StackTrace stackTrace, emit) {
    logger.d("error handler: $error, $stackTrace");
  }
}
