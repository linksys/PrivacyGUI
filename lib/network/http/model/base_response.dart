
class BaseResponse <T> {
  int code;
  String message;
  T? data;

  BaseResponse({required this.code, required this.message, required this.data});

  factory BaseResponse.fromJson(Map<String, dynamic> json, Function(Map<String, dynamic>) builder) {
    return BaseResponse(code: json['status'], message: json['message'], data: builder(json['data']));
  }
}