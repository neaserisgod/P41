import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/p41_backend_config.dart';

class CashApiException implements Exception {
  const CashApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class CashApiService {
  CashApiService({
    this.baseUrl = P41BackendConfig.apiBaseUrl,
  }) {
    _client.connectionTimeout = const Duration(seconds: 6);
  }

  final String baseUrl;
  final HttpClient _client = HttpClient();

  Future<Map<String, dynamic>?> currentShift({
    required String token,
    int? branchId,
    required String deviceId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/shifts/current').replace(
        queryParameters: {
          'device_id': deviceId,
          if (branchId != null) 'branch_id': '$branchId',
        },
      );
      final request = await _client.openUrl('GET', uri).timeout(const Duration(seconds: 6));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final response = await request.close().timeout(const Duration(seconds: 12));
      final responseBody = await utf8.decodeStream(response);
      final parsed = responseBody.isEmpty ? null : jsonDecode(responseBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = parsed is Map<String, dynamic> ? parsed['detail']?.toString() : null;
        throw CashApiException(detail ?? 'Error de servidor (${response.statusCode})', statusCode: response.statusCode);
      }

      if (parsed == null) {
        return null;
      }
      if (parsed is! Map<String, dynamic>) {
        throw const CashApiException('Respuesta invalida del servidor');
      }
      return parsed;
    } on TimeoutException {
      debugPrint('CashApiService timeout -> /api/shifts/current');
      throw const CashApiException('Tiempo de espera agotado con el backend VPS');
    } on SocketException {
      debugPrint('CashApiService socket exception -> /api/shifts/current');
      throw const CashApiException('No se pudo conectar con el backend VPS');
    }
  }

  Future<List<Map<String, dynamic>>> listShifts({
    required String token,
    int? branchId,
  }) {
    return _requestList(
      'GET',
      '/api/shifts/',
      token: token,
      queryParameters: branchId == null ? null : {'branch_id': '$branchId'},
    );
  }

  Future<Map<String, dynamic>> shiftSummary({
    required String token,
    required String shiftId,
  }) {
    return _request(
      'GET',
      '/api/shifts/$shiftId/summary',
      token: token,
    );
  }

  Future<Map<String, dynamic>> openShift({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _request(
      'POST',
      '/api/shifts/open',
      token: token,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> closeShift({
    required String token,
    required String shiftId,
    required double countedCash,
  }) {
    return _request(
      'POST',
      '/api/shifts/$shiftId/close',
      token: token,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'counted_cash': countedCash}),
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
      if (response.statusCode == 404 && responseBody.isEmpty) {
        return <String, dynamic>{};
      }
      final parsed = responseBody.isEmpty ? <String, dynamic>{} : jsonDecode(responseBody);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = parsed is Map<String, dynamic> ? parsed['detail']?.toString() : null;
        throw CashApiException(detail ?? 'Error de servidor (${response.statusCode})', statusCode: response.statusCode);
      }
      if (parsed is! Map<String, dynamic>) {
        throw const CashApiException('Respuesta invalida del servidor');
      }
      return parsed;
    } on TimeoutException {
      debugPrint('CashApiService timeout -> $path');
      throw const CashApiException('Tiempo de espera agotado con el backend VPS');
    } on SocketException {
      debugPrint('CashApiService socket exception -> $path');
      throw const CashApiException('No se pudo conectar con el backend VPS');
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
        throw CashApiException(detail ?? 'Error de servidor (${response.statusCode})', statusCode: response.statusCode);
      }
      if (parsed is! List<dynamic>) {
        throw const CashApiException('Respuesta invalida del servidor');
      }
      return parsed.whereType<Map<String, dynamic>>().toList();
    } on TimeoutException {
      debugPrint('CashApiService timeout -> $path');
      throw const CashApiException('Tiempo de espera agotado con el backend VPS');
    } on SocketException {
      debugPrint('CashApiService socket exception -> $path');
      throw const CashApiException('No se pudo conectar con el backend VPS');
    }
  }
}
