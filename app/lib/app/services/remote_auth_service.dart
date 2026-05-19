import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

const _remoteAuthBaseUrl = String.fromEnvironment(
  'P41_API_BASE_URL',
  defaultValue: 'http://31.97.166.250',
);

class RemoteAuthException implements Exception {
  const RemoteAuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class RemoteAuthPayload {
  const RemoteAuthPayload({
    required this.token,
    required this.userId,
    required this.email,
    required this.businessId,
  });

  final String token;
  final String userId;
  final String email;
  final String businessId;
}

class RemoteProfilePayload {
  const RemoteProfilePayload({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.businessId,
    required this.businessName,
  });

  final String userId;
  final String email;
  final String displayName;
  final String role;
  final String businessId;
  final String businessName;
}

class RemoteBranchPayload {
  const RemoteBranchPayload({
    required this.id,
    required this.name,
    required this.label,
    required this.isActive,
  });

  final String id;
  final String name;
  final String label;
  final bool isActive;
}

class RemoteUserPayload {
  const RemoteUserPayload({
    required this.id,
    required this.name,
    required this.role,
    required this.isActive,
    this.pin,
  });

  final String id;
  final String name;
  final String role;
  final bool isActive;
  final String? pin;
}

class RemoteBootstrapPayload {
  const RemoteBootstrapPayload({
    required this.auth,
    required this.profile,
    required this.branches,
    required this.users,
  });

  final RemoteAuthPayload auth;
  final RemoteProfilePayload profile;
  final List<RemoteBranchPayload> branches;
  final List<RemoteUserPayload> users;
}

class RemoteAuthService {
  RemoteAuthService({
    this.baseUrl = _remoteAuthBaseUrl,
  }) {
    _client.connectionTimeout = const Duration(seconds: 6);
  }

  final String baseUrl;
  final HttpClient _client = HttpClient();

  Future<void> createInitialAdmin({
    required String businessName,
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _request(
      'POST',
      '/api/auth/setup-admin',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode({
        'business_name': businessName,
        'business_type': 'retail',
        'email': email,
        'password': password,
        'display_name': displayName,
      }),
    );
  }

  Future<RemoteBootstrapPayload> login({
    required String email,
    required String password,
  }) async {
    final authResponse = await _request(
      'POST',
      '/api/auth/login',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
      },
      body:
          'username=${Uri.encodeQueryComponent(email)}&password=${Uri.encodeQueryComponent(password)}',
    );

    final auth = RemoteAuthPayload(
      token: authResponse['access_token']?.toString() ?? '',
      userId: authResponse['user_id']?.toString() ?? '',
      email: authResponse['email']?.toString() ?? email,
      businessId: authResponse['business_id']?.toString() ?? '',
    );

    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${auth.token}',
    };

    final profileResponse = await _request(
      'GET',
      '/api/auth/me',
      headers: headers,
    );
    final branchesResponse = await _requestList(
      'GET',
      '/api/branches',
      headers: headers,
    );

    List<dynamic> usersResponse = const [];
    try {
      usersResponse = await _requestList(
        'GET',
        '/api/users',
        headers: headers,
      );
    } on RemoteAuthException catch (error) {
      if (error.statusCode != 403 && error.statusCode != 404) {
        rethrow;
      }
    }

    final displayName = profileResponse['display_name']?.toString().trim() ?? '';
    final firstName = profileResponse['first_name']?.toString().trim() ?? '';
    final profile = RemoteProfilePayload(
      userId: profileResponse['id']?.toString() ?? auth.userId,
      email: profileResponse['email']?.toString() ?? auth.email,
      displayName: displayName.isNotEmpty
          ? displayName
          : (firstName.isNotEmpty ? firstName : auth.email),
      role: profileResponse['role']?.toString() ?? 'owner',
      businessId: profileResponse['business_id']?.toString() ?? auth.businessId,
      businessName: profileResponse['business_name']?.toString() ?? 'P41',
    );

    final branches = branchesResponse
        .map(
          (branch) => RemoteBranchPayload(
            id: branch['id'].toString(),
            name: branch['name']?.toString() ?? 'Sucursal',
            label: ((branch['address']?.toString() ?? '').trim().isNotEmpty)
                ? branch['address'].toString().trim()
                : 'Operacion general',
            isActive: _isActive(branch['is_active']),
          ),
        )
        .toList();

    final users = usersResponse
        .map(
          (entry) => RemoteUserPayload(
            id: entry['id'].toString(),
            name: entry['display_name']?.toString() ??
                entry['name']?.toString() ??
                entry['email']?.toString() ??
                'Usuario',
            role: entry['role']?.toString() ?? 'cashier',
            isActive: _isActive(entry['is_active']),
            pin: entry['pin']?.toString(),
          ),
        )
        .toList();

    return RemoteBootstrapPayload(
      auth: auth,
      profile: profile,
      branches: branches,
      users: users,
    );
  }

  bool _isActive(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value != '0' && value.toLowerCase() != 'false';
    }
    return true;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? headers,
    String? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await _client.openUrl(method, uri).timeout(
            const Duration(seconds: 6),
          );
      headers?.forEach(request.headers.set);
      if (body != null) {
        request.write(body);
      }
      final response = await request.close().timeout(
            const Duration(seconds: 12),
          );
      final responseBody = await utf8.decodeStream(response);
      final parsed = responseBody.isEmpty ? <String, dynamic>{} : jsonDecode(responseBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = parsed is Map<String, dynamic>
            ? parsed['detail']?.toString()
            : null;
        throw RemoteAuthException(
          detail ?? 'Error de servidor (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (parsed is! Map<String, dynamic>) {
        throw const RemoteAuthException('Respuesta invalida del servidor');
      }
      return parsed;
    } on TimeoutException {
      debugPrint('RemoteAuthService._request timeout -> $path');
      throw const RemoteAuthException('Tiempo de espera agotado con el VPS');
    } on SocketException {
      debugPrint('RemoteAuthService._request socket exception -> $path');
      throw const RemoteAuthException('No se pudo conectar con el VPS');
    }
  }

  Future<List<dynamic>> _requestList(
    String method,
    String path, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await _client.openUrl(method, uri).timeout(
            const Duration(seconds: 6),
          );
      headers?.forEach(request.headers.set);
      final response = await request.close().timeout(
            const Duration(seconds: 12),
          );
      final responseBody = await utf8.decodeStream(response);
      final parsed = responseBody.isEmpty ? <dynamic>[] : jsonDecode(responseBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = parsed is Map<String, dynamic>
            ? parsed['detail']?.toString()
            : null;
        throw RemoteAuthException(
          detail ?? 'Error de servidor (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (parsed is! List<dynamic>) {
        throw const RemoteAuthException('Respuesta invalida del servidor');
      }
      return parsed;
    } on TimeoutException {
      debugPrint('RemoteAuthService._requestList timeout -> $path');
      throw const RemoteAuthException('Tiempo de espera agotado con el VPS');
    } on SocketException {
      debugPrint('RemoteAuthService._requestList socket exception -> $path');
      throw const RemoteAuthException('No se pudo conectar con el VPS');
    }
  }
}
