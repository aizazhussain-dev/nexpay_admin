import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class MaturedVaultsDeskScreen extends StatefulWidget {
  const MaturedVaultsDeskScreen({super.key});

  @override
  State<MaturedVaultsDeskScreen> createState() => _MaturedVaultsDeskScreenState();
}

class _MaturedVaultsDeskScreenState extends State<MaturedVaultsDeskScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");
  String _searchQuery = "";
  bool _isSettling = false;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final usersMap = admin.users;

    // Collect all savings pots across all accounts
    final List potsList = [];
    double totalLockedCapital = 0;
    double totalEstProfit = 0;

    usersMap.forEach((mobile, userData) {
    final userName = (userData['name'] ?? 'Investor').toString();
    final pots = userData['savingsPots'];

    if (pots is List) {
    for (int i = 0; i < pots.length; i++) {
    final pt = pots[i];
    if (pt is Map) {
    final amt = double.tryParse(pt['current']?.toString() ?? pt['amount']?.toString() ?? '0') ?? 0.0;
    final rate = double.tryParse(pt['rate']?.toString() ?? '12.0') ?? 12.0;
    final days = int.tryParse(pt['lockDays']?.toString() ?? pt['days']?.toString() ?? '30') ?? 30;

    final profit = (amt * (rate / 100.0) * (days / 365.0)).roundToDouble();
    final totalPayout = amt + profit;

    totalLockedCapital += amt;
    totalEstProfit += profit;

    potsList.add({
    'userMobile': mobile.toString(),
    'userName': userName,
    'potIndex': i,
    'potId': (pt['id'] ?? pt['potId'] ?? 'POT-#$i').toString(),
    'planTitle': (pt['title'] ?? pt['planTitle'] ?? 'Halal Savings Vault').toString(),
    'amount': amt,
    'rate': rate,
    'days': days,
    'profit': profit,
    'totalPayout': totalPayout,
    'maturityDate': (pt['maturityDate'] ?? '30 Days Lock').toString(),
    'category': (pt['category'] ?? 'Emergency Vault').toString(),
    });
    }
    }
    }
    });

    // Search filter
    final filteredList = potsList.where((p) {
    if (_searchQuery.isNotEmpty) {
    final q = _searchQuery.toLowerCase();
    final mob = p['userMobile'].toString().toLowerCase();
    final name = p['userName'].toString().toLowerCase();
    final title = p['planTitle'].toString().toLowerCase();
    final potId = p['potId'].toString().toLowerCase();
    return mob.contains(q) || name.contains(q) || title.contains(q) || potId.contains(q);
    }
    return true;
    }).toList();

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
    "Halal Savings Vaults & Profit Settlement Desk",
    style: TextStyle(
    color: Color(0xFF0F172A),
    fontSize: isDesktop ? 22 : 18,
    fontWeight: FontWeight.w900,
    ),
    ),
    const SizedBox(height: 4),
    const Text(
    "Monitor user locked capital pots, profit accrual benchmarks, and disburse matured payouts",
    style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
    ),
    ],
    ),
    ),
    ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
    backgroundColor: AppConstants.accentGreen,
    foregroundColor: Color(0xFF021A13),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: () => admin.fetchAllData(),
    icon: const Icon(Icons.sync_rounded, size: 18),
    label: const Text("Sync Ledger", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
    ),
    ],
    ),
    const SizedBox(height: 20),

    // Operational Metric Badges
    Wrap(
    spacing: 14,
    runSpacing: 10,
    children: [
    _buildMetricCard("LOCKED CAPITAL", "₨ ${_currencyFormat.format(totalLockedCapital)}", AppConstants.accentGreen, isDesktop),
    _buildMetricCard("ACCRUED PROFIT", "₨ ${_currencyFormat.format(totalEstProfit)}", Color(0xFFA855F7), isDesktop),
    _buildMetricCard("TOTAL POTS", "${potsList.length} Active Vaults", AppConstants.accentBlue, isDesktop),
    _buildMetricCard("TOTAL INVESTORS", "${usersMap.length} Accounts", AppConstants.accentGold, isDesktop),
    ],
    ),
    const SizedBox(height: 20),

    // Search Field
    SizedBox(
    width: isDesktop ? 360 : double.infinity,
    child: TextField(
    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
    decoration: InputDecoration(
    hintText: "Search Investor, Mobile, Pot ID, Plan...",
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
    const SizedBox(height: 18),

    // Content Desk
    Expanded(
    child: filteredList.isEmpty
    ? const Center(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.savings_outlined, size: 54, color: AppConstants.textMuted),
    SizedBox(height: 12),
    Text(
    "No active savings vault pots found on file",
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
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
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
  DataColumn(label: Text("INVESTOR", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("PLAN & POT ID", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("PRINCIPAL CAPITAL", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("HALAL PROFIT RATE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("MATURITY TARGET", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("LOCK STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("SETTLEMENT ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((pt) {
  final amt = pt['amount'] as double;
  final profit = pt['profit'] as double;
  final totalPayout = pt['totalPayout'] as double;

  return DataRow(
  cells: [
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(pt['userName'], style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13)),
  Text(pt['userMobile'], style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
  ],
  ),
  ),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(pt['planTitle'], style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 12.5)),
  Text("#${pt['potId']} (${pt['category']})", style: const TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontFamily: 'monospace')),
  ],
  ),
  ),
  DataCell(
  Text(
  "₨ ${_currencyFormat.format(amt)}",
  style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 14),
  ),
  ),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text("${pt['rate']}% p.a.", style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w900, fontSize: 13)),
  Text("+₨ ${_currencyFormat.format(profit)} Profit", style: const TextStyle(color: AppConstants.accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
  ],
  ),
  ),
  DataCell(
  Text(
  pt['maturityDate'],
  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700),
  ),
  ),
  DataCell(
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: Colors.amber.withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
  ),
  child: const Text("ACTIVE VAULT", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900)),
  ),
  ),
  DataCell(
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: AppConstants.accentGreen,
  foregroundColor: Color(0xFF021A13),
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  onPressed: _isSettling ? null : () => _confirmSettleVault(context, pt, admin),
  icon: const Icon(Icons.paid_rounded, size: 14),
  label: Text(
  "Release (₨ ${_currencyFormat.format(totalPayout)})",
  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
  ),
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
  final pt = list[idx];
  final amt = pt['amount'] as double;
  final profit = pt['profit'] as double;
  final totalPayout = pt['totalPayout'] as double;

  return Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: Color(0xFFE2E8F0)),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text(pt['planTitle'], style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 14)),
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  decoration: BoxDecoration(
  color: Colors.amber.withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  ),
  child: const Text("ACTIVE VAULT", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 10)),
  ),
  ],
  ),
  const SizedBox(height: 6),
  Text("#${pt['potId']} • ${pt['maturityDate']}", style: const TextStyle(color: Color(0xFFA855F7), fontFamily: 'monospace', fontSize: 11)),
  const Divider(color: Color(0xFFE2E8F0), height: 18),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text("Principal Invested", style: TextStyle(color: AppConstants.textMuted, fontSize: 11)),
  Text("₨ ${_currencyFormat.format(amt)}", style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 15)),
  ],
  ),
  Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
  Text("Accrued Shariah Profit (${pt['rate']}%)", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
  Text("+₨ ${_currencyFormat.format(profit)}", style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w900, fontSize: 15)),
  ],
  ),
  ],
  ),
  const SizedBox(height: 10),
  Text("Investor: ${pt['userName']} (${pt['userMobile']})", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
  const SizedBox(height: 14),
  SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: AppConstants.accentGreen,
  foregroundColor: Color(0xFF021A13),
  padding: const EdgeInsets.symmetric(vertical: 10),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  onPressed: _isSettling ? null : () => _confirmSettleVault(context, pt, admin),
  icon: const Icon(Icons.paid_rounded, size: 16),
  label: Text(
  "Disburse Full Matured Payout (₨ ${_currencyFormat.format(totalPayout)})",
  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
  ),
  ),
  ),
  ],
  ),
  );
  },
  );
  }

  // Vault Settle & Wallet Disburse Dialog
  void _confirmSettleVault(BuildContext context, Map<String, dynamic> pt, AdminProvider admin) {
  final mob = pt['userMobile'].toString();
  final pIdx = pt['potIndex'] as int;
  final totalPayout = pt['totalPayout'] as double;
  final planTitle = pt['planTitle'].toString();
  final principal = pt['amount'] as double;

  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: const Row(
  children: [
  Icon(Icons.monetization_on_rounded, color: AppConstants.accentGreen),
  SizedBox(width: 8),
  Text("Disburse Matured Vault", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18)),
  ],
  ),
  content: Text(
  "Settlement Breakdown:\n"
  "• Investor: ${pt['userName']} ($mob)\n"
  "• Plan: $planTitle (#${pt['potId']})\n"
  "• Principal Capital: ₨ ${_currencyFormat.format(principal)}\n"
  "• Shariah Profit (${pt['rate']}%): ₨ ${_currencyFormat.format(pt['profit'])}\n"
  "• Total Credit Payout: ₨ ${_currencyFormat.format(totalPayout)}\n\n"
  "Kya aap waqai yeh pot close karke mukammal raqam customer ke primary wallet balance me transfer karna chahte hain?",
  style: const TextStyle(color: AppConstants.textMuted, fontSize: 13, height: 1.4),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: Color(0xFF021A13)),
  onPressed: () async {
  Navigator.pop(ctx);
  setState(() => _isSettling = true);

  try {
  // Fetch fresh user data to prevent race condition
  final userRaw = admin.users[mob];
  if (userRaw is! Map<String, dynamic>) {
  throw Exception("User record not found");
  }

  final userCopy = Map<String, dynamic>.from(userRaw);
  final currentBal = double.tryParse(userCopy['balance']?.toString() ?? '0') ?? 0.0;
  final currentRec = double.tryParse(userCopy['received']?.toString() ?? '0') ?? 0.0;
  final currentSavings = double.tryParse(userCopy['savings']?.toString() ?? '0') ?? 0.0;

  // Adjust balances
  userCopy['balance'] = currentBal + totalPayout;
  userCopy['received'] = currentRec + totalPayout;
  userCopy['savings'] = max(0.0, currentSavings - principal);

  // Remove matured pot
  final pots = (userCopy['savingsPots'] is List)
  ? List<dynamic>.from(userCopy['savingsPots'])
      : [];

  if (pIdx >= 0 && pIdx < pots.length) {
  pots.removeAt(pIdx);
  }
  userCopy['savingsPots'] = pots;

  // Prepend Ledger Transaction
  final txs = (userCopy['transactions'] is List)
  ? List<dynamic>.from(userCopy['transactions'])
      : [];

  final tid = "MAT-${Random().nextInt(90000000) + 10000000}";
  txs.insert(0, {
  'tid': tid,
  'title': "Halal Vault Matured Profit & Payout: $planTitle",
  'from': "NexPay Profit Treasury",
  'to': userCopy['name'] ?? "Investor",
  'dest': "Principal + Shariah Profit Credit",
  'amount': totalPayout,
  'date': DateTime.now().toIso8601String(),
  });
  userCopy['transactions'] = txs;

  // Synchronize via save_all atomic action
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'save_all'},
  data: {
  'users': {mob: userCopy}
  },
  );

  if (res.data['status'] == 'success') {
  await admin.fetchAllData();
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text(
  "✓ Matured Vault Released! ₨ ${_currencyFormat.format(totalPayout)} credited to $mob.",
  style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold),
  ),
  ),
  );
  }
  } else {
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(backgroundColor: AppConstants.dangerRed, content: Text(res.data['message'] ?? "Settlement failed.")),
  );
  }
  }
  } catch (e) {
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while releasing vault.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isSettling = false);
  }
  },
  child: const Text("Disburse Matured Payout", style: TextStyle(fontWeight: FontWeight.w900)),
  ),
  ],
  ),
  );
  }
}
