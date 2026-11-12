class PayoutModel {
  final int id;
  final String tid;
  final String senderMobile;
  final String senderName;
  final String targetBank;
  final String beneficiaryTitle;
  final String beneficiaryAccount;
  final double amount;
  final String status;
  final String? processedBy;
  final String createdAt;

  PayoutModel({
    required this.id,
    required this.tid,
    required this.senderMobile,
    required this.senderName,
    required this.targetBank,
    required this.beneficiaryTitle,
    required this.beneficiaryAccount,
    required this.amount,
    required this.status,
    this.processedBy,
    required this.createdAt,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tid: json['tid']?.toString() ?? '',
      senderMobile: json['sender_mobile']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'Customer',
      targetBank: json['target_bank']?.toString() ?? 'Bank',
      beneficiaryTitle: json['beneficiary_title']?.toString() ?? '-',
      beneficiaryAccount: json['beneficiary_account']?.toString() ?? '-',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      processedBy: json['processed_by']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class DepositModel {
  final int id;
  final String userMobile;
  final String userName;
  final double amount;
  final String channel;
  final String status;
  final String createdAt;

  DepositModel({
    required this.id,
    required this.userMobile,
    required this.userName,
    required this.amount,
    required this.channel,
    required this.status,
    required this.createdAt,
  });

  factory DepositModel.fromJson(Map<String, dynamic> json) {
    return DepositModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userMobile: json['user_mobile']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Customer',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      channel: json['channel']?.toString() ?? 'Gateway',
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}