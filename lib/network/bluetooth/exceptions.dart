class BTError implements Exception{

  final String code;
  final String message;

  const BTError({
    required this.code,
    required this.message,
  });
}