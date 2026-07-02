class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, String>? fieldErrors;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.fieldErrors,
  });

  ApiException copyWith({
    String? message,
    int? statusCode,
    Map<String, String>? fieldErrors,
  }) {
    return ApiException(
      message: message ?? this.message,
      statusCode: statusCode ?? this.statusCode,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  String toString() => message;
}