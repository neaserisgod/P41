import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/global_catalog_product.dart';
import 'global_lookup_local_service.dart';

class CatalogApiException implements Exception {
  const CatalogApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class CatalogSyncPayload {
  const CatalogSyncPayload({required this.products, required this.suppliers});

  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> suppliers;
}

class CatalogApiService {
  CatalogApiService({
    this.baseUrl = 'http://127.0.0.1:8010',
    GlobalLookupLocalService? localLookup,
  }) : _localLookup = localLookup ?? const GlobalLookupLocalService() {
    _client.connectionTimeout = const Duration(seconds: 6);
  }

  final String baseUrl;
  final HttpClient _client = HttpClient();
  final GlobalLookupLocalService _localLookup;

  Future<CatalogSyncPayload> pullCatalog({
    required String token,
    required String deviceId,
    int? branchId,
  }) async {
    final query = <String, String>{
      'device_id': deviceId,
      'last_sync_version': '0',
    };
    if (branchId != null) {
      query['branch_id'] = '$branchId';
    }

    final response = await _request(
      'GET',
      '/api/sync/pull',
      token: token,
      queryParameters: query,
    );

    final products = (response['products'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final suppliers = (response['suppliers'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return CatalogSyncPayload(products: products, suppliers: suppliers);
  }

  Future<Map<String, dynamic>> createProduct({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _request(
      'POST',
      '/api/products',
      token: token,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> updateProduct({
    required String token,
    required String productId,
    required Map<String, dynamic> body,
  }) {
    return _request(
      'PUT',
      '/api/products/$productId',
      token: token,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<GlobalCatalogProduct?> lookupGlobalProduct(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final localMatch = await _localLookup.lookup(normalized);
    if (localMatch != null) {
      return localMatch;
    }
    final response = await _requestPublic(
      'GET',
      '/api/products/global-lookup/$normalized',
    );
    if (response is! Map<String, dynamic>) {
      return null;
    }
    return GlobalCatalogProduct.fromJson(response);
  }

  Future<List<GlobalCatalogProduct>> searchGlobalProducts(String query) async {
    final normalized = query.trim();
    if (normalized.length < 3) {
      return const [];
    }
    final localResults = await _localLookup.search(normalized);
    if (localResults.isNotEmpty || await _localLookup.hasCatalog()) {
      return localResults;
    }
    final response = await _requestPublic(
      'GET',
      '/api/products/global-search',
      queryParameters: {'q': normalized},
    );
    if (response is! List<dynamic>) {
      throw const CatalogApiException('Respuesta invalida del servidor');
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(GlobalCatalogProduct.fromJson)
        .toList();
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
      final uri = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: queryParameters);
      final request = await _client
          .openUrl(method, uri)
          .timeout(const Duration(seconds: 6));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      headers?.forEach(request.headers.set);
      if (body != null) {
        request.write(body);
      }

      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final responseBody = await utf8.decodeStream(response);
      final parsed = responseBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = parsed is Map<String, dynamic>
            ? parsed['detail']?.toString()
            : null;
        throw CatalogApiException(
          detail ?? 'Error de servidor (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (parsed is! Map<String, dynamic>) {
        throw const CatalogApiException('Respuesta invalida del servidor');
      }

      return parsed;
    } on TimeoutException {
      debugPrint('CatalogApiService._request timeout -> $path');
      throw const CatalogApiException(
        'Tiempo de espera agotado con el servidor local',
      );
    } on SocketException {
      debugPrint('CatalogApiService._request socket exception -> $path');
      throw const CatalogApiException(
        'No se pudo conectar con el servidor local',
      );
    }
  }

  Future<dynamic> _requestPublic(
    String method,
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: queryParameters);
      final request = await _client
          .openUrl(method, uri)
          .timeout(const Duration(seconds: 6));
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final responseBody = await utf8.decodeStream(response);
      final parsed = responseBody.isEmpty ? null : jsonDecode(responseBody);

      if (response.statusCode == 404) {
        return null;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = parsed is Map<String, dynamic>
            ? parsed['detail']?.toString()
            : null;
        throw CatalogApiException(
          detail ?? 'Error de servidor (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
      return parsed;
    } on TimeoutException {
      debugPrint('CatalogApiService._requestPublic timeout -> $path');
      throw const CatalogApiException(
        'Tiempo de espera agotado con el servidor local',
      );
    } on SocketException {
      debugPrint('CatalogApiService._requestPublic socket exception -> $path');
      throw const CatalogApiException(
        'No se pudo conectar con el servidor local',
      );
    }
  }
}
