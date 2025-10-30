class BaseResponse<T> {
  final bool isSuccess;
  final String message;
  final T? data;
  final int? statusCode;

  BaseResponse({
    required this.isSuccess,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return BaseResponse<T>(
      isSuccess: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      statusCode: json['status_code'],
    );
  }

  factory BaseResponse.success({
    required T data,
    String message = 'Success',
    int? statusCode,
  }) {
    return BaseResponse<T>(
      isSuccess: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }

  factory BaseResponse.error({required String message, int? statusCode}) {
    return BaseResponse<T>(
      isSuccess: false,
      message: message,
      statusCode: statusCode,
    );
  }
}
