import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://localhost:8080/api';

  // Default headers
  static Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // GET request
  static Future<ApiResponse> get(
      String endpoint, {
        Map<String, String>? headers,
        Map<String, dynamic>? queryParams,
      }) async {
    try {
      String url = '$baseUrl$endpoint';

      // Add query parameters if provided
      if (queryParams != null && queryParams.isNotEmpty) {
        final queryString = Uri(queryParameters: queryParams.map(
              (key, value) => MapEntry(key, value.toString()),
        )).query;
        url += '?$queryString';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {..._defaultHeaders, ...?headers},
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // POST request
  static Future<ApiResponse> post(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // PUT request
  static Future<ApiResponse> put(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // PATCH request
  static Future<ApiResponse> patch(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // DELETE request
  static Future<ApiResponse> delete(
      String endpoint, {
        Map<String, String>? headers,
        Map<String, dynamic>? body,
      }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Handle response and parse JSON
  static ApiResponse _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success
      dynamic data;
      try {
        data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (e) {
        data = response.body;
      }

      return ApiResponse(
        success: true,
        data: data,
        statusCode: response.statusCode,
      );
    } else {
      // Error
      String message = 'Request failed';
      try {
        final errorData = jsonDecode(response.body);
        message = errorData['error'] ?? errorData['message'] ?? message;
      } catch (e) {
        message = response.body.isNotEmpty ? response.body : message;
      }

      return ApiResponse(
        success: false,
        message: message,
        statusCode: response.statusCode,
      );
    }
  }
}

// Response wrapper class
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  // Helper to get data as Map
  Map<String, dynamic>? get dataAsMap {
    if (data is Map<String, dynamic>) {
      return data as Map<String, dynamic>;
    }
    return null;
  }

  // Helper to get data as List
  List<dynamic>? get dataAsList {
    if (data is List) {
      return data as List<dynamic>;
    }
    return null;
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, statusCode: $statusCode, message: $message, data: $data)';
  }
}