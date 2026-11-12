import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class UsersDirectoryDeskScreen extends StatefulWidget {
  const UsersDirectoryDeskScreen({super.key});

  @override
  State<UsersDirectoryDeskScreen> createState() => _UsersDirectoryDeskScreenState();
}

class _UsersDirectoryDeskScreenState extends State<UsersDirectoryDeskScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  String _searchQuery = "";
  String _riskFilter = "ALL"; // ALL, VERIFIED, BASIC, FROZEN

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final usersMap = admin.users;

    // Convert map to list for filtering and sorting
    final List userList = [];
    usersMap.forEach((mob, u) {
    if (u is Map<String, dynamic>) {
    userList.add(Map<String, dynamic>.from(u)..['mobile'] = mob);
    } else if (u is Map) {
    userList.add(Map<String, dynamic>.from(u)..['mobile'] = mob);
    }
    });

    // Filter Logic
    final filteredList = userList.where((u) {
    final isFrozen = u['isFrozen'] == true || u['is_frozen'] == 1 || u['is_frozen'] == '1';
    final isKyc = u['isKycVerified'] == true || u['is_kyc_verified'] == 1 || u['is_kyc_verified'] == '1';

    if (_riskFilter == "VERIFIED" && !isKyc) return false;
    if (_riskFilter == "BASIC" && (isKyc || isFrozen)) return false;
    if (_riskFilter == "FROZEN" && !isFrozen) return false;

    if (_searchQuery.isNotEmpty) {
    final q = _searchQuery.toLowerCase();
    final name = (u['name'] ?? '').toString().toLowerCase();
    final mob = (u['mobile'] ?? '').toString().toLowerCase();
    final cnic = (u['cnic'] ?? '').toString().toLowerCase();
    final email = (u['email'] ?? '').toString().toLowerCase();
    return name.contains(q) || mob.contains(q) || cnic.contains(q) || email.contains(q);
    }
    return true;
    }).toList();

    // Metrics
    int verifiedCount = 0;
    int frozenCount = 0;
    double totalSystemCash = 0.0;
    double totalSystemCrypto = 0.0;

    for (var u in userList) {
    final isKyc = u['isKycVerified'] == true || u['is_kyc_verified'] == 1;
    final isFrozen = u['isFrozen'] == true || u['is_frozen'] == 1;
    final bal = double.tryParse(u['balance']?.toString() ?? '0') ?? 0.0;
    final crypto = double.tryParse(u['crypto']?.toString() ?? '0') ?? 0.0;

    totalSystemCash += bal;
    totalSystemCrypto += crypto;
    if (isKyc) verifiedCount++;
    if (isFrozen) frozenCount++;
    }

    return Padding(
    padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Header Bar
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    "Master User Directory & Security Controller",
    style: TextStyle(
    color: Color(0xFF0F172A),
    fontSize: isDesktop ? 22 : 18,
    fontWeight: FontWeight.w700,
    ),
    ),
    const SizedBox(height: 4),
    const Text(
    "360° customer inspector, compliance locks, asset adjustments, and MPIN overrides",
    style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
    ),
    ],
    ),
    ),
    ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
    backgroundColor: AppConstants.accentGreen,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: () => admin.fetchAllData(),
    icon: const Icon(Icons.sync_rounded, size: 18),
    label: const Text("Sync Directory", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    ),
    ],
    ),
    const SizedBox(height: 20),

    // Metric Badges
    Wrap(
    spacing: 14,
    runSpacing: 10,
    children: [
    _buildMetricCard("TOTAL ACCOUNTS", "${userList.length} Registered", AppConstants.accentBlue, isDesktop),
    _buildMetricCard("TIER-2 VERIFIED", "$verifiedCount Verified", AppConstants.accentGreen, isDesktop),
    _buildMetricCard("TOTAL WALLET CASH", "₨ ${_currencyFormat.format(totalSystemCash)}", AppConstants.accentGold, isDesktop),
    _buildMetricCard("FROZEN ACCOUNTS", "$frozenCount Locked", frozenCount > 0 ? AppConstants.dangerRed : AppConstants.textMuted, isDesktop),
    ],
    ),
    const SizedBox(height: 20),

    // Filters & Search
    Wrap(
    spacing: 12,
    runSpacing: 10,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
    SizedBox(
    width: isDesktop ? 340 : double.infinity,
    child: TextField(
    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
    decoration: InputDecoration(
    hintText: "Search Mobile, Name, CNIC, Email...",
    hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 12.5),
    prefixIcon: const Icon(Icons.search_rounded, color: AppConstants.textMuted, size: 20),
    filled: true,
    fillColor: AppConstants.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
    onChanged: (val) => setState(() => _searchQuery = val.trim()),
    ),
    ),
    _buildFilterChip("ALL", "All Accounts (${userList.length})"),
    _buildFilterChip("VERIFIED", "Tier-2 Verified ($verifiedCount)"),
    _buildFilterChip("BASIC", "Tier-1 Basic"),
    _buildFilterChip("FROZEN", "Locked / Frozen ($frozenCount)"),
    ],
    ),
    const SizedBox(height: 18),

    // Content Desk
    Expanded(
    child: filteredList.isEmpty
    ? const Center(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.people_alt_outlined, size: 54, color: AppConstants.textMuted),
    SizedBox(height: 12),
    Text(
    "No customer accounts found matching criteria",
    style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.bold),
    ),
    ],
    ),
    )
        : isDesktop
    ? _buildDesktopTable(filteredList, admin)
        : _buildMobileCards(filteredList, admin),
    ),
    ],
    ),
    );
    }

  Widget _buildMetricCard(String title, String value, Color color, bool isDesktop) {
    return Container(
      width: isDesktop ? 220 : 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppConstants.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _riskFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppConstants.accentGreen,
      backgroundColor: AppConstants.surface,
      labelStyle: TextStyle(
        color: isSelected ? Color(0xFF021A13) : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? AppConstants.accentGreen : Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() => _riskFilter = key),
    );
  }

  Widget _buildDesktopTable(List list, AdminProvider admin) {
  return Container(
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: Color(0xFFE2E8F0)),
  ),
  child: ClipRRect(
  borderRadius: BorderRadius.circular(18),
  child: SingleChildScrollView(
  scrollDirection: Axis.vertical,
  child: SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: DataTable(
  headingRowColor: WidgetStateProperty.all(AppConstants.surfaceCard),
  dataRowColor: WidgetStateProperty.all(Colors.transparent),
  horizontalMargin: 20,
  columnSpacing: 26,
  columns: const [
  DataColumn(label: Text("CUSTOMER PROFILE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("CNIC IDENTITY", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("RISK TIER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("CASH BALANCE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("CRYPTO (USDT)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("GOLD (24K)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("SECURITY & INSPECT", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((u) {
  final mob = (u['mobile'] ?? '').toString();
  final name = (u['name'] ?? 'Customer').toString();
  final email = (u['email'] ?? '').toString();
  final cnic = (u['cnic'] ?? 'Pending').toString();

  final bal = double.tryParse(u['balance']?.toString() ?? '0') ?? 0.0;
  final crypto = double.tryParse(u['crypto']?.toString() ?? '0') ?? 0.0;
  final gold = double.tryParse(u['goldGrams']?.toString() ?? u['gold_grams']?.toString() ?? '0') ?? 0.0;

  final isFrozen = u['isFrozen'] == true || u['is_frozen'] == 1;
  final isKyc = u['isKycVerified'] == true || u['is_kyc_verified'] == 1;

  return DataRow(
  cells: [
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13.5)),
  Text(mob, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
  if (email.isNotEmpty)
  Text(email, style: const TextStyle(color: AppConstants.accentGreen, fontSize: 10.5, fontWeight: FontWeight.w600)),
  ],
  ),
  ),
  DataCell(Text(cnic, style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'monospace', fontSize: 12))),
  DataCell(_buildRiskTierBadge(isKyc, isFrozen)),
  DataCell(
  Text(
  "₨ ${_currencyFormat.format(bal)}",
  style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w700, fontSize: 14),
  ),
  ),
  DataCell(
  Text(
  "\$ ${crypto.toStringAsFixed(2)}",
  style: const TextStyle(color: Color(0xFFF3BA2F), fontWeight: FontWeight.w800, fontSize: 13),
  ),
  ),
  DataCell(
  Text(
  "${gold.toStringAsFixed(3)} g",
  style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w800, fontSize: 13),
  ),
  ),
  DataCell(
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: AppConstants.accentGreen,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  onPressed: () => _openUser360InspectModal(context, mob, admin),
  icon: const Icon(Icons.remove_red_eye_rounded, size: 14),
  label: const Text("360° Inspect", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
  ),
  ),
  ],
  );
  }).toList(),
  ),
  ),
  ),
  ),
  );
  }

  Widget _buildMobileCards(List list, AdminProvider admin) {
  return ListView.builder(
  itemCount: list.length,
  itemBuilder: (context, idx) {
  final u = list[idx];
  final mob = (u['mobile'] ?? '').toString();
  final name = (u['name'] ?? 'Customer').toString();
  final email = (u['email'] ?? '').toString();
  final cnic = (u['cnic'] ?? 'Pending').toString();

  final bal = double.tryParse(u['balance']?.toString() ?? '0') ?? 0.0;
  final crypto = double.tryParse(u['crypto']?.toString() ?? '0') ?? 0.0;
  final gold = double.tryParse(u['goldGrams']?.toString() ?? u['gold_grams']?.toString() ?? '0') ?? 0.0;

  final isFrozen = u['isFrozen'] == true || u['is_frozen'] == 1;
  final isKyc = u['isKycVerified'] == true || u['is_kyc_verified'] == 1;

  return Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: isFrozen ? AppConstants.dangerRed.withValues(alpha: 0.3) : Color(0xFFE2E8F0)),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 14)),
  Text(mob, style: const TextStyle(color: AppConstants.accentBlue, fontFamily: 'monospace', fontSize: 11.5)),
  ],
  ),
  _buildRiskTierBadge(isKyc, isFrozen),
  ],
  ),
  if (email.isNotEmpty) ...[
  const SizedBox(height: 2),
  Text(email, style: const TextStyle(color: AppConstants.accentGreen, fontSize: 11)),
  ],
  const Divider(color: Color(0xFFE2E8F0), height: 18),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text("Cash Balance", style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5)),
  Text("₨ ${_currencyFormat.format(bal)}", style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w700, fontSize: 14)),
  ],
  ),
  Column(
  children: [
  const Text("USDT Crypto", style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5)),
  Text("\$ ${crypto.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFF3BA2F), fontWeight: FontWeight.bold, fontSize: 13)),
  ],
  ),
  Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
  const Text("Gold Vault", style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5)),
  Text("${gold.toStringAsFixed(3)} g", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 13)),
  ],
  ),
  ],
  ),
  const SizedBox(height: 12),
  SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: AppConstants.accentGreen,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 9),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  onPressed: () => _openUser360InspectModal(context, mob, admin),
  icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
  label: const Text("360° Inspect & Control Account", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
  ),
  ),
  ],
  ),
  );
  },
  );
  }

  Widget _buildRiskTierBadge(bool isKyc, bool isFrozen) {
  if (isFrozen) {
  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(color: AppConstants.dangerRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
  child: const Text("LOCKED / FROZEN", style: TextStyle(color: AppConstants.dangerRed, fontSize: 10, fontWeight: FontWeight.w700)),
  );
  }
  if (isKyc) {
  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(color: AppConstants.accentGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
  child: const Text("TIER-2 VIP VERIFIED", style: TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w700)),
  );
  }
  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
  child: const Text("TIER-1 BASIC", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w700)),
  );
  }

  // =========================================================================
  // 360° USER ACCOUNT INSPECTOR & EXECUTIVE CONTROL MODAL
  // =========================================================================
  void _openUser360InspectModal(BuildContext context, String mobile, AdminProvider admin) {
  final user = admin.users[mobile];
  if (user == null) return;

  final isFrozen = user['isFrozen'] == true || user['is_frozen'] == 1;
  final isKyc = user['isKycVerified'] == true || user['is_kyc_verified'] == 1;
  final cleanMob = mobile.replaceAll(RegExp(r'[^0-9]'), '');
  final iban = "PK76NEXP${cleanMob.length >= 10 ? cleanMob.substring(1) : "0000000000"}01";

  final bal = double.tryParse(user['balance']?.toString() ?? '0') ?? 0.0;
  final crypto = double.tryParse(user['crypto']?.toString() ?? '0') ?? 0.0;
  final gold = double.tryParse(user['goldGrams']?.toString() ?? user['gold_grams']?.toString() ?? '0') ?? 0.0;
  final txs = (user['transactions'] is List) ? List<dynamic>.from(user['transactions']) : [];

  showDialog(
  context: context,
  builder: (ctx) => StatefulBuilder(
  builder: (ctx, setModalState) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text("${user['name'] ?? 'Customer'}", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
  const SizedBox(height: 2),
  Text("IBAN: $iban • Mobile: $mobile", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11, fontFamily: 'monospace')),
  ],
  ),
  _buildRiskTierBadge(isKyc, isFrozen),
  ],
  ),
  content: Container(
  constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
  child: SingleChildScrollView(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  // Balances Row
  Row(
  children: [
  Expanded(
  child: Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(color: AppConstants.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: Color(0xFFE2E8F0))),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text("CASH WALLET", style: TextStyle(color: AppConstants.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
  const SizedBox(height: 4),
  Text("₨ ${_currencyFormat.format(bal)}", style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w700, fontSize: 16)),
  ],
  ),
  ),
  ),
  const SizedBox(width: 8),
  Expanded(
  child: Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(color: AppConstants.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: Color(0xFFE2E8F0))),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text("CRYPTO (USDT)", style: TextStyle(color: AppConstants.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
  const SizedBox(height: 4),
  Text("\$ ${crypto.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFF3BA2F), fontWeight: FontWeight.w700, fontSize: 16)),
  ],
  ),
  ),
  ),
  const SizedBox(width: 8),
  Expanded(
  child: Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(color: AppConstants.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: Color(0xFFE2E8F0))),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text("24K GOLD BULLION", style: TextStyle(color: AppConstants.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
  const SizedBox(height: 4),
  Text("${gold.toStringAsFixed(3)} g", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w700, fontSize: 16)),
  ],
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 18),

  // Management & Security Control Bar
  Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
  color: AppConstants.dangerRed.withValues(alpha: 0.05),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppConstants.dangerRed.withValues(alpha: 0.25)),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text("⚠️ SECURITY, MPIN & COMPLIANCE TOOLS", style: TextStyle(color: AppConstants.dangerRed, fontSize: 11, fontWeight: FontWeight.w700)),
  const SizedBox(height: 10),
  Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
  // Freeze / Unfreeze
  ElevatedButton(
  style: ElevatedButton.styleFrom(
  backgroundColor: isFrozen ? AppConstants.accentGreen : AppConstants.dangerRed,
  foregroundColor: isFrozen ? Color(0xFF021A13) : Color(0xFF0F172A),
  ),
  onPressed: () => _toggleFreezeUser(ctx, mobile, isFrozen, user, admin),
  child: Text(isFrozen ? "🔓 Unfreeze Account" : "🔒 Freeze Account", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
  ),

  // Reset Device Trust
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.withValues(alpha: 0.15), foregroundColor: Colors.amber),
  onPressed: () => _resetDeviceTrust(ctx, mobile, admin),
  child: const Text("📱 Reset Device (Force OTP)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
  ),

  // Reset / Wipe KYC
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed.withValues(alpha: 0.15), foregroundColor: AppConstants.dangerRed),
  onPressed: () => _resetUserKyc(ctx, mobile, admin),
  child: const Text("🔄 Wipe KYC (Allow Re-KYC)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
  ),

  // Override MPIN
  OutlinedButton(
  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
  onPressed: () => _promptOverrideMpin(ctx, mobile, user, admin),
  child: const Text("🔑 Reset 4-Digit MPIN", style: TextStyle(fontSize: 11.5)),
  ),

  // Update Gmail
  OutlinedButton(
  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
  onPressed: () => _promptUpdateEmail(ctx, mobile, user, admin),
  child: const Text("📧 Update Gmail", style: TextStyle(fontSize: 11.5)),
  ),

  // Adjust Cash Balance
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.surfaceCard, foregroundColor: AppConstants.accentGreen),
  onPressed: () => _promptAdjustBalance(ctx, mobile, 'cash', bal, admin),
  child: const Text("± Edit Cash", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
  ),

  // Adjust Crypto Balance
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.surfaceCard, foregroundColor: Color(0xFFF3BA2F)),
  onPressed: () => _promptAdjustBalance(ctx, mobile, 'crypto', crypto, admin),
  child: const Text("± Edit USDT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
  ),

  // Adjust Gold Balance
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.surfaceCard, foregroundColor: Color(0xFFFBBF24)),
  onPressed: () => _promptAdjustBalance(ctx, mobile, 'gold', gold, admin),
  child: const Text("± Edit Gold", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
  ),
  ],
  ),
  ],
  ),
  ),
  const SizedBox(height: 18),

  // Live Passbook & Transactions Ledger
  const Text("📜 LIVE ACCOUNT PASSBOOK & LEDGER (WITH 1-CLICK DISPUTE RECALL)", style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w700)),
  const SizedBox(height: 8),
  Container(
  height: 220,
  decoration: BoxDecoration(color: AppConstants.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: Color(0xFFE2E8F0))),
  child: txs.isEmpty
  ? const Center(child: Text("No transaction history recorded for this account.", style: TextStyle(color: AppConstants.textMuted, fontSize: 12)))
      : ListView.separated(
  itemCount: txs.length,
  separatorBuilder: (_, __) => const Divider(color: Color(0xFFE2E8F0), height: 1),
  itemBuilder: (c, idx) {
  final t = txs[idx];
  final amt = double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0;
  final isDebit = amt < 0;
  final tid = (t['tid'] ?? 'TRX').toString();

  return ListTile(
  dense: true,
  title: Text(t['title'] ?? 'Transaction', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12)),
  subtitle: Text("${t['date'] ?? '-'} • TID: $tid • ${t['dest'] ?? '-'}", style: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5)),
  trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
  Text(
  "${isDebit ? '-' : '+'} ₨ ${_currencyFormat.format(amt.abs())}",
  style: TextStyle(color: isDebit ? AppConstants.dangerRed : AppConstants.accentGreen, fontWeight: FontWeight.w700, fontSize: 13),
  ),
  if (isDebit) ...[
  const SizedBox(width: 8),
  OutlinedButton(
  style: OutlinedButton.styleFrom(
  foregroundColor: Colors.amber,
  side: const BorderSide(color: Colors.amber),
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  visualDensity: VisualDensity.compact,
  ),
  onPressed: () => _executeOneClickReversal(ctx, mobile, tid, amt.abs(), admin),
  child: const Text("↩ Reverse", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
  ),
  ],
  ],
  ),
  );
  },
  ),
  ),
  ],
  ),
  ),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Color(0xFF64748B)))),
  ],
  ),
  ),
  );
  }

  // Toggle Freeze
  Future<void> _toggleFreezeUser(BuildContext ctx, String mobile, bool isCurrentlyFrozen, Map<String, dynamic> user, AdminProvider admin) async {
  Navigator.pop(ctx);
  final newState = !isCurrentlyFrozen;

  final userCopy = Map<String, dynamic>.from(user);
  userCopy['isFrozen'] = newState;

  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'save_all'},
  data: {
  'users': {mobile: userCopy}
  },
  );
  if (res.data['status'] == 'success') {
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text(newState ? "✓ Account $mobile has been FROZEN." : "✓ Account $mobile has been RESTORED.", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }
  }
  } catch (_) {}
  }

  // Reset Device Trust
  Future<void> _resetDeviceTrust(BuildContext ctx, String mobile, AdminProvider admin) async {
  Navigator.pop(ctx);
  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'admin_reset_device'},
  data: {'mobile': mobile},
  );
  if (res.data['status'] == 'success') {
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(backgroundColor: AppConstants.accentGreen, content: Text("✓ ${res.data['message']}", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold))),
  );
  }
  }
  } catch (_) {}
  }

  // Reset / Wipe KYC
  Future<void> _resetUserKyc(BuildContext ctx, String mobile, AdminProvider admin) async {
  Navigator.pop(ctx);
  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'admin_reset_kyc'},
  data: {'mobile': mobile},
  );
  if (res.data['status'] == 'success') {
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(backgroundColor: AppConstants.accentGreen, content: Text("✓ ${res.data['message']}", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold))),
  );
  }
  }
  } catch (_) {}
  }

  // Override MPIN
  void _promptOverrideMpin(BuildContext ctx, String mobile, Map<String, dynamic> user, AdminProvider admin) {
  Navigator.pop(ctx);
  final controller = TextEditingController();

  showDialog(
  context: context,
  builder: (dCtx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: Text("Override 4-Digit MPIN ($mobile)", style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16)),
  content: TextField(
  controller: controller,
  keyboardType: TextInputType.number,
  maxLength: 4,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 6),
  decoration: InputDecoration(
  hintText: "••••",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text("Cancel")),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: Colors.white),
  onPressed: () async {
  final pin = controller.text.trim();
  if (pin.length != 4) return;
  Navigator.pop(dCtx);

  final userCopy = Map<String, dynamic>.from(user);
  userCopy['mpin'] = pin;

  await _api.dio.post(
  '',
  queryParameters: {'action': 'save_all'},
  data: {
  'users': {mobile: userCopy}
  },
  );
  await admin.fetchAllData();
  },
  child: const Text("Save MPIN"),
  ),
  ],
  ),
  );
  }

  // Update Email
  void _promptUpdateEmail(BuildContext ctx, String mobile, Map<String, dynamic> user, AdminProvider admin) {
  Navigator.pop(ctx);
  final controller = TextEditingController(text: user['email'] ?? '');

  showDialog(
  context: context,
  builder: (dCtx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: Text("Update Linked Gmail ($mobile)", style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16)),
  content: TextField(
  controller: controller,
  style: const TextStyle(color: Color(0xFF0F172A)),
  decoration: InputDecoration(
  hintText: "customer@gmail.com",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text("Cancel")),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: Colors.white),
  onPressed: () async {
  final email = controller.text.trim();
  if (!email.contains('@')) return;
  Navigator.pop(dCtx);

  final userCopy = Map<String, dynamic>.from(user);
  userCopy['email'] = email;

  await _api.dio.post(
  '',
  queryParameters: {'action': 'save_all'},
  data: {
  'users': {mobile: userCopy}
  },
  );
  await admin.fetchAllData();
  },
  child: const Text("Save Gmail"),
  ),
  ],
  ),
  );
  }

  // Adjust Balances (Cash, Crypto, Gold)
  void _promptAdjustBalance(BuildContext ctx, String mobile, String type, double currentVal, AdminProvider admin) {
  Navigator.pop(ctx);
  final controller = TextEditingController();

  showDialog(
  context: context,
  builder: (dCtx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: Text("Adjust ${type.toUpperCase()} ($mobile)", style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16)),
  content: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text("Current: $currentVal", style: const TextStyle(color: AppConstants.textMuted, fontSize: 12)),
  const SizedBox(height: 10),
  TextField(
  controller: controller,
  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
  style: const TextStyle(color: Color(0xFF0F172A)),
  decoration: InputDecoration(
  hintText: "e.g. 500 or -200",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ],
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text("Cancel")),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: Colors.white),
  onPressed: () async {
  final delta = double.tryParse(controller.text) ?? 0.0;
  if (delta == 0.0) return;
  Navigator.pop(dCtx);

  if (type == 'cash') {
  await _api.dio.post(
  '',
  queryParameters: {'action': 'adjust_balance'},
  data: {'mobile': mobile, 'amount': delta},
  );
  } else {
  final userRaw = admin.users[mobile];
  if (userRaw != null) {
  final userCopy = Map<String, dynamic>.from(userRaw);
  if (type == 'crypto') {
  userCopy['crypto'] = (double.tryParse(userCopy['crypto']?.toString() ?? '0') ?? 0.0) + delta;
  } else if (type == 'gold') {
  userCopy['goldGrams'] = (double.tryParse(userCopy['goldGrams']?.toString() ?? '0') ?? 0.0) + delta;
  }
  await _api.dio.post(
  '',
  queryParameters: {'action': 'save_all'},
  data: {
  'users': {mobile: userCopy}
  },
  );
  }
  }
  await admin.fetchAllData();
  },
  child: const Text("Update Balance"),
  ),
  ],
  ),
  );
  }

  // 1-Click Ledger Dispute Reversal
  Future<void> _executeOneClickReversal(BuildContext ctx, String mobile, String tid, double amount, AdminProvider admin) async {
  Navigator.pop(ctx);
  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'reverse_transaction'},
  data: {
  'senderMobile': mobile,
  'tid': tid,
  'amount': amount,
  'recipientMobile': '',
  },
  );
  if (res.data['status'] == 'success') {
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(backgroundColor: AppConstants.accentGreen, content: Text("✓ Reversal executed! ₨ ${_currencyFormat.format(amount)} refunded to $mobile.", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold))),
  );
  }
  }
  } catch (_) {}
  }
}
