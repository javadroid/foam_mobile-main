class WalletModel {
  final double balance;
  final double pendingBalance;
  final String currency;
  final String status;

  WalletModel({
    required this.balance,
    required this.pendingBalance,
    required this.currency,
    required this.status,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (json['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'NGN',
      status: json['status'] ?? 'ACTIVE',
    );
  }
}

class WalletLedgerItem {
  final String id;
  final double amount;
  final String direction; // CREDIT, DEBIT
  final double balanceBefore;
  final double balanceAfter;
  final String type; // DEPOSIT, ORDER_PAYMENT, etc.
  final String status;
  final String reference;
  final String description;
  final DateTime createdAt;

  WalletLedgerItem({
    required this.id,
    required this.amount,
    required this.direction,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.type,
    required this.status,
    required this.reference,
    required this.description,
    required this.createdAt,
  });

  factory WalletLedgerItem.fromJson(Map<String, dynamic> json) {
    return WalletLedgerItem(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      direction: json['direction'] ?? 'CREDIT',
      balanceBefore: (json['balanceBefore'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 'DEPOSIT',
      status: json['status'] ?? 'SUCCESS',
      reference: json['reference'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isCredit => direction == 'CREDIT';
}
