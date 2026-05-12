import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class SalesApiException implements Exception {
  const SalesApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class SalesApiService {
  SalesApiService({
    this.baseUrl = 'http://127.0.0.1:8010',
  }) {
    _client.connectionTimeout = const Duration(seconds: 6);
  }

  final String baseUrl;
  final HttpClient _client = HttpClient();

  Future<List<Map<String, dynamic>>> listSales({
    required String token,
    int? branchId,
  }) {
    return _requestList(
      'GET',
      '/api/sales',
      token: token,
      queryParameters: branchId == null ? null : {'branch_id': '$branchId', 'limit': '200'},
    );
  }

  Future<Map<String, dynamic>> createSale({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _request(
      'POST',
      '/api/sales',
      token: token,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    required String token,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    String? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
      final request = await _client.openUrl(method, uri).timeout(const Duration(seconds: 6));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      headers?.forEach(request.headers.set);
      if (body != null) {
        request.write(body);
      }
      final response = await request.close().timeout(const Duration(seconds: 12));
      final responseBody = await utf8.decodeStream(response);
      final parsed = responseBody.isEmpty ? <String, dynamic>{} : jsonDecode(responseBody);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = parsed is Map<String, dynamic> ? parsed['detail']?.toString() : null;
        throw SalesApiException(detail ?? 'Error de servidor (${response.statusCode})', statusCode: response.statusCode);
      }
      if (parsed is! Map<String, dynamic>) {
        throw const SalesApiException('Respuesta invalida del servidor');
      }
      return parsed;
    } on TimeoutException {
      debugPrint('SalesApiService timeout -> $path');
      throw const SalesApiException('Tiempo de espera agotado con el servidor local');
    } on SocketException {
      debugPrint('SalesApiService socket exception -> $path');
      throw const SalesApiException('No se pudo conectar con el servidor local');
    } on FormatException {
      debugPrint('SalesApiService invalid json -> $path');
      throw const SalesApiException('Respuesta invalida del servidor local');
    }
  }

  Future<List<Map<String, dynamic>>> _requestList(
    String method,
    String path, {
    required String token,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
      final request = await _client.openUrl(method, uri).timeout(const Duration(seconds: 6));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final response = await request.close().timeout(const Duration(seconds: 12));
      final responseBody = await utf8.decodeStream(response);
      final parsed = responseBody.isEmpty ? <dynamic>[] : jsonDecode(responseBody);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = parsed is Map<String, dynamic> ? parsed['detail']?.toString() : null;
        throw SalesApiException(detail ?? 'Error de servidor (${response.statusCode})', statusCode: response.statusCode);
      }
      if (parsed is! List<dynamic>) {
        throw const SalesApiException('Respuesta invalida del servidor');
      }
      return parsed.whereType<Map<String, dynamic>>().toList();
    } on TimeoutException {
      debugPrint('SalesApiService timeout -> $path');
      throw const SalesApiException('Tiempo de espera agotado con el servidor local');
    } on SocketException {
      debugPrint('SalesApiService socket exception -> $path');
      throw const SalesApiException('No se pudo conectar con el servidor local');
    } on FormatException {
      debugPrint('SalesApiService invalid json -> $path');
      throw const SalesApiException('Respuesta invalida del servidor local');
    }
  }
}
