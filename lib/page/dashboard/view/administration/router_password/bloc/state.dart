import 'package:equatable/equatable.dart';
import 'package:linksys_moab/page/dashboard/view/administration/router_password/bloc/cubit.dart';

class RouterPasswordState extends Equatable {
  final String adminPassword;
  final String hint;
  final bool isValid;
  final bool isDefault;
  final bool isSetByUser;
  final bool hasEdited;
  final String? error;

  @override
  List<Object?> get props =>
      [adminPassword, hint, isValid, isDefault, isSetByUser, hasEdited, error];

  const RouterPasswordState({
    required this.adminPassword,
    required this.hint,
    required this.isValid,
    required this.isDefault,
    required this.isSetByUser,
    required this.hasEdited,
    this.error,
  });

  factory RouterPasswordState.init() {
    return const RouterPasswordState(
      adminPassword: '',
      hint: '',
      isValid: false,
      isDefault: true,
      isSetByUser: false,
      hasEdited: false,
      error: null,
    );
  }

  RouterPasswordState copyWith({
    String? adminPassword,
    String? hint,
    bool? isValid,
    bool? isDefault,
    bool? isSetByUser,
    bool? hasEdited,
    String? error,
  }) {
    return RouterPasswordState(
      adminPassword: adminPassword ?? this.adminPassword,
      hint: hint ?? this.hint,
      isValid: isValid ?? this.isValid,
      isDefault: isDefault ?? this.isDefault,
      isSetByUser: isSetByUser ?? this.isSetByUser,
      hasEdited: hasEdited ?? this.hasEdited,
      error: error ?? this.error,
    );
  }
}
