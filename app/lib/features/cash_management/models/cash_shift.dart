enum CashShiftStatus { closed, open }

enum CashRegisterKind { general, cigarettes }

class CashRegisterAmounts {
  const CashRegisterAmounts({
    required this.general,
    this.cigarettes = 0,
  });

  final double general;
  final double cigarettes;
}

class CashShift {
  const CashShift({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.registerName,
    this.registerKind = CashRegisterKind.general,
    required this.status,
    this.openedBy,
    this.openedAtLabel,
    this.openingAmount,
    this.expectedAmount,
    this.cashSalesTotal,
    this.virtualSalesTotal,
    this.countedAmount,
    this.closedAtLabel,
    this.closedBy,
  });

  final String id;
  final String branchId;
  final String branchName;
  final String registerName;
  final CashRegisterKind registerKind;
  final CashShiftStatus status;
  final String? openedBy;
  final String? openedAtLabel;
  final double? openingAmount;
  final double? expectedAmount;
  final double? cashSalesTotal;
  final double? virtualSalesTotal;
  final double? countedAmount;
  final String? closedAtLabel;
  final String? closedBy;

  bool get isOpen => status == CashShiftStatus.open;
  double? get difference {
    if (countedAmount == null || expectedAmount == null) {
      return null;
    }
    return countedAmount! - expectedAmount!;
  }

  CashShift copyWith({
    String? id,
    String? branchId,
    String? branchName,
    String? registerName,
    CashRegisterKind? registerKind,
    CashShiftStatus? status,
    String? openedBy,
    String? openedAtLabel,
    double? openingAmount,
    double? expectedAmount,
    double? cashSalesTotal,
    double? virtualSalesTotal,
    double? countedAmount,
    String? closedAtLabel,
    String? closedBy,
    bool clearOpenedBy = false,
    bool clearOpenedAtLabel = false,
    bool clearOpeningAmount = false,
    bool clearExpectedAmount = false,
    bool clearCashSalesTotal = false,
    bool clearVirtualSalesTotal = false,
    bool clearCountedAmount = false,
    bool clearClosedAtLabel = false,
    bool clearClosedBy = false,
  }) {
    return CashShift(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      registerName: registerName ?? this.registerName,
      registerKind: registerKind ?? this.registerKind,
      status: status ?? this.status,
      openedBy: clearOpenedBy ? null : openedBy ?? this.openedBy,
      openedAtLabel: clearOpenedAtLabel ? null : openedAtLabel ?? this.openedAtLabel,
      openingAmount: clearOpeningAmount ? null : openingAmount ?? this.openingAmount,
      expectedAmount: clearExpectedAmount ? null : expectedAmount ?? this.expectedAmount,
      cashSalesTotal: clearCashSalesTotal ? null : cashSalesTotal ?? this.cashSalesTotal,
      virtualSalesTotal: clearVirtualSalesTotal ? null : virtualSalesTotal ?? this.virtualSalesTotal,
      countedAmount: clearCountedAmount ? null : countedAmount ?? this.countedAmount,
      closedAtLabel: clearClosedAtLabel ? null : closedAtLabel ?? this.closedAtLabel,
      closedBy: clearClosedBy ? null : closedBy ?? this.closedBy,
    );
  }
}
