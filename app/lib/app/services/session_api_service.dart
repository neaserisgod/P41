import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/p41_backend_config.dart';

class SessionApiException implements Exception {
  const SessionApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class SessionAuthPayload {
  const SessionAuthPayload({
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

class SessionProfilePayload {
  const SessionProfilePayload({
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

class SessionBranchPayload {
  const SessionBranchPayload({
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

class SessionStaffPayload {
  const SessionStaffPayload({
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

class SessionBootstrapPayload {
  const SessionBootstrapPayload({
    required this.auth,
    required this.profile,
    required this.branches,
    required this.staff,
  });

  final SessionAuthPayload auth;
  final SessionProfilePayload profile;
  final List<SessionBranchPayload> branches;
  final List<SessionStaffPayload> staff;
}

class SessionApiService {
  SessionApiService({
    this.baseUrl = P41BackendConfig.apiBaseUrl,
  }) {
    _client.connectionTimeout = const Duration(seconds: 6);
  }

  final String baseUrl;
  final HttpClient _client = HttpClient();

  Future<bool> checkSetupRequired() async {
    try {
      final response = await _request('GET', '/public/system-status');
      debugPrint('SessionApiService.checkSetupRequired -> $response');
      return (response['setup_required'] as bool?) ?? false;
    } on SessionApiException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  Future<SessionBootstrapPayload> login({
    required String email,
    required String password,
  }) async {
    debugPrint('SessionApiService.login start -> $email');
    final authResponse = await _request(
      'POST',
      '/api/auth/login',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
      },
      body:
          'username=${Uri.encodeQueryComponent(email)}&password=${Uri.encodeQueryComponent(password)}',
    );

    final auth = SessionAuthPayload(
      token: authResponse['access_token']?.toString() ?? '',
      userId: authResponse['user_id']?.toString() ?? '',
      email: authResponse['email']?.toString() ?? email,
      businessId: authResponse['business_id']?.toString() ?? '',
    );
    debugPrint('SessionApiService.login auth ok -> user=${auth.userId} business=${auth.businessId}');

    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${auth.token}',
    };

    final profileResponse = await _request(
      'GET',
      '/api/auth/me',
      headers: headers,
    );
    debugPrint('SessionApiService.login me ok -> $profileResponse');
    final branchesResponse = await _requestList(
      'GET',
      '/api/branches',
      headers: headers,
    );
    debugPrint('SessionApiService.login branches ok -> count=${branchesResponse.length}');

    List<dynamic> staffResponse = const [];
    try {
      staffResponse = await _requestList(
        'GET',
        '/api/staff',
        headers: headers,
      );
      debugPrint('SessionApiService.login staff ok -> count=${staffResponse.length}');
    } on SessionApiException catch (error) {
      debugPrint('SessionApiService.login staff fallback -> status=${error.statusCode} message=${error.message}');
      if (error.statusCode != 403 && error.statusCode != 404) {
        rethrow;
      }
    }

    if (staffResponse.isEmpty) {
      try {
        final usersResponse = await _requestList(
          'GET',
          '/api/users',
          headers: headers,
        );
        debugPrint('SessionApiService.login users fallback -> count=${usersResponse.length}');
        staffResponse = usersResponse
            .map(
              (entry) => {
                'id': entry['id'],
                'name': entry['display_name'] ?? entry['email'] ?? 'Usuario',
                'role': entry['role'] ?? 'cashier',
                'is_active': _isUserActive(entry['is_active']),
              },
            )
            .toList();
      } on SessionApiException catch (error) {
        debugPrint('SessionApiService.login users fallback failed -> status=${error.statusCode} message=${error.message}');
        if (error.statusCode != 403 && error.statusCode != 404) {
          rethrow;
        }
      }
    }

    final displayName = profileResponse['display_name']?.toString().trim() ?? '';
    final firstName = profileResponse['first_name']?.toString().trim() ?? '';

    final profile = SessionProfilePayload(
      userId: profileResponse['id']?.toString() ?? auth.userId,
      email: profileResponse['email']?.toString() ?? auth.email,
      displayName: displayName.isNotEmpty ? displayName : (firstName.isNotEmpty ? firstName : auth.email),
      role: profileResponse['role']?.toString() ?? 'admin',
      businessId: profileResponse['business_id']?.toString() ?? auth.businessId,
      businessName: profileResponse['business_name']?.toString() ?? 'P41',
    );

    final branches = branchesResponse
        .map(
          (branch) => SessionBranchPayload(
            id: branch['id'].toString(),
            name: branch['name']?.toString() ?? 'Sucursal',
            label: ((branch['address']?.toString() ?? '').trim().isNotEmpty)
                ? branch['address'].toString().trim()
                : 'Operacion general',
            isActive: (branch['is_active'] as bool?) ?? true,
          ),
        )
        .toList();

    final staff = staffResponse
        .map(
          (entry) => SessionStaffPayload(
            id: entry['id'].toString(),
            name: entry['name']?.toString() ?? 'Usuario',
            role: entry['role']?.toString() ?? 'cashier',
            isActive: (entry['is_active'] as bool?) ?? true,
            pin: entry['pin']?.toString(),
          ),
        )
        .toList();

    debugPrint('SessionApiService.login finish -> branches=${branches.length} staff=${staff.length}');

    return SessionBootstrapPayload(
      auth: auth,
      profile: profile,
      branches: branches,
      staff: staff,
    );
  }

  Future<void> setupAdmin({
    required String businessName,
    required String email,
    required String password,
  }) async {
    await _request(
      'POST',
      '/api/auth/setup-admin',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode({
        'business_name': businessName,
        'email': email,
        'password': password,
        'display_name': 'Administrador',
      }),
    );
  }

  Future<SessionBranchPayload> updateBranch({
    required String token,
    required String branchId,
    required String name,
    String? label,
    bool? isActive,
  }) async {
    final response = await _request(
      'PUT',
      '/api/branches/$branchId',
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'address': label,
        'is_active': isActive,
      }),
    );

    return SessionBranchPayload(
      id: response['id'].toString(),
      name: response['name']?.toString() ?? name,
      label: ((response['address']?.toString() ?? '').trim().isNotEmpty)
          ? response['address'].toString().trim()
          : 'Operacion general',
      isActive: (response['is_active'] as bool?) ?? true,
    );
  }

  Future<SessionBranchPayload> createBranch({
    required String token,
    required String name,
    required String label,
    bool isActive = true,
  }) async {
    final response = await _request(
      'POST',
      '/api/branches',
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'address': label,
        'is_active': isActive,
      }),
    );
    return SessionBranchPayload(
      id: response['id'].toString(),
      name: response['name']?.toString() ?? name,
      label: ((response['address']?.toString() ?? '').trim().isNotEmpty)
          ? response['address'].toString().trim()
          : 'Operacion general',
      isActive: (response['is_active'] as bool?) ?? true,
    );
  }

  Future<SessionStaffPayload> createStaff({
    required String token,
    required String name,
    required String role,
    required String pin,
  }) async {
    final response = await _request(
      'POST',
      '/api/staff',
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'role': _mapRoleToApi(role),
        'pin': pin,
        'is_active': true,
      }),
    );

    return SessionStaffPayload(
      id: response['id'].toString(),
      name: response['name']?.toString() ?? name,
      role: response['role']?.toString() ?? role,
      isActive: _isUserActive(response['is_active']),
      pin: response['pin']?.toString(),
    );
  }

  Future<SessionStaffPayload> updateStaff({
    required String token,
    required String id,
    required String name,
    required String role,
    required bool isActive,
    String? pin,
  }) async {
    final response = await _request(
      'PUT',
      '/api/staff/$id',
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'role': _mapRoleToApi(role),
        'is_active': isActive,
        if (pin != null && pin.trim().isNotEmpty) 'pin': pin.trim(),
      }),
    );

    return SessionStaffPayload(
      id: response['id'].toString(),
      name: response['name']?.toString() ?? name,
      role: response['role']?.toString() ?? role,
      isActive: _isUserActive(response['is_active']),
      pin: response['pin']?.toString() ?? pin,
    );
  }

  String _mapRoleToApi(String role) {
    switch (role.trim().toLowerCase()) {
      case 'administrador':
      case 'admin':
        return 'admin';
      case 'supervisor':
        return 'admin';
      case 'cajero':
      case 'cashier':
        return 'cashier';
      default:
        return role.trim().toLowerCase();
    }
  }

  bool _isUserActive(dynamic value) {
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
        final detail = parsed is Map<String, dynamic> ? parsed['detail']?.toString() : null;
        throw SessionApiException(
          detail ?? 'Error de servidor (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (parsed is! Map<String, dynamic>) {
        throw const SessionApiException('Respuesta invalida del servidor');
      }
      return parsed;
    } on TimeoutException {
      debugPrint('SessionApiService._request timeout -> $path');
      throw const SessionApiException('Tiempo de espera agotado con el backend VPS');
    } on SocketException {
      debugPrint('SessionApiService._request socket exception -> $path');
      throw const SessionApiException('No se pudo conectar con el backend VPS');
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
        final detail = parsed is Map<String, dynamic> ? parsed['detail']?.toString() : null;
        throw SessionApiException(
          detail ?? 'Error de servidor (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      if (parsed is! List<dynamic>) {
        throw const SessionApiException('Respuesta invalida del servidor');
      }
      return parsed;
    } on TimeoutException {
      debugPrint('SessionApiService._requestList timeout -> $path');
      throw const SessionApiException('Tiempo de espera agotado con el backend VPS');
    } on SocketException {
      debugPrint('SessionApiService._requestList socket exception -> $path');
      throw const SessionApiException('No se pudo conectar con el backend VPS');
    }
  }
}
