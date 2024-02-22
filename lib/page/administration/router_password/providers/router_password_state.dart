import 'package:equatable/equatable.dart';

class RouterPasswordState extends Equatable {
  final String adminPassword;
  final String hint;
  final bool isLoading;
  final bool isValid;
  final bool isDefault;
  final bool isSetByUser;
  final bool hasEdited;
  final String? error;
  final int? remainingErrorAttempts;

  @override
  List<Object?> get props => [
        adminPassword,
        hint,
        isLoading,
        isValid,
        isDefault,
        isSetByUser,
        hasEdited,
        error,
        remainingErrorAttempts,
      ];

  const RouterPasswordState({
    required this.adminPassword,
    required this.hint,
    this.isLoading = true,
    required this.isValid,
    required this.isDefault,
    required this.isSetByUser,
    required this.hasEdited,
    this.error,
    this.remainingErrorAttempts,
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
      remainingErrorAttempts: null,
    );
  }

  RouterPasswordState copyWith({
    String? adminPassword,
    String? hint,
    bool? isLoading,
    bool? isValid,
    bool? isDefault,
    bool? isSetByUser,
    bool? hasEdited,
    String? error,
    int? remainingErrorAttempts,
  }) {
    return RouterPasswordState(
      adminPassword: adminPassword ?? this.adminPassword,
      hint: hint ?? this.hint,
      isLoading: isLoading ?? this.isLoading,
      isValid: isValid ?? this.isValid,
      isDefault: isDefault ?? this.isDefault,
      isSetByUser: isSetByUser ?? this.isSetByUser,
      hasEdited: hasEdited ?? this.hasEdited,
      error: error ?? this.error,
      remainingErrorAttempts:
          remainingErrorAttempts ?? this.remainingErrorAttempts,
    );
  }
}
