
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

  const ErrorResponse({required this.status, required this.code, this.errorMessage, this.parameters});

  factory ErrorResponse.fromJson(int status, Map<String, dynamic> json) {
    final errorsJson = json['errors'];
    if (errorsJson != null) {
      final errorJson = List.from(errorsJson)[0]['error'];
      final String code = errorJson['code'];
      final String? errorMessage = errorJson['message'];
      final List<Map<String, dynamic>>? parameters = !errorJson.containsKey('parameters') ? null : List.from(errorJson['parameters']) ;
      return ErrorResponse(status: status,code: code, errorMessage: errorMessage, parameters: parameters);
    } else {
      final String code = json['error'];
      final String? errorMessage = json['error_description'];
      final List<Map<String, dynamic>>? parameters = !json.containsKey('parameters') ? null : List.from(json['parameters']) ;
      return ErrorResponse(status: status,code: code, errorMessage: errorMessage, parameters: parameters);
    }

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

  final int status;
  final String code;
  final String? errorMessage;
  final List<Map<String, dynamic>>? parameters;
}