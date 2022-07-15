
class BaseResponse <T> {
  int code;
  String message;
  T? data;

  BaseResponse({required this.code, required this.message, required this.data});

  factory BaseResponse.fromJson(Map<String, dynamic> json, Function(Map<String, dynamic>) builder) {
    return BaseResponse(code: json['status'], message: json['message'], data: builder(json['data']));
  }
}

class ErrorResponse {

  const ErrorResponse({required this.code, this.errorMessage, this.parameters});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    final String code = json['code'];
    final String? errorMessage = json['errorMessage'];
    final List<Map<String, dynamic>>? parameters = List.from(json['parameters']) ;
    return ErrorResponse(code: code, errorMessage: errorMessage, parameters: parameters);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {
      'code': code
    };
    if (errorMessage != null) {
      result.addAll({'errorMessage': errorMessage!});
    }
    if (parameters != null) {
      result.addAll({'parameters': parameters!});
    }
    return result;
  }

  final String code;
  final String? errorMessage;
  final List<Map<String, dynamic>>? parameters;
}