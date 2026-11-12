import '../../widgets/institutional_scroll.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class OutwardLedgerDeskScreen extends StatefulWidget {
  const OutwardLedgerDeskScreen({super.key});

  @override
  State<OutwardLedgerDeskScreen> createState() => _OutwardLedgerDeskScreenState();
}

class _OutwardLedgerDeskScreenState extends State<OutwardLedgerDeskScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");
  String _searchQuery = "";
  String _categoryFilter = "ALL"; // ALL, INTERBANK, BILLS, WALLET, BUNDLES
  bool _isReversing = false;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final usersMap = admin.users;

    // Collect all outward (negative amount) transactions across all users
    final List outwardList = [];

    usersMap.forEach((mobile, userData) {
    final userName = (userData['name'] ?? 'Customer').toString();
    final txs = userData['transactions'];

    if (txs is List) {
    for (var t in txs) {
    if (t is Map) {
    final amt = double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0;
    final title = (t['title'] ?? '').toString();

    // Outward debited settlements[cite: 16]
    if (amt < 0) {
    outwardList.add({
    'senderMobile': mobile.toString(),
    'senderName': userName,
    'title': title,
    'dest': (t['dest'] ?? '-').toString(),
    'to': (t['to'] ?? '-').toString(),
    'amount': amt.abs(),
    'tid': (t['tid'] ?? 'TRX').toString(),
    'date': (t['date'] ?? '').toString(),
    });
    }
    }
    }
    }
    });

    // Sort newest first
    outwardList.sort((a, b) {
    final dateA = DateTime.tryParse(a['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dateB = DateTime.tryParse(b['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return dateB.compareTo(dateA);
    });

    // Filter Logic
    final filteredList = outwardList.where((item) {
    final title = item['title'].toString().toLowerCase();

    if (_categoryFilter == "INTERBANK" && !title.contains("interbank") && !title.contains("bank") && !title.contains("manual transfer")) {
    return false;
    }
    if (_categoryFilter == "BILLS" && !title.contains("bill")) return false;
    if (_categoryFilter == "WALLET" && !title.contains("wallet") && !title.contains("internal")) return false;
    if (_categoryFilter == "BUNDLES" && !title.contains("package") && !title.contains("bundle")) return false;

    if (_searchQuery.isNotEmpty) {
    final q = _searchQuery.toLowerCase();
    final mob = item['senderMobile'].toString().toLowerCase();
    final name = item['senderName'].toString().toLowerCase();
    final tid = item['tid'].toString().toLowerCase();
    final dest = item['dest'].toString().toLowerCase();
    final to = item['to'].toString().toLowerCase();
    return mob.contains(q) || name.contains(q) || tid.contains(q) || dest.contains(q) || to.contains(q) || title.contains(q);
    }
    return true;
    }).toList();

    // Total Outward Settlement Sum
    double totalOutwardVolume = 0;
    for (var item in outwardList) {
    totalOutwardVolume += (item['amount'] as double);
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
    "1Link Outward Transfers & Dispute Recall Ledger",
    style: TextStyle(
    color: Color(0xFF0F172A),
    fontSize: isDesktop ? 22 : 18,
    fontWeight: FontWeight.w700,
    ),
    ),
    const SizedBox(height: 4),
    Text(
    "Comprehensive ledger of interbank payments, bills, and 1-Click dispute reversals",
    style: const TextStyle(color: AppConstants.textMuted, fontSize: 12),
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
    label: const Text("Sync Ledger", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    ),
    ],
    ),
    const SizedBox(height: 20),

    // Filters & Total Outward Badge
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
    hintText: "Search Sender, Mobile, TID, Bank...",
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
    _buildFilterChip("ALL", "All Outward (${outwardList.length})"),
    _buildFilterChip("INTERBANK", "Interbank / 1Link"),
    _buildFilterChip("BILLS", "Utility Bills"),
    _buildFilterChip("WALLET", "Wallet Transfers"),
    _buildFilterChip("BUNDLES", "SIM Bundles"),
    Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
    color: AppConstants.dangerRed.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppConstants.dangerRed.withValues(alpha: 0.3)),
    ),
    child: Text(
    "Total Outward: ₨ ${_currencyFormat.format(totalOutwardVolume)}",
    style: const TextStyle(color: AppConstants.dangerRed, fontSize: 12, fontWeight: FontWeight.w700),
    ),
    ),
    ],
    ),
    const SizedBox(height: 18),

    // Content Area
    Expanded(
    child: filteredList.isEmpty
    ? const Center(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.account_balance_wallet_outlined, size: 54, color: AppConstants.textMuted),
    SizedBox(height: 12),
    Text(
    "No outward ledger transactions found",
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

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _categoryFilter == key;
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
      onSelected: (_) => setState(() => _categoryFilter = key),
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
  child: InstitutionalVScroll(
  scrollDirection: Axis.vertical,
  child: InstitutionalHScroll(
  child: DataTable(
  headingRowColor: WidgetStateProperty.all(AppConstants.surfaceCard),
  dataRowColor: WidgetStateProperty.all(Colors.transparent),
  horizontalMargin: 20,
  columnSpacing: 24,
  columns: const [
  DataColumn(label: Text("TIMESTAMP", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("SENDER PROFILE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("BENEFICIARY / TARGET", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("TRANSACTION TYPE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("DEBIT AMOUNT", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("TID", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("DISPUTE RECALL", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((item) {
  final dateStr = _formatTimestamp(item['date']);
  final amt = item['amount'] as double;
  final tid = item['tid'].toString();
  final senderMob = item['senderMobile'].toString();
  final recMob = _extractRecipientMobile(item['dest'].toString(), item['to'].toString());

  return DataRow(
  cells: [
  DataCell(Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5))),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(item['senderName'], style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13)),
  Text(senderMob, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
  ],
  ),
  ),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(item['to'], style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 12.5)),
  Text(item['dest'], style: const TextStyle(color: AppConstants.accentGold, fontSize: 11, fontFamily: 'monospace')),
  ],
  ),
  ),
  DataCell(
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: Color(0xFFA855F7).withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: Color(0xFFA855F7).withValues(alpha: 0.3)),
  ),
  child: Text(
  item['title'],
  style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w800, fontSize: 11),
  ),
  ),
  ),
  DataCell(
  Text(
  "- ₨ ${_currencyFormat.format(amt)}",
  style: const TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w700, fontSize: 14),
  ),
  ),
  DataCell(Text(tid, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontFamily: 'monospace'))),
  DataCell(
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: Colors.amber.withValues(alpha: 0.15),
  foregroundColor: Colors.amber,
  side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  onPressed: _isReversing
  ? null
      : () => _confirmDisputeRecall(context, senderMob, tid, amt, recMob, admin),
  icon: const Icon(Icons.replay_rounded, size: 14),
  label: const Text("1-Click Reverse", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
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
  final item = list[idx];
  final dateStr = _formatTimestamp(item['date']);
  final amt = item['amount'] as double;
  final tid = item['tid'].toString();
  final senderMob = item['senderMobile'].toString();
  final recMob = _extractRecipientMobile(item['dest'].toString(), item['to'].toString());

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
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: Color(0xFFA855F7).withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
  item['title'],
  style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w700, fontSize: 11),
  ),
  ),
  Text(
  "- ₨ ${_currencyFormat.format(amt)}",
  style: const TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w700, fontSize: 16),
  ),
  ],
  ),
  const SizedBox(height: 12),
  Text(item['to'], style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 14)),
  const SizedBox(height: 2),
  Text(item['dest'], style: const TextStyle(color: AppConstants.accentGold, fontFamily: 'monospace', fontSize: 12)),
  const Divider(color: Color(0xFFE2E8F0), height: 20),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text("Sender: ${item['senderName']} ($senderMob)", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
  Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
  ],
  ),
  const SizedBox(height: 4),
  Text("TID: $tid", style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5, fontFamily: 'monospace')),
  const SizedBox(height: 12),
  SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
  style: OutlinedButton.styleFrom(
  foregroundColor: Colors.amber,
  side: BorderSide(color: Colors.amber.withValues(alpha: 0.4)),
  padding: const EdgeInsets.symmetric(vertical: 10),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  onPressed: _isReversing
  ? null
      : () => _confirmDisputeRecall(context, senderMob, tid, amt, recMob, admin),
  icon: const Icon(Icons.replay_rounded, size: 16),
  label: const Text("1-Click Dispute Recall (Refund)", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
  ),
  ),
  ],
  ),
  );
  },
  );
  }

  String _extractRecipientMobile(String dest, String to) {
  final reg = RegExp(r'03[0-9]{9}');
  final matchDest = reg.firstMatch(dest);
  if (matchDest != null) return matchDest.group(0)!;
  final matchTo = reg.firstMatch(to);
  if (matchTo != null) return matchTo.group(0)!;
  return "";
  }

  String _formatTimestamp(String timestamp) {
  if (timestamp.isEmpty) return "-";
  try {
  final date = DateTime.parse(timestamp);
  return DateFormat("dd MMM, hh:mm a").format(date);
  } catch (_) {
  return timestamp;
  }
  }

  // 1-Click Dispute Recall & Auto-Refund Execution
  void _confirmDisputeRecall(
  BuildContext context,
  String senderMobile,
  String tid,
  double amount,
  String recipientMobile,
  AdminProvider admin,
  ) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: const Row(
  children: [
  Icon(Icons.warning_amber_rounded, color: Colors.amber),
  SizedBox(width: 8),
  Text("Execute 1-Click Reversal", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
  ],
  ),
  content: Text(
  "Dispute Reversal Summary:\n"
  "• TID: $tid\n"
  "• Amount: ₨ ${_currencyFormat.format(amount)}\n"
  "• Refunding to: $senderMobile\n"
  "${recipientMobile.isNotEmpty ? '• Recalling from: $recipientMobile\n' : ''}\n"
  "Kya aap waqai is transaction ko recall karke customer ke wallet me refund karna chahte hain?",
  style: const TextStyle(color: AppConstants.textMuted, fontSize: 13, height: 1.4),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
  onPressed: () async {
  Navigator.pop(ctx);
  setState(() => _isReversing = true);

  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'reverse_transaction'},
  data: {
  'senderMobile': senderMobile,
  'tid': tid,
  'amount': amount,
  'recipientMobile': recipientMobile,
  },
  );

  if (res.data['status'] == 'success') {
  await admin.fetchAllData();
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text(
  "✓ Reversal Successful: ₨ ${_currencyFormat.format(amount)} refunded to $senderMobile!",
  style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold),
  ),
  ),
  );
  }
  } else {
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  backgroundColor: AppConstants.dangerRed,
  content: Text(
  res.data['message'] ?? "Reversal failed or duplicate recall blocked.",
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
  ),
  ),
  );
  }
  }
  } catch (e) {
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.dangerRed,
  content: Text("Server network error while reversing transaction.", style: TextStyle(color: Color(0xFF0F172A))),
  ),
  );
  }
  } finally {
  if (mounted) setState(() => _isReversing = false);
  }
  },
  child: const Text("Execute Reversal", style: TextStyle(fontWeight: FontWeight.w700)),
  ),
  ],
  ),
  );
  }
}
