import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/models/session_context.dart';
import '../../../app/services/cash_api_service.dart';
import '../../../app/services/local_store_service.dart';
import '../../pos/models/sale_models.dart';
import '../models/cash_shift.dart';

class CashController extends ChangeNotifier {
  CashController({
    required String accessToken,
    required SessionBranch initialBranch,
    required String scopeKey,
    CashApiService? apiService,
    LocalStoreService? localStoreService,
  })  : _accessToken = accessToken,
        _activeBranch = initialBranch,
        _scopeKey = scopeKey,
        _apiService = apiService ?? CashApiService(),
        _localStoreService = localStoreService ?? LocalStoreService() {
    unawaited(reload());
  }

  final CashApiService _apiService;
  final LocalStoreService _localStoreService;
  final List<CashShift> _history = [];
  final String _deviceId = 'p41-desktop';
  String _accessToken;
  SessionBranch _activeBranch;
  String _scopeKey;
  bool _isLoading = false;
  String? _errorMessage;
  bool _separateCigarettes = false;

  List<CashShift> get history => List.unmodifiable(_history.reversed);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get separateCigarettes => _separateCigarettes;

  CashShift shiftForBranch(SessionBranch branch) {
    final openShift = _history.lastWhere(
      (shift) =>
          shift.branchId == branch.id &&
          shift.isOpen &&
          shift.registerKind == CashRegisterKind.general,
      orElse: () => CashShift(
        id: 'closed-${branch.id}',
        branchId: branch.id,
        branchName: branch.name,
        registerName: 'Caja',
        registerKind: CashRegisterKind.general,
        status: CashShiftStatus.closed,
      ),
    );
    return openShift;
  }

  CashShift cigaretteShiftForBranch(SessionBranch branch) {
    final openShift = _history.lastWhere(
      (shift) =>
          shift.branchId == branch.id &&
          shift.isOpen &&
          shift.registerKind == CashRegisterKind.cigarettes,
      orElse: () => CashShift(
        id: 'closed-cigarettes-${branch.id}',
        branchId: branch.id,
        branchName: branch.name,
        registerName: 'Caja cigarrillos',
        registerKind: CashRegisterKind.cigarettes,
        status: CashShiftStatus.closed,
      ),
    );
    return openShift;
  }

  List<CashShift> historyForBranch(String branchId) {
    return history.where((shift) => shift.branchId == branchId).toList();
  }

  Future<void> reload() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _restoreSettings();
    if (await _localStoreService.isOfflineOnly()) {
      final restored = await _restoreLocalSnapshot();
      _errorMessage = restored ? null : 'Todavía no hay movimientos de caja.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    try {
      final localCigaretteShifts = _history
          .where((shift) => shift.branchId == _activeBranch.id && shift.registerKind == CashRegisterKind.cigarettes)
          .toList();
      final branchId = int.tryParse(_activeBranch.id);
      final historyPayload = await _apiService.listShifts(
        token: _accessToken,
        branchId: branchId,
      );
      final currentPayload = await _apiService.currentShift(
        token: _accessToken,
        branchId: branchId,
        deviceId: _deviceId,
      );
      _history
        ..clear()
        ..addAll(historyPayload.map((entry) => _shiftFromApi(entry, branchName: _activeBranch.name)));
      _history.addAll(localCigaretteShifts);

      if (currentPayload != null && currentPayload.isNotEmpty) {
        final currentId = currentPayload['id']?.toString();
        Map<String, dynamic>? summary;
        if (currentId != null) {
          summary = await _apiService.shiftSummary(
            token: _accessToken,
            shiftId: currentId,
          );
        }
        final current = _shiftFromApi(
          currentPayload,
          branchName: _activeBranch.name,
          summary: summary,
        );
        final index = _history.indexWhere((shift) => shift.id == current.id);
        if (index == -1) {
          _history.add(current);
        } else {
          _history[index] = current;
        }
      }
      await _saveLocalSnapshot();
    } on CashApiException catch (error) {
      final restored = await _restoreLocalSnapshot();
      _errorMessage = restored ? null : error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSession({
    required String accessToken,
    required SessionBranch activeBranch,
    required String scopeKey,
  }) async {
    final tokenChanged = _accessToken != accessToken;
    final branchChanged = _activeBranch.id != activeBranch.id;
    final scopeChanged = _scopeKey != scopeKey;
    _accessToken = accessToken;
    _activeBranch = activeBranch;
    _scopeKey = scopeKey;
    if (tokenChanged || branchChanged || scopeChanged) {
      await reload();
    }
  }

  Future<void> openShift({
    required SessionBranch branch,
    required SessionUser user,
    required CashRegisterAmounts amounts,
  }) async {
    final current = shiftForBranch(branch);
    if (current.isOpen) {
      return;
    }
    if (await _localStoreService.isOfflineOnly()) {
      _openLocalGeneralShift(branch: branch, user: user, openingAmount: amounts.general);
      if (_separateCigarettes) {
        _openLocalCigaretteShift(branch: branch, user: user, openingAmount: amounts.cigarettes);
      }
      await _saveLocalSnapshot();
      _errorMessage = 'Caja abierta.';
      notifyListeners();
      return;
    }
    try {
      await _apiService.openShift(
        token: _accessToken,
        body: {
          'initial_cash': amounts.general,
          'branch_id': int.tryParse(branch.id),
          if (user.pin != null && user.pin!.trim().isNotEmpty)
            'staff_id': int.tryParse(user.id)
          else
            'user_id': int.tryParse(user.id),
          'device_id': _deviceId,
        },
      );
      if (_separateCigarettes) {
        _openLocalCigaretteShift(branch: branch, user: user, openingAmount: amounts.cigarettes);
      }
      await reload();
      if (_separateCigarettes) {
        await _saveLocalSnapshot();
        notifyListeners();
      }
    } on CashApiException catch (error) {
      _openLocalGeneralShift(branch: branch, user: user, openingAmount: amounts.general);
      if (_separateCigarettes) {
        _openLocalCigaretteShift(branch: branch, user: user, openingAmount: amounts.cigarettes);
      }
      await _saveLocalSnapshot();
      _errorMessage = _isConnectivityError(error)
          ? 'Caja abierta.'
          : error.message;
      notifyListeners();
    }
  }

  Future<void> closeShift({
    required SessionBranch branch,
    required SessionUser user,
    required CashRegisterAmounts amounts,
  }) async {
    final index = _history.lastIndexWhere(
      (shift) =>
          shift.branchId == branch.id &&
          shift.isOpen &&
          shift.registerKind == CashRegisterKind.general,
    );
    if (index == -1) {
      return;
    }
    if (await _localStoreService.isOfflineOnly()) {
      final current = _history[index];
      _history[index] = current.copyWith(
        status: CashShiftStatus.closed,
        countedAmount: amounts.general,
        closedAtLabel: _formatDateTime(DateTime.now().toIso8601String()),
        closedBy: user.name,
      );
      _closeLocalCigaretteShift(branch: branch, user: user, countedAmount: amounts.cigarettes);
      await _saveLocalSnapshot();
      _errorMessage = 'Caja cerrada.';
      notifyListeners();
      return;
    }
    try {
      await _apiService.closeShift(
        token: _accessToken,
        shiftId: _history[index].id,
        countedCash: amounts.general,
      );
      _closeLocalCigaretteShift(branch: branch, user: user, countedAmount: amounts.cigarettes);
      await reload();
      if (_separateCigarettes) {
        await _saveLocalSnapshot();
        notifyListeners();
      }
    } on CashApiException catch (error) {
      final current = _history[index];
      _history[index] = current.copyWith(
        status: CashShiftStatus.closed,
        countedAmount: amounts.general,
        closedAtLabel: _formatDateTime(DateTime.now().toIso8601String()),
        closedBy: user.name,
      );
      _closeLocalCigaretteShift(branch: branch, user: user, countedAmount: amounts.cigarettes);
      await _saveLocalSnapshot();
      _errorMessage = _isConnectivityError(error)
          ? 'Caja cerrada.'
          : error.message;
      notifyListeners();
    }
  }

  void registerSale({
    required SessionBranch branch,
    required SaleTransaction transaction,
  }) {
    final generalIndex = _history.lastIndexWhere(
      (shift) =>
          shift.branchId == branch.id &&
          shift.isOpen &&
          shift.registerKind == CashRegisterKind.general,
    );
    if (generalIndex == -1) {
      return;
    }
    final normalized = transaction.paymentMethod.trim().toLowerCase();
    final isCash = normalized == 'cash' || normalized == 'efectivo';
    final cigaretteRevenue = transaction.items
        .where(_isCigaretteItem)
        .fold<double>(0, (sum, item) => sum + item.revenue);
    final generalRevenue = transaction.total - (_separateCigarettes ? cigaretteRevenue : 0);
    _history[generalIndex] = _applyRevenue(
      _history[generalIndex],
      amount: generalRevenue < 0 ? 0 : generalRevenue,
      isCash: isCash,
    );
    if (_separateCigarettes && cigaretteRevenue > 0) {
      final cigarettesIndex = _history.lastIndexWhere(
        (shift) =>
            shift.branchId == branch.id &&
            shift.isOpen &&
            shift.registerKind == CashRegisterKind.cigarettes,
      );
      if (cigarettesIndex != -1) {
        _history[cigarettesIndex] = _applyRevenue(
          _history[cigarettesIndex],
          amount: cigaretteRevenue,
          isCash: isCash,
        );
      }
    }
    _saveLocalSnapshot();
    notifyListeners();
  }

  Future<void> reverseSale({
    required String branchId,
    required SaleTransaction transaction,
  }) async {
    final normalized = transaction.paymentMethod.trim().toLowerCase();
    final isCash = normalized == 'cash' || normalized == 'efectivo';
    final cigaretteRevenue = transaction.items
        .where(_isCigaretteItem)
        .fold<double>(0, (sum, item) => sum + item.revenue);
    final generalRevenue = transaction.total - (_separateCigarettes ? cigaretteRevenue : 0);

    final generalIndex = _resolveGeneralShiftIndex(branchId: branchId, transaction: transaction);
    if (generalIndex != -1) {
      _history[generalIndex] = _reverseRevenue(
        _history[generalIndex],
        amount: generalRevenue < 0 ? 0 : generalRevenue,
        isCash: isCash,
      );
    }

    if (_separateCigarettes && cigaretteRevenue > 0) {
      final cigarettesIndex = _resolveCigaretteShiftIndex(branchId: branchId);
      if (cigarettesIndex != -1) {
        _history[cigarettesIndex] = _reverseRevenue(
          _history[cigarettesIndex],
          amount: cigaretteRevenue,
          isCash: isCash,
        );
      }
    }

    await _saveLocalSnapshot();
    notifyListeners();
  }

  Future<void> updateSeparateCigarettes(bool value) async {
    _separateCigarettes = value;
    await _localStoreService.writeSection(
      _scopeKey,
      _cashSettingsSection,
      {'separate_cigarettes': value},
    );
    if (value) {
      final generalShift = shiftForBranch(_activeBranch);
      if (generalShift.isOpen) {
        final exists = _history.any(
          (shift) =>
              shift.branchId == _activeBranch.id &&
              shift.isOpen &&
              shift.registerKind == CashRegisterKind.cigarettes,
        );
        if (!exists) {
          _history.add(
            CashShift(
              id: 'local-cigarettes-${DateTime.now().millisecondsSinceEpoch}',
              branchId: _activeBranch.id,
              branchName: _activeBranch.name,
              registerName: 'Caja cigarrillos',
              registerKind: CashRegisterKind.cigarettes,
              status: CashShiftStatus.open,
              openedBy: generalShift.openedBy,
              openedAtLabel: generalShift.openedAtLabel,
              openingAmount: 0,
              expectedAmount: 0,
              cashSalesTotal: 0,
              virtualSalesTotal: 0,
            ),
          );
          await _saveLocalSnapshot();
        }
      }
    } else {
      _history.removeWhere(
        (shift) => shift.branchId == _activeBranch.id && shift.registerKind == CashRegisterKind.cigarettes,
      );
      await _saveLocalSnapshot();
    }
    notifyListeners();
  }

  Future<void> _saveLocalSnapshot() async {
    await _localStoreService.saveCashSnapshot(
      scopeKey: _scopeKey,
      branchId: _activeBranch.id,
      shifts: _history.map(_shiftToJson).toList(),
    );
  }

  Future<bool> _restoreLocalSnapshot() async {
    final shiftsJson = await _localStoreService.readCashSnapshot(
          scopeKey: _scopeKey,
          branchId: _activeBranch.id,
        ) ??
        await _localStoreService.readSection(_scopeKey, _cashShiftsSection);
    if (shiftsJson is! List<dynamic>) {
      return false;
    }
    _history
      ..clear()
      ..addAll(shiftsJson.whereType<Map<String, dynamic>>().map(_shiftFromJson));
    return true;
  }

  Map<String, dynamic> _shiftToJson(CashShift shift) {
    return {
      'id': shift.id,
      'branch_id': shift.branchId,
      'branch_name': shift.branchName,
      'register_name': shift.registerName,
      'register_kind': shift.registerKind.name,
      'status': shift.status == CashShiftStatus.open ? 'open' : 'closed',
      'opened_by': shift.openedBy,
      'opened_at_label': shift.openedAtLabel,
      'opening_amount': shift.openingAmount,
      'expected_amount': shift.expectedAmount,
      'cash_sales_total': shift.cashSalesTotal,
      'virtual_sales_total': shift.virtualSalesTotal,
      'counted_amount': shift.countedAmount,
      'closed_at_label': shift.closedAtLabel,
      'closed_by': shift.closedBy,
    };
  }

  CashShift _shiftFromJson(Map<String, dynamic> json) {
    return CashShift(
      id: json['id']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? _activeBranch.id,
      branchName: json['branch_name']?.toString() ?? _activeBranch.name,
      registerName: json['register_name']?.toString() ?? 'Caja',
      registerKind: (json['register_kind']?.toString() ?? 'general') == 'cigarettes'
          ? CashRegisterKind.cigarettes
          : CashRegisterKind.general,
      status: (json['status']?.toString() ?? 'closed') == 'open'
          ? CashShiftStatus.open
          : CashShiftStatus.closed,
      openedBy: json['opened_by']?.toString(),
      openedAtLabel: json['opened_at_label']?.toString(),
      openingAmount: (json['opening_amount'] as num?)?.toDouble(),
      expectedAmount: (json['expected_amount'] as num?)?.toDouble(),
      cashSalesTotal: (json['cash_sales_total'] as num?)?.toDouble(),
      virtualSalesTotal: (json['virtual_sales_total'] as num?)?.toDouble(),
      countedAmount: (json['counted_amount'] as num?)?.toDouble(),
      closedAtLabel: json['closed_at_label']?.toString(),
      closedBy: json['closed_by']?.toString(),
    );
  }

  bool _isConnectivityError(CashApiException error) {
    return error.statusCode == null &&
        (error.message.contains('No se pudo conectar') || error.message.contains('Tiempo de espera'));
  }

  CashShift _shiftFromApi(
    Map<String, dynamic> json, {
    required String branchName,
    Map<String, dynamic>? summary,
  }) {
    final start = _formatDateTime(json['start_time']?.toString());
    final end = _formatDateTime(json['end_time']?.toString());
    return CashShift(
      id: json['id'].toString(),
      branchId: json['branch_id']?.toString() ?? _activeBranch.id,
      branchName: branchName,
      registerName: 'Caja',
      registerKind: CashRegisterKind.general,
      status: (json['status']?.toString() ?? 'closed') == 'open'
          ? CashShiftStatus.open
          : CashShiftStatus.closed,
      openedBy: json['staff_id']?.toString() ?? json['user_id']?.toString(),
      openedAtLabel: start,
      openingAmount: (json['initial_cash'] as num?)?.toDouble(),
      expectedAmount: (summary?['expected_cash'] as num?)?.toDouble() ?? (json['expected_cash'] as num?)?.toDouble(),
      cashSalesTotal: ((summary?['expected_cash'] as num?)?.toDouble() ?? (json['expected_cash'] as num?)?.toDouble() ?? 0) -
          ((json['initial_cash'] as num?)?.toDouble() ?? 0),
      countedAmount: (json['counted_cash'] as num?)?.toDouble(),
      closedAtLabel: end,
      closedBy: json['staff_id']?.toString() ?? json['user_id']?.toString(),
    );
  }

  String? _formatDateTime(String? value) {
    final date = value == null ? null : DateTime.tryParse(value)?.toLocal();
    if (date == null) {
      return null;
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _restoreSettings() async {
    final stored = await _localStoreService.readSection(_scopeKey, _cashSettingsSection);
    if (stored is Map<String, dynamic>) {
      _separateCigarettes = stored['separate_cigarettes'] == true;
      return;
    }
    _separateCigarettes = false;
  }

  void _openLocalGeneralShift({
    required SessionBranch branch,
    required SessionUser user,
    required double openingAmount,
  }) {
    _history.add(
      CashShift(
        id: 'local-shift-${DateTime.now().millisecondsSinceEpoch}',
        branchId: branch.id,
        branchName: branch.name,
        registerName: 'Caja',
        registerKind: CashRegisterKind.general,
        status: CashShiftStatus.open,
        openedBy: user.name,
        openedAtLabel: _formatDateTime(DateTime.now().toIso8601String()),
        openingAmount: openingAmount,
        expectedAmount: openingAmount,
        cashSalesTotal: 0,
        virtualSalesTotal: 0,
      ),
    );
  }

  void _openLocalCigaretteShift({
    required SessionBranch branch,
    required SessionUser user,
    required double openingAmount,
  }) {
    _history.removeWhere(
      (shift) => shift.branchId == branch.id && shift.registerKind == CashRegisterKind.cigarettes,
    );
    _history.add(
      CashShift(
        id: 'local-cigarettes-${DateTime.now().millisecondsSinceEpoch}',
        branchId: branch.id,
        branchName: branch.name,
        registerName: 'Caja cigarrillos',
        registerKind: CashRegisterKind.cigarettes,
        status: CashShiftStatus.open,
        openedBy: user.name,
        openedAtLabel: _formatDateTime(DateTime.now().toIso8601String()),
        openingAmount: openingAmount,
        expectedAmount: openingAmount,
        cashSalesTotal: 0,
        virtualSalesTotal: 0,
      ),
    );
  }

  void _closeLocalCigaretteShift({
    required SessionBranch branch,
    required SessionUser user,
    required double countedAmount,
  }) {
    final index = _history.lastIndexWhere(
      (shift) =>
          shift.branchId == branch.id &&
          shift.isOpen &&
          shift.registerKind == CashRegisterKind.cigarettes,
    );
    if (index == -1) {
      return;
    }
    final current = _history[index];
    _history[index] = current.copyWith(
      status: CashShiftStatus.closed,
      countedAmount: countedAmount,
      closedAtLabel: _formatDateTime(DateTime.now().toIso8601String()),
      closedBy: user.name,
    );
  }

  CashShift _applyRevenue(
    CashShift shift, {
    required double amount,
    required bool isCash,
  }) {
    final nextCashSales = (shift.cashSalesTotal ?? 0) + (isCash ? amount : 0);
    final nextVirtualSales = (shift.virtualSalesTotal ?? 0) + (isCash ? 0 : amount);
    return shift.copyWith(
      cashSalesTotal: nextCashSales,
      virtualSalesTotal: nextVirtualSales,
      expectedAmount: (shift.openingAmount ?? 0) + nextCashSales,
    );
  }

  CashShift _reverseRevenue(
    CashShift shift, {
    required double amount,
    required bool isCash,
  }) {
    final currentCashSales = shift.cashSalesTotal ?? 0;
    final currentVirtualSales = shift.virtualSalesTotal ?? 0;
    final nextCashSales = isCash ? (currentCashSales - amount).clamp(0, 999999999).toDouble() : currentCashSales;
    final nextVirtualSales = isCash ? currentVirtualSales : (currentVirtualSales - amount).clamp(0, 999999999).toDouble();
    return shift.copyWith(
      cashSalesTotal: nextCashSales,
      virtualSalesTotal: nextVirtualSales,
      expectedAmount: (shift.openingAmount ?? 0) + nextCashSales,
    );
  }

  int _resolveGeneralShiftIndex({
    required String branchId,
    required SaleTransaction transaction,
  }) {
    if (transaction.shiftId.trim().isNotEmpty) {
      final byId = _history.lastIndexWhere(
        (shift) =>
            shift.branchId == branchId &&
            shift.registerKind == CashRegisterKind.general &&
            shift.id == transaction.shiftId,
      );
      if (byId != -1) {
        return byId;
      }
    }
    return _history.lastIndexWhere(
      (shift) => shift.branchId == branchId && shift.registerKind == CashRegisterKind.general,
    );
  }

  int _resolveCigaretteShiftIndex({
    required String branchId,
  }) {
    return _history.lastIndexWhere(
      (shift) => shift.branchId == branchId && shift.registerKind == CashRegisterKind.cigarettes,
    );
  }

  bool _isCigaretteItem(SaleProductBreakdown item) {
    final category = item.category.trim().toLowerCase();
    return category == 'cigarrillos' ||
        category == 'cigarrillo' ||
        category == 'tabaco';
  }

  String get _cashShiftsSection => 'cash_shifts_${_activeBranch.id}';
  String get _cashSettingsSection => 'cash_settings_${_activeBranch.id}';
}
