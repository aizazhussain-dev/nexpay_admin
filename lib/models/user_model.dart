class UserModel {
  final int id;
  final String name;
  final String mobile;
  final String email;
  final String cnic;
  final String address;
  final double balance;
  final double crypto;
  final double goldGrams;
  final double sent;
  final double received;
  final double savings;
  final double vaultBalance;
  final bool isKycVerified;
  final String kycStatus;
  final bool isFrozen;
  final String riskTier;
  final String? trustedDevice;
  final Map<String, dynamic>? kycDocs;
  final List<dynamic> transactions;
  final String registeredAt;

  UserModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.cnic,
    required this.address,
    required this.balance,
    required this.crypto,
    required this.goldGrams,
    required this.sent,
    required this.received,
    required this.savings,
    required this.vaultBalance,
    required this.isKycVerified,
    required this.kycStatus,
    required this.isFrozen,
    required this.riskTier,
    this.trustedDevice,
    this.kycDocs,
    required this.transactions,
    required this.registeredAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? defaultMobile}) {
    return UserModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Customer',
      mobile: json['mobile']?.toString() ?? defaultMobile ?? '',
      email: json['email']?.toString() ?? '',
      cnic: json['cnic']?.toString() ?? '',
      address: json['address']?.toString() ?? 'Not Recorded',
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      crypto: double.tryParse(json['crypto']?.toString() ?? '0') ?? 0.0,
      goldGrams: double.tryParse(json['goldGrams']?.toString() ?? json['gold_grams']?.toString() ?? '0') ?? 0.0,
      sent: double.tryParse(json['sent']?.toString() ?? '0') ?? 0.0,
      received: double.tryParse(json['received']?.toString() ?? '0') ?? 0.0,
      savings: double.tryParse(json['savings']?.toString() ?? '0') ?? 0.0,
      vaultBalance: double.tryParse(json['vaultBalance']?.toString() ?? json['vault_balance']?.toString() ?? '0') ?? 0.0,
      isKycVerified: json['isKycVerified'] == true || json['is_kyc_verified'] == 1 || json['is_kyc_verified'] == '1',
      kycStatus: json['kycStatus']?.toString() ?? json['kyc_status']?.toString() ?? 'PENDING',
      isFrozen: json['isFrozen'] == true || json['is_frozen'] == 1 || json['is_frozen'] == '1',
      riskTier: json['riskTier']?.toString() ?? json['risk_tier']?.toString() ?? 'TIER 1',
      trustedDevice: json['trusted_device']?.toString(),
      kycDocs: json['kycDocuments'] is Map ? json['kycDocuments'] : (json['kycDocs'] is Map ? json['kycDocs'] : null),
      transactions: json['transactions'] is List ? json['transactions'] : [],
      registeredAt: json['registeredAt']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }
}