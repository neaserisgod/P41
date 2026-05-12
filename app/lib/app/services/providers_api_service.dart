import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ProvidersApiException implements Exception {
  const ProvidersApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ProvidersApiService {
  ProvidersApiService({
    this.baseUrl = 'http://127.0.0.1:8010',
  }) {
    _client.connectionTimeout = const Duration(seconds: 6);
  }

  final String baseUrl;
  final HttpClient _client = HttpClient();

  Future<List<Map<String, dynamic>>> listSuppliers({
    required String token,
    int? branchId,
  }) {
    return _requestList(
      'GET',
      '/api/suppliers',
      token: token,
      queryParameters: branchId == null ? null : {'branch_id': '$branchId'},
    );
  }

  Future<Map<String, dynamic>> createSupplier({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _request(
      'POST',
      '/api/suppliers',
      token: token,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> updateSupplier({
    required String token,
    required String supplierId,
    required Map<String, dynamic> body,
  }) {
    return _request(
      'PUT',
      '/api/suppliers/$supplierId',
      token: token,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<List<Map<String, dynamic>>> listOrders({
    required String token,
    String? supplierId,
    int? branchId,
  }) {
    final query = <String, String>{};
    if (supplierId != null) {
      query['supplier_id'] = supplierId;
    }
    if (branchId != null) {
      query['branch_id'] = '$branchId';
    }
    return _requestList(
      'GET',
      '/api/orders',
      token: token,
      queryParameters: query.isEmpty ? null : query,
    );
  }

  Future<Map<String, dynamic>> createOrder({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _request(
      'POST',
      '/api/orders',
      token: token,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required String token,
    required String orderId,
    required String status,
  }) {
    return _request(
      'PATCH',
      '/api/orders/$orderId/status',
      token: token,
      queryParameters: {'status': status},
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
        throw ProvidersApiException(
          detail ?? 'Error de servidor (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
      if (parsed is! Map<String, dynamic>) {
        throw const ProvidersApiException('Respuesta invalida del servidor');
      }
      return parsed;
    } on TimeoutException {
      debugPrint('ProvidersApiService timeout -> $path');
      throw const ProvidersApiException('Tiempo de espera agotado con el servidor local');
    } on SocketException {
      debugPrint('ProvidersApiService socket exception -> $path');
      throw const ProvidersApiException('No se pudo conectar con el servidor local');
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
        throw ProvidersApiException(
          detail ?? 'Error de servidor (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
      if (parsed is! List<dynamic>) {
        throw const ProvidersApiException('Respuesta invalida del servidor');
      }
      return parsed.whereType<Map<String, dynamic>>().toList();
    } on TimeoutException {
      debugPrint('ProvidersApiService timeout -> $path');
      throw const ProvidersApiException('Tiempo de espera agotado con el servidor local');
    } on SocketException {
      debugPrint('ProvidersApiService socket exception -> $path');
      throw const ProvidersApiException('No se pudo conectar con el servidor local');
    }
  }
}
