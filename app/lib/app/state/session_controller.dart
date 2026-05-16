import 'package:flutter/material.dart';

import '../services/local_store_service.dart';
import '../services/session_persistence_service.dart';
import '../services/session_api_service.dart';
import '../models/session_context.dart';

enum SessionStage { loading, setup, login, branchSelection, userSelection, ready }

class RememberedAccount {
  const RememberedAccount({
    required this.scopeKey,
    required this.email,
    required this.accountName,
  });

  final String scopeKey;
  final String email;
  final String accountName;

  String get initials {
    final parts = accountName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'HP';
    }
    if (parts.length == 1) {
      final single = parts.first;
      return single.substring(0, single.length > 1 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class LocalAccessUser {
  const LocalAccessUser({
    required this.id,
    required this.name,
    required this.role,
    required this.initials,
    required this.branchIds,
  });

  final String id;
  final String name;
  final String role;
  final String initials;
  final List<String> branchIds;
}

class AccountProfile {
  const AccountProfile({
    required this.accountName,
    required this.ownerEmail,
    required this.password,
    required this.users,
    required this.branches,
  });

  final String accountName;
  final String ownerEmail;
  final String password;
  final List<SessionUser> users;
  final List<SessionBranch> branches;

  AccountProfile copyWith({
    String? accountName,
    String? ownerEmail,
    String? password,
    List<SessionUser>? users,
    List<SessionBranch>? branches,
  }) {
    return AccountProfile(
      accountName: accountName ?? this.accountName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      password: password ?? this.password,
      users: users ?? this.users,
      branches: branches ?? this.branches,
    );
  }
}

class SessionController extends ChangeNotifier {
  SessionController({
    SessionApiService? apiService,
    SessionPersistenceService? persistenceService,
    LocalStoreService? localStoreService,
  })  : _apiService = apiService ?? SessionApiService(),
        _persistenceService = persistenceService ?? SessionPersistenceService(),
        _localStoreService = localStoreService ?? LocalStoreService() {
    _bootstrap();
  }

  final SessionApiService _apiService;
  final SessionPersistenceService _persistenceService;
  final LocalStoreService _localStoreService;
  AccountProfile? _account;
  bool _isBootstrapping = true;
  bool _setupRequired = false;
  bool _isAuthenticated = false;
  SessionUser? _activeUser;
  SessionBranch? _activeBranch;
  String? _sessionError;
  String? _accessToken;
  String? _businessId;
  PersistedSession? _persistedSession;
  bool _offlineOnly = true;
  List<RememberedAccount> _rememberedAccounts = const [];

  SessionStage get stage {
    if (_isBootstrapping) {
      return SessionStage.loading;
    }
    if (_setupRequired) {
      return SessionStage.setup;
    }
    if (!_isAuthenticated) {
      return SessionStage.login;
    }
    if (_activeBranch == null) {
      return SessionStage.branchSelection;
    }
    if (_activeUser == null) {
      return SessionStage.userSelection;
    }
    return SessionStage.ready;
  }

  AccountProfile? get account => _account;
  List<SessionUser> get allUsers => _account?.users ?? const [];
  List<SessionBranch> get allBranches => _account?.branches ?? const [];
  List<SessionBranch> get branches => allBranches.where((branch) => branch.isActive).toList();
  bool get hasSingleBranch => branches.length <= 1;
  List<SessionUser> get users {
    final branchId = _activeBranch?.id;
    final activeUsers = allUsers.where((user) => user.isActive);
    if (branchId == null) {
      return activeUsers.toList();
    }
    return activeUsers.where((user) => user.branchIds.contains(branchId)).toList();
  }
  SessionUser? get activeUser => _activeUser;
  SessionBranch? get activeBranch => _activeBranch;
  String? get accountName => _account?.accountName ?? 'HorsePOS';
  String? get sessionError => _sessionError;
  bool get canSetupServer => _setupRequired;
  String? get accessToken => _accessToken;
  String? get businessId => _businessId;
  bool get offlineOnly => _offlineOnly;
  List<RememberedAccount> get rememberedAccounts => _rememberedAccounts;

  Future<List<LocalAccessUser>> localUsersForAccount(String email) async {
    final cached = await _localStoreService.readSessionSnapshot(email) ??
        await _localStoreService.readSection(email, 'session');
    if (cached is! Map<String, dynamic>) {
      return const [];
    }
    final usersJson = cached['users'];
    if (usersJson is! List<dynamic>) {
      return const [];
    }
    return usersJson
        .whereType<Map<String, dynamic>>()
        .map(_userFromJson)
        .where((user) => user.isActive && (user.pin?.trim().isNotEmpty ?? false))
        .map(
          (user) => LocalAccessUser(
            id: user.id,
            name: user.name,
            role: user.role,
            initials: user.initials,
            branchIds: user.branchIds,
          ),
        )
        .toList();
  }

  Future<void> setupInitialAccount({
    required String accountName,
    required String ownerEmail,
    required String password,
  }) async {
    _sessionError = null;
    notifyListeners();
    final normalizedAccountName = accountName.trim().isEmpty ? 'P41 Cuenta' : accountName.trim();
    final normalizedEmail = ownerEmail.trim();
    final normalizedPassword = password.trim();
    if (normalizedEmail.isEmpty) {
      _sessionError = 'Completá el email principal.';
      notifyListeners();
      return;
    }
    if (normalizedPassword.isEmpty) {
      _sessionError = 'Completá la clave de acceso.';
      notifyListeners();
      return;
    }
    try {
      if (_offlineOnly) {
        await _createLocalAccount(
          accountName: normalizedAccountName,
          ownerEmail: normalizedEmail,
          password: normalizedPassword,
        );
        return;
      }
      await _apiService.setupAdmin(
        businessName: normalizedAccountName,
        email: normalizedEmail,
        password: normalizedPassword,
      );
      _setupRequired = false;
      await signIn(
        email: normalizedEmail,
        password: normalizedPassword,
      );
    } on SessionApiException catch (error) {
      _sessionError = error.message;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
    bool silent = false,
  }) async {
    final normalizedEmail = email.trim();
    await _refreshRememberedAccounts();
    final hasRememberedAccount = _rememberedAccounts.any(
      (account) => account.email.trim().toLowerCase() == normalizedEmail.toLowerCase(),
    );
    if (!silent) {
      _sessionError = null;
      notifyListeners();
    }
    try {
      debugPrint('SessionController.signIn start -> $normalizedEmail');
      final payload = await _apiService.login(
        email: normalizedEmail,
        password: password,
      );
      debugPrint('SessionController.signIn payload ok -> business=${payload.profile.businessName}');
      _hydrateFromServer(payload, password: password);
      debugPrint('SessionController.signIn hydrated -> users=${allUsers.length} branches=${allBranches.length}');
      _persistedSession = PersistedSession(
        email: normalizedEmail,
        branchId: _activeBranch?.id,
        userId: _activeUser?.id,
      );
      await _persistenceService.save(_persistedSession!);
      await _saveSessionSnapshot();
      await _refreshRememberedAccounts();
      _sessionError = null;
      notifyListeners();
      return true;
    } on SessionApiException catch (error) {
      debugPrint('SessionController.signIn api error -> ${error.message}');
      _sessionError = silent
          ? null
          : (_isConnectivityError(error)
              ? (hasRememberedAccount
                  ? 'Usá la cuenta guardada con PIN o conectate para validar la clave.'
                  : 'Necesitás conexión para validar esta cuenta por primera vez.')
              : error.message);
      notifyListeners();
      return false;
    } catch (error, stackTrace) {
      debugPrint('SessionController.signIn unexpected -> $error');
      debugPrintStack(stackTrace: stackTrace);
      _sessionError = silent
          ? null
          : (_offlineOnly && !hasRememberedAccount
              ? 'No se pudo validar esta cuenta contra el servidor.'
              : 'No se pudo completar el acceso con los datos del servidor');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithLocalPin({
    required String email,
    required String userId,
    required String pin,
  }) async {
    final cached = await _localStoreService.readSessionSnapshot(email) ??
        await _localStoreService.readSection(email, 'session');
    if (cached is! Map<String, dynamic>) {
      _sessionError = 'No se encontró la cuenta en este equipo.';
      notifyListeners();
      return false;
    }

    final accountJson = cached['account'];
    final usersJson = cached['users'];
    final branchesJson = cached['branches'];
    if (accountJson is! Map<String, dynamic> ||
        usersJson is! List<dynamic> ||
        branchesJson is! List<dynamic>) {
      _sessionError = 'No se pudieron leer los datos guardados.';
      notifyListeners();
      return false;
    }

    final users = usersJson.whereType<Map<String, dynamic>>().map(_userFromJson).toList();
    final branches = branchesJson.whereType<Map<String, dynamic>>().map(_branchFromJson).toList();
    SessionUser? selectedUser;
    for (final user in users) {
      if (user.id == userId && user.isActive) {
        selectedUser = user;
        break;
      }
    }
    if (selectedUser == null || selectedUser.pin?.trim() != pin.trim()) {
      _sessionError = 'PIN inválido.';
      notifyListeners();
      return false;
    }

    _account = AccountProfile(
      accountName: accountJson['account_name']?.toString() ?? 'P41',
      ownerEmail: accountJson['owner_email']?.toString() ?? email,
      password: _account?.password ?? '',
      users: users,
      branches: branches,
    );
    _accessToken = 'offline-local';
    _businessId = cached['business_id']?.toString();
    _isAuthenticated = true;

    final activeBranches = branches.where((branch) => branch.isActive).toList();
    SessionBranch? preferredBranch = _preferredBranchFrom(activeBranches);
    if (preferredBranch == null) {
      for (final branch in activeBranches) {
        if (selectedUser.branchIds.contains(branch.id)) {
          preferredBranch = branch;
          break;
        }
      }
    }
    preferredBranch ??= activeBranches.isNotEmpty ? activeBranches.first : null;
    _activeBranch = preferredBranch;
    _activeUser = selectedUser;
    _sessionError = null;
    _persistedSession = PersistedSession(
      email: email.trim(),
      branchId: _activeBranch?.id,
      userId: _activeUser?.id,
    );
    await _persistenceService.save(_persistedSession!);
    _persistSelection();
    notifyListeners();
    return true;
  }

  Future<void> reloadFromLocalStorage() async {
    _account = null;
    _isAuthenticated = false;
    _activeUser = null;
    _activeBranch = null;
    _sessionError = null;
    _accessToken = null;
    _businessId = null;
    _persistedSession = null;
    _rememberedAccounts = const [];
    _isBootstrapping = true;
    notifyListeners();
    await _bootstrap();
  }

  void selectBranch(SessionBranch branch) {
    _activeBranch = branch;
    if (_activeUser != null && !_activeUser!.branchIds.contains(branch.id)) {
      _activeUser = null;
    }
    notifyListeners();
    _persistSelection();
  }

  void selectUser(SessionUser user) {
    _activeUser = user;
    notifyListeners();
    _persistSelection();
  }

  void switchBranch(SessionBranch branch) {
    _activeBranch = branch;
    if (_activeUser != null && !_activeUser!.branchIds.contains(branch.id)) {
      _activeUser = null;
    }
    notifyListeners();
    _persistSelection();
  }

  void switchUser(SessionUser user) {
    _activeUser = user;
    notifyListeners();
    _persistSelection();
  }

  void clearUserSelection() {
    _activeUser = null;
    notifyListeners();
    _persistSelection();
  }

  void clearBranchSelection() {
    _activeBranch = null;
    _activeUser = null;
    notifyListeners();
    _persistSelection();
  }

  void signOut() {
    _isAuthenticated = false;
    _activeBranch = null;
    _activeUser = null;
    _accessToken = null;
    _businessId = null;
    _persistedSession = null;
    _sessionError = null;
    notifyListeners();
    _persistenceService.clear();
  }

  Future<void> createUser({
    required BuildContext context,
    required String name,
    required String role,
    required List<String> branchIds,
    String? pin,
  }) async {
    final account = _account;
    final token = _accessToken;
    if (account == null || token == null) {
      return;
    }
    if (_offlineOnly) {
      final resolvedBranchIds = branchIds.isEmpty
          ? allBranches.where((branch) => branch.isActive).map((branch) => branch.id).toList()
          : branchIds;
      final user = SessionUser(
        id: 'local-user-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        role: role,
        initials: _buildInitials(name),
        branchIds: resolvedBranchIds,
        pin: (pin == null || pin.trim().isEmpty) ? '1234' : pin.trim(),
        isActive: true,
      );
      _account = account.copyWith(users: [...account.users, user]);
      _sessionError = 'Usuario guardado.';
      await _saveSessionSnapshot();
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sessionError!)),
        );
      }
      return;
    }
    try {
      final payload = await _apiService.createStaff(
        token: token,
        name: name,
        role: role,
        pin: (pin == null || pin.trim().isEmpty) ? '1234' : pin.trim(),
      );
      final resolvedBranchIds = branchIds.isEmpty
          ? allBranches.where((branch) => branch.isActive).map((branch) => branch.id).toList()
          : branchIds;
      final user = SessionUser(
        id: payload.id,
        name: payload.name,
        role: _mapRole(payload.role),
        initials: _buildInitials(payload.name),
        branchIds: resolvedBranchIds,
        pin: payload.pin,
        isActive: payload.isActive,
      );
      _account = account.copyWith(
        users: [...account.users, user],
      );
      await _saveSessionSnapshot();
      notifyListeners();
    } on SessionApiException catch (error) {
      if (_isConnectivityError(error)) {
        final resolvedBranchIds = branchIds.isEmpty
            ? allBranches.where((branch) => branch.isActive).map((branch) => branch.id).toList()
            : branchIds;
        final user = SessionUser(
          id: 'local-user-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          role: role,
          initials: _buildInitials(name),
          branchIds: resolvedBranchIds,
          pin: (pin == null || pin.trim().isEmpty) ? '1234' : pin.trim(),
          isActive: true,
        );
        _account = account.copyWith(users: [...account.users, user]);
        await _saveSessionSnapshot();
        _sessionError = 'Usuario guardado.';
        notifyListeners();
      } else {
        _sessionError = error.message;
        notifyListeners();
      }
      if (context.mounted && _sessionError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sessionError!)),
        );
      }
    }
  }

  Future<void> updateUser(SessionUser user, {String? pin}) async {
    final account = _account;
    final token = _accessToken;
    if (account == null || token == null) {
      return;
    }
    if (_offlineOnly) {
      final updatedUser = user.copyWith(pin: pin);
      final updatedUsers = account.users
          .map((item) => item.id == user.id ? updatedUser : item)
          .toList();
      _account = account.copyWith(users: updatedUsers);
      if (_activeUser?.id == user.id) {
        _activeUser = updatedUser.isActive ? updatedUser : null;
      }
      _sessionError = 'Usuario actualizado.';
      await _saveSessionSnapshot();
      notifyListeners();
      return;
    }
    try {
      final payload = await _apiService.updateStaff(
        token: token,
        id: user.id,
        name: user.name,
        role: user.role,
        isActive: user.isActive,
        pin: pin,
      );
      final updatedUser = user.copyWith(
        name: payload.name,
        role: _mapRole(payload.role),
        initials: _buildInitials(payload.name),
        pin: payload.pin,
        isActive: payload.isActive,
      );
      final updatedUsers = account.users
          .map((item) => item.id == user.id ? updatedUser : item)
          .toList();
      _account = account.copyWith(users: updatedUsers);
      if (_activeUser?.id == user.id) {
        _activeUser = updatedUser.isActive ? updatedUser : null;
      }
      await _saveSessionSnapshot();
      notifyListeners();
    } on SessionApiException catch (error) {
      if (_isConnectivityError(error)) {
        final updatedUser = user.copyWith(pin: pin);
        final updatedUsers = account.users
            .map((item) => item.id == user.id ? updatedUser : item)
            .toList();
        _account = account.copyWith(users: updatedUsers);
        if (_activeUser?.id == user.id) {
          _activeUser = updatedUser.isActive ? updatedUser : null;
        }
        await _saveSessionSnapshot();
        _sessionError = 'Usuario actualizado.';
      } else {
        _sessionError = error.message;
      }
      notifyListeners();
    }
  }

  Future<void> createBranch({
    required String name,
    required String label,
  }) async {
    final account = _account;
    final token = _accessToken;
    if (account == null || token == null) {
      return;
    }
    if (_offlineOnly) {
      final branch = SessionBranch(
        id: 'local-branch-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        label: label,
        isActive: true,
      );
      _account = account.copyWith(branches: [...account.branches, branch]);
      _sessionError = 'Local guardado.';
      await _saveSessionSnapshot();
      notifyListeners();
      return;
    }
    try {
      final payload = await _apiService.createBranch(
        token: token,
        name: name,
        label: label,
        isActive: true,
      );
      final branch = SessionBranch(
        id: payload.id,
        name: payload.name,
        label: payload.label,
        isActive: payload.isActive,
      );
      _account = account.copyWith(
        branches: [...account.branches, branch],
      );
      await _saveSessionSnapshot();
      notifyListeners();
    } on SessionApiException catch (error) {
      if (_isConnectivityError(error)) {
        final branch = SessionBranch(
          id: 'local-branch-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          label: label,
          isActive: true,
        );
        _account = account.copyWith(branches: [...account.branches, branch]);
        await _saveSessionSnapshot();
        _sessionError = 'Local guardado.';
      } else {
        _sessionError = error.message;
      }
      notifyListeners();
    }
  }

  Future<void> updateBranch(SessionBranch branch) async {
    final account = _account;
    final token = _accessToken;
    if (account == null || token == null) {
      return;
    }
    if (_offlineOnly) {
      final updatedBranches = account.branches
          .map((item) => item.id == branch.id ? branch : item)
          .toList();
      _account = account.copyWith(branches: updatedBranches);
      if (_activeBranch?.id == branch.id) {
        _activeBranch = branch.isActive ? branch : null;
        if (!branch.isActive) {
          _activeUser = null;
        }
      }
      _sessionError = 'Local actualizado.';
      await _saveSessionSnapshot();
      notifyListeners();
      return;
    }
    try {
      final payload = await _apiService.updateBranch(
        token: token,
        branchId: branch.id,
        name: branch.name,
        label: branch.label,
        isActive: branch.isActive,
      );
      final updatedBranch = branch.copyWith(
        name: payload.name,
        label: payload.label,
        isActive: payload.isActive,
      );
      final updatedBranches = account.branches
          .map((item) => item.id == branch.id ? updatedBranch : item)
          .toList();
      _account = account.copyWith(branches: updatedBranches);
      if (_activeBranch?.id == branch.id) {
        _activeBranch = updatedBranch.isActive ? updatedBranch : null;
        if (!updatedBranch.isActive) {
          _activeUser = null;
        }
      }
      await _saveSessionSnapshot();
      notifyListeners();
    } on SessionApiException catch (error) {
      if (_isConnectivityError(error)) {
        final updatedBranches = account.branches
            .map((item) => item.id == branch.id ? branch : item)
            .toList();
        _account = account.copyWith(branches: updatedBranches);
        if (_activeBranch?.id == branch.id) {
          _activeBranch = branch.isActive ? branch : null;
          if (!branch.isActive) {
            _activeUser = null;
          }
        }
        await _saveSessionSnapshot();
        _sessionError = 'Local actualizado.';
      } else {
        _sessionError = error.message;
      }
      notifyListeners();
    }
  }

  Future<void> renameActiveBranch(String name) async {
    final branch = _activeBranch;
    final token = _accessToken;
    final account = _account;
    if (branch == null || token == null || account == null) {
      return;
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == branch.name) {
      return;
    }
    if (_offlineOnly) {
      final updatedBranch = branch.copyWith(name: trimmed);
      final updatedBranches = account.branches
          .map((item) => item.id == branch.id ? updatedBranch : item)
          .toList();
      _account = account.copyWith(branches: updatedBranches);
      _activeBranch = updatedBranch;
      _sessionError = 'Nombre guardado.';
      await _saveSessionSnapshot();
      notifyListeners();
      return;
    }

    try {
      final payload = await _apiService.updateBranch(
        token: token,
        branchId: branch.id,
        name: trimmed,
        label: branch.label,
        isActive: branch.isActive,
      );
      final updatedBranch = branch.copyWith(
        name: payload.name,
        label: payload.label,
        isActive: payload.isActive,
      );
      final updatedBranches = account.branches
          .map((item) => item.id == branch.id ? updatedBranch : item)
          .toList();
      _account = account.copyWith(branches: updatedBranches);
      _activeBranch = updatedBranch;
      _sessionError = null;
      await _saveSessionSnapshot();
      notifyListeners();
    } on SessionApiException catch (error) {
      if (_isConnectivityError(error)) {
        final updatedBranch = branch.copyWith(name: trimmed);
        final updatedBranches = account.branches
            .map((item) => item.id == branch.id ? updatedBranch : item)
            .toList();
        _account = account.copyWith(branches: updatedBranches);
        _activeBranch = updatedBranch;
        await _saveSessionSnapshot();
        _sessionError = 'Nombre guardado.';
      } else {
        _sessionError = error.message;
      }
      notifyListeners();
    }
  }

  String _buildInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'US';
    }
    if (parts.length == 1) {
      final single = parts.first;
      return single.substring(0, single.length > 1 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _bootstrap() async {
    try {
      await _refreshRememberedAccounts();
      _offlineOnly = await _localStoreService.isOfflineOnly();
      _persistedSession = await _persistenceService.load();
      if (_offlineOnly) {
        _setupRequired = _rememberedAccounts.isEmpty;
        if (_setupRequired) {
          _persistedSession = null;
          await _persistenceService.clear();
        }
        return;
      }
      _setupRequired = await _apiService.checkSetupRequired();
      if (_setupRequired) {
        _persistedSession = null;
        await _persistenceService.clear();
      }
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  void _hydrateFromServer(SessionBootstrapPayload payload, {required String password}) {
    final branches = payload.branches.isEmpty
        ? [
            const SessionBranch(
              id: 'default',
              name: 'Sucursal principal',
              label: 'Pendiente de sincronizacion',
            ),
          ]
        : payload.branches
            .map(
              (branch) => SessionBranch(
                id: branch.id,
                name: branch.name,
                label: branch.label,
                isActive: branch.isActive,
              ),
            )
            .toList();

    final branchIds = branches.map((branch) => branch.id).toList();
    final users = payload.staff.isEmpty
        ? [
            SessionUser(
              id: payload.profile.userId,
              name: payload.profile.displayName,
              role: _mapRole(payload.profile.role),
              initials: _buildInitials(payload.profile.displayName),
              branchIds: branchIds,
            ),
          ]
        : payload.staff
            .map(
              (user) => SessionUser(
                id: user.id,
                name: user.name,
              role: _mapRole(user.role),
              initials: _buildInitials(user.name),
              branchIds: branchIds,
              pin: user.pin,
              isActive: user.isActive,
            ),
            )
            .toList();

    _account = AccountProfile(
      accountName: payload.profile.businessName,
      ownerEmail: payload.profile.email,
      password: password,
      users: users,
      branches: branches,
    );
    _accessToken = payload.auth.token;
    _businessId = payload.profile.businessId;
    _isAuthenticated = true;
    final activeBranches = branches.where((branch) => branch.isActive).toList();
    _activeBranch = _preferredBranchFrom(activeBranches) ??
        (activeBranches.length == 1 ? activeBranches.first : null);
    final availableUsers = _activeBranch == null
        ? users.where((user) => user.isActive).toList()
        : users
            .where((user) => user.isActive && user.branchIds.contains(_activeBranch!.id))
            .toList();
    _activeUser = _preferredUserFrom(availableUsers) ??
        (availableUsers.length == 1 ? availableUsers.first : null);
    _sessionError = null;
  }

  Future<void> _saveSessionSnapshot() async {
    final account = _account;
    if (account == null) {
      return;
    }
    await _localStoreService.saveSessionSnapshot(
      scopeKey: account.ownerEmail,
      ownerEmail: account.ownerEmail,
      accountName: account.accountName,
      accessToken: _accessToken ?? 'offline-local',
      businessId: _businessId,
      users: account.users.map(_userToJson).toList(),
      branches: account.branches.map(_branchToJson).toList(),
    );
    await _refreshRememberedAccounts();
  }

  Future<void> _createLocalAccount({
    required String accountName,
    required String ownerEmail,
    required String password,
  }) async {
    await _refreshRememberedAccounts();
    final normalizedEmail = ownerEmail.trim().toLowerCase();
    final duplicate = _rememberedAccounts.any(
      (account) => account.email.trim().toLowerCase() == normalizedEmail,
    );
    if (duplicate) {
      _sessionError = 'Ya existe una cuenta guardada con ese email en este equipo.';
      notifyListeners();
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final branch = SessionBranch(
      id: 'local-branch-$timestamp',
      name: accountName,
      label: 'Operacion general',
      isActive: true,
    );
    final owner = SessionUser(
      id: 'local-owner-$timestamp',
      name: accountName,
      role: 'Administrador',
      initials: _buildInitials(accountName),
      branchIds: [branch.id],
      pin: password,
      isActive: true,
    );

    _account = AccountProfile(
      accountName: accountName,
      ownerEmail: ownerEmail.trim(),
      password: '',
      users: [owner],
      branches: [branch],
    );
    _accessToken = 'offline-local';
    _businessId = 'local-business-$timestamp';
    _isAuthenticated = true;
    _setupRequired = false;
    _activeBranch = branch;
    _activeUser = owner;
    _sessionError = null;
    _persistedSession = PersistedSession(
      email: ownerEmail.trim(),
      branchId: branch.id,
      userId: owner.id,
    );
    await _persistenceService.save(_persistedSession!);
    await _saveSessionSnapshot();
    notifyListeners();
  }

  Future<void> _refreshRememberedAccounts() async {
    final rawAccounts = await _localStoreService.listRememberedAccounts();
    _rememberedAccounts = rawAccounts
        .map(
          (item) => RememberedAccount(
            scopeKey: item['scope_key'] ?? '',
            email: item['email'] ?? '',
            accountName: item['account_name'] ?? 'Cuenta local',
          ),
        )
        .where((item) => item.scopeKey.isNotEmpty && item.email.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _userToJson(SessionUser user) {
    return {
      'id': user.id,
      'name': user.name,
      'role': user.role,
      'initials': user.initials,
      'branch_ids': user.branchIds,
      'pin': user.pin,
      'is_active': user.isActive,
    };
  }

  SessionUser _userFromJson(Map<String, dynamic> json) {
    final branchIds = (json['branch_ids'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .toList();
    return SessionUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Usuario',
      role: json['role']?.toString() ?? 'Cajero',
      initials: json['initials']?.toString() ?? _buildInitials(json['name']?.toString() ?? 'Usuario'),
      branchIds: branchIds,
      pin: json['pin']?.toString(),
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> _branchToJson(SessionBranch branch) {
    return {
      'id': branch.id,
      'name': branch.name,
      'label': branch.label,
      'is_active': branch.isActive,
    };
  }

  SessionBranch _branchFromJson(Map<String, dynamic> json) {
    return SessionBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sucursal',
      label: json['label']?.toString() ?? 'Operacion general',
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  bool _isConnectivityError(SessionApiException error) {
    if (error.statusCode != null) {
      return false;
    }
    return error.message.contains('No se pudo conectar') ||
        error.message.contains('Tiempo de espera');
  }

  SessionBranch? _preferredBranchFrom(List<SessionBranch> branches) {
    final preferredId = _persistedSession?.branchId;
    if (preferredId == null) {
      return null;
    }
    for (final branch in branches) {
      if (branch.id == preferredId) {
        return branch;
      }
    }
    return null;
  }

  SessionUser? _preferredUserFrom(List<SessionUser> users) {
    final preferredId = _persistedSession?.userId;
    if (preferredId == null) {
      return null;
    }
    for (final user in users) {
      if (user.id == preferredId) {
        return user;
      }
    }
    return null;
  }

  void _persistSelection() {
    final persisted = _persistedSession;
    if (persisted == null) {
      return;
    }
    _persistedSession = persisted.copyWith(
      branchId: _activeBranch?.id,
      userId: _activeUser?.id,
      clearBranchId: _activeBranch == null,
      clearUserId: _activeUser == null,
    );
    _persistenceService.save(_persistedSession!);
  }

  String _mapRole(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
      case 'admin':
        return 'Administrador';
      case 'supervisor':
        return 'Supervisor';
      case 'cashier':
        return 'Cajero';
      default:
        return role;
    }
  }
}
