import '../../widgets/institutional_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class GoldDispatchDeskScreen extends StatefulWidget {
  const GoldDispatchDeskScreen({super.key});

  @override
  State<GoldDispatchDeskScreen> createState() => _GoldDispatchDeskScreenState();
}

class _GoldDispatchDeskScreenState extends State<GoldDispatchDeskScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, PENDING, DISPATCHED, REJECTED
  bool _isActionBusy = false;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final usersMap = admin.users;

    // Collect all Physical Gold delivery orders from user ledger transactions
    final List orders = [];

    usersMap.forEach((mobile, userData) {
    final userName = (userData['name'] ?? 'Customer').toString();
    final userAddress = (userData['address'] ?? '').toString();
    final txs = userData['transactions'];

    if (txs is List) {
    for (var t in txs) {
    if (t is Map) {
    final tid = (t['tid'] ?? '').toString();
    final title = (t['title'] ?? '').toString();

    final isGoldOrder = tid.startsWith("INGOT-") || title.contains("Physical 24K Mint Ingot");

    if (isGoldOrder) {
    // Extract Grams from Title
    final match = RegExp(r'([0-9.]+)\s*g', caseSensitive: false).firstMatch(title);
    final grams = match != null ? double.tryParse(match.group(1)!) ?? 1.0 : 1.0;

    // Extract Address from 'to' field or user address
    String addr = userAddress;
    if (t['to'] != null) {
    final cleanedTo = t['to'].toString().replaceAll(userName, '').replaceAll(RegExp(r'[()]'), '').trim();
    if (cleanedTo.isNotEmpty) addr = cleanedTo;
    }
    if (addr.isEmpty || addr == 'Not Recorded') {
    addr = "Recorded in Profile Dossier";
    }

    orders.add({
    'mobile': mobile.toString(),
    'name': userName,
    'date': (t['date'] ?? '').toString(),
    'title': title,
    'grams': grams,
    'address': addr,
    'tid': tid,
    'fee': (double.tryParse(t['amount']?.toString() ?? '750') ?? 750.0).abs(),
    'dest': (t['dest'] ?? 'Courier Handover Pending').toString(),
    });
    }
    }
    }
    }
    });

    // Sort newest orders first
    orders.sort((a, b) {
    final dateA = DateTime.tryParse(a['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dateB = DateTime.tryParse(b['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return dateB.compareTo(dateA);
    });

    // Filter Logic
    final filteredList = orders.where((o) {
    final dest = o['dest'].toString().toLowerCase();
    final isDispatched = dest.contains("dispatched");
    final isRejected = dest.contains("rejected");
    final isPending = !isDispatched && !isRejected;

    if (_statusFilter == "PENDING" && !isPending) return false;
    if (_statusFilter == "DISPATCHED" && !isDispatched) return false;
    if (_statusFilter == "REJECTED" && !isRejected) return false;

    if (_searchQuery.isNotEmpty) {
    final q = _searchQuery.toLowerCase();
    final mob = o['mobile'].toString().toLowerCase();
    final name = o['name'].toString().toLowerCase();
    final tid = o['tid'].toString().toLowerCase();
    final addr = o['address'].toString().toLowerCase();
    return mob.contains(q) || name.contains(q) || tid.contains(q) || addr.contains(q);
    }
    return true;
    }).toList();

    // Metric Calculations
    int pendingCount = 0;
    int dispatchedCount = 0;
    double totalGramsOrdered = 0;

    for (var o in orders) {
    final dest = o['dest'].toString().toLowerCase();
    final isDispatched = dest.contains("dispatched");
    final isRejected = dest.contains("rejected");
    final grams = o['grams'] as double;

    totalGramsOrdered += grams;
    if (!isDispatched && !isRejected) {
    pendingCount++;
    } else if (isDispatched) {
    dispatchedCount++;
    }
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
    Row(
    children: [
    Text(
    "Physical 24K Gold Ingot Dispatch & Tracking",
    style: TextStyle(
    color: Color(0xFF0F172A),
    fontSize: isDesktop ? 22 : 18,
    fontWeight: FontWeight.w700,
    ),
    ),
    if (pendingCount > 0) ...[
    const SizedBox(width: 10),
    Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
    color: AppConstants.accentGold.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppConstants.accentGold.withValues(alpha: 0.3)),
    ),
    child: Text(
    "$pendingCount TO SHIP",
    style: const TextStyle(color: AppConstants.accentGold, fontSize: 10, fontWeight: FontWeight.w700),
    ),
    ),
    ],
    ],
    ),
    const SizedBox(height: 4),
    const Text(
    "Manage bullion bar doorstep delivery requests, assign courier tracking numbers or refund vault balance",
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
    label: const Text("Sync Ledger", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    ),
    ],
    ),
    const SizedBox(height: 20),

    // Operational Metric Cards
    Wrap(
    spacing: 14,
    runSpacing: 10,
    children: [
    _buildMetricCard("PENDING DISPATCH", "$pendingCount Ingot Orders", pendingCount > 0 ? AppConstants.accentGold : AppConstants.accentGreen, isDesktop),
    _buildMetricCard("SHIPPED VIA COURIER", "$dispatchedCount Handover Completed", AppConstants.accentGreen, isDesktop),
    _buildMetricCard("TOTAL GOLD MINTED", "${totalGramsOrdered.toStringAsFixed(2)} g 24K", AppConstants.accentGold, isDesktop),
    _buildMetricCard("TOTAL DELIVERY ORDERS", "${orders.length} Logged", AppConstants.accentBlue, isDesktop),
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
    hintText: "Search Customer, Mobile, Address, TID...",
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
    _buildFilterChip("ALL", "All Orders (${orders.length})"),
    _buildFilterChip("PENDING", "Pending Dispatch ($pendingCount)"),
    _buildFilterChip("DISPATCHED", "Dispatched ($dispatchedCount)"),
    _buildFilterChip("REJECTED", "Rejected & Refunded"),
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
    Icon(Icons.local_shipping_outlined, size: 54, color: AppConstants.textMuted),
    SizedBox(height: 12),
    Text(
    "No gold ingot delivery orders found",
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
    final isSelected = _statusFilter == key;
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
      onSelected: (_) => setState(() => _statusFilter = key),
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
  DataColumn(label: Text("ORDER DATE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("CUSTOMER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("INGOT WEIGHT", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("DESTINATION ADDRESS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("COURIER FEE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("ORDER TID", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("STATUS / TRACKING", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((o) {
  final dest = o['dest'].toString();
  final isDispatched = dest.toLowerCase().contains("dispatched");
  final isRejected = dest.toLowerCase().contains("rejected");
  final isPending = !isDispatched && !isRejected;

  final dateStr = _formatTimestamp(o['date'].toString());
  final grams = o['grams'] as double;
  final fee = o['fee'] as double;
  final tid = o['tid'].toString();
  final mobile = o['mobile'].toString();

  return DataRow(
  cells: [
  DataCell(Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5))),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(o['name'], style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13)),
  Text(mobile, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
  ],
  ),
  ),
  DataCell(
  Row(
  children: [
  const Icon(Icons.workspace_premium_rounded, size: 16, color: AppConstants.accentGold),
  const SizedBox(width: 4),
  Text(
  "${grams.toStringAsFixed(2)} g 24K",
  style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w700, fontSize: 13.5),
  ),
  ],
  ),
  ),
  DataCell(
  Container(
  constraints: const BoxConstraints(maxWidth: 240),
  child: Text(
  "📍 ${o['address']}",
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
  ),
  ),
  ),
  DataCell(Text("₨ ${_currencyFormat.format(fee)}", style: const TextStyle(color: AppConstants.textMuted, fontSize: 12))),
  DataCell(Text(tid, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontFamily: 'monospace'))),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  _buildStatusBadge(isPending, isDispatched, isRejected),
  if (isDispatched) ...[
  const SizedBox(height: 3),
  Text(dest, style: const TextStyle(color: AppConstants.accentGreen, fontSize: 10.5, fontFamily: 'monospace')),
  ],
  ],
  ),
  ),
  DataCell(
  isPending
  ? Row(
  children: [
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: AppConstants.accentGreen,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  onPressed: _isActionBusy ? null : () => _openDispatchDialog(context, o, admin),
  icon: const Icon(Icons.local_shipping_rounded, size: 14),
  label: const Text("Dispatch", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
  ),
  const SizedBox(width: 8),
  OutlinedButton.icon(
  style: OutlinedButton.styleFrom(
  foregroundColor: AppConstants.dangerRed,
  side: BorderSide(color: AppConstants.dangerRed.withValues(alpha: 0.4)),
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  onPressed: _isActionBusy ? null : () => _confirmRejectOrder(context, o, admin),
  icon: const Icon(Icons.cancel_rounded, size: 14),
  label: const Text("Reject", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
  ),
  ],
  )
      : Text(
  isDispatched ? "✓ Armed Handover" : "✕ Refunded",
  style: TextStyle(
  color: isDispatched ? AppConstants.accentGreen : AppConstants.dangerRed,
  fontSize: 11.5,
  fontWeight: FontWeight.w700,
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
  final o = list[idx];
  final dest = o['dest'].toString();
  final isDispatched = dest.toLowerCase().contains("dispatched");
  final isRejected = dest.toLowerCase().contains("rejected");
  final isPending = !isDispatched && !isRejected;

  final dateStr = _formatTimestamp(o['date'].toString());
  final grams = o['grams'] as double;
  final tid = o['tid'].toString();
  final mobile = o['mobile'].toString();

  return Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: isPending ? AppConstants.accentGold.withValues(alpha: 0.3) : Color(0xFFE2E8F0)),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Row(
  children: [
  const Icon(Icons.workspace_premium_rounded, size: 16, color: AppConstants.accentGold),
  const SizedBox(width: 4),
  Text("${grams.toStringAsFixed(2)} g 24K Gold Ingot", style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w700, fontSize: 14)),
  ],
  ),
  _buildStatusBadge(isPending, isDispatched, isRejected),
  ],
  ),
  const SizedBox(height: 10),
  Text("📍 ${o['address']}", style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, height: 1.35)),
  if (isDispatched) ...[
  const SizedBox(height: 6),
  Text(dest, style: const TextStyle(color: AppConstants.accentGreen, fontSize: 11, fontFamily: 'monospace')),
  ],
  const Divider(color: Color(0xFFE2E8F0), height: 20),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text("Customer: ${o['name']} ($mobile)", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
  Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
  ],
  ),
  const SizedBox(height: 4),
  Text("Order TID: $tid", style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5, fontFamily: 'monospace')),

  if (isPending) ...[
  const SizedBox(height: 14),
  Row(
  children: [
  Expanded(
  child: ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: AppConstants.accentGreen,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 10),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  onPressed: _isActionBusy ? null : () => _openDispatchDialog(context, o, admin),
  icon: const Icon(Icons.local_shipping_rounded, size: 16),
  label: const Text("Assign Courier Tracking", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
  ),
  ),
  const SizedBox(width: 8),
  Expanded(
  child: OutlinedButton(
  style: OutlinedButton.styleFrom(
  foregroundColor: AppConstants.dangerRed,
  side: BorderSide(color: AppConstants.dangerRed.withValues(alpha: 0.4)),
  padding: const EdgeInsets.symmetric(vertical: 10),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  onPressed: _isActionBusy ? null : () => _confirmRejectOrder(context, o, admin),
  child: const Text("Reject & Refund", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
  ),
  ),
  ],
  ),
  ],
  ],
  ),
  );
  },
  );
  }

  Widget _buildStatusBadge(bool isPending, bool isDispatched, bool isRejected) {
  Color bg;
  Color text;
  String label;

  if (isPending) {
  bg = AppConstants.accentGold.withValues(alpha: 0.15);
  text = AppConstants.accentGold;
  label = "PENDING DISPATCH";
  } else if (isDispatched) {
  bg = AppConstants.accentGreen.withValues(alpha: 0.15);
  text = AppConstants.accentGreen;
  label = "DISPATCHED";
  } else {
  bg = AppConstants.dangerRed.withValues(alpha: 0.15);
  text = AppConstants.dangerRed;
  label = "REJECTED & REFUNDED";
  }

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
  child: Text(label, style: TextStyle(color: text, fontSize: 10.5, fontWeight: FontWeight.w700)),
  );
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

  // Dialog: Assign Courier Tracking (TCS/Leopards)
  void _openDispatchDialog(BuildContext context, Map<String, dynamic> o, AdminProvider admin) {
  final trackingController = TextEditingController();
  final tid = o['tid'].toString();
  final mob = o['mobile'].toString();
  final grams = (o['grams'] as double).toStringAsFixed(2);

  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: const Row(
  children: [
  Icon(Icons.local_shipping_rounded, color: AppConstants.accentGreen),
  SizedBox(width: 8),
  Text("Dispatch 24K Bullion", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
  ],
  ),
  content: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text("Customer: ${o['name']} ($mob)", style: const TextStyle(color: AppConstants.accentBlue, fontSize: 12, fontWeight: FontWeight.bold)),
  const SizedBox(height: 2),
  Text("Mint Bar: $grams Grams 24K Pure Bullion", style: const TextStyle(color: AppConstants.accentGold, fontSize: 12, fontWeight: FontWeight.w800)),
  const SizedBox(height: 4),
  Text("Destination: ${o['address']}", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
  const SizedBox(height: 16),
  const Text("ENTER TCS / LEOPARDS COURIER TRACKING ID", style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800)),
  const SizedBox(height: 6),
  TextField(
  controller: trackingController,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
  decoration: InputDecoration(
  hintText: "e.g. TCS-77298102 or LPD-992102",
  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ],
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: Colors.white),
  onPressed: () async {
  final tracking = trackingController.text.trim();
  if (tracking.isEmpty) return;

  Navigator.pop(ctx);
  setState(() => _isActionBusy = true);

  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'dispatch_gold_delivery'},
  data: {
  'mobile': mob,
  'tid': tid,
  'tracking': tracking,
  },
  );

  if (res.data['status'] == 'success') {
  await admin.fetchAllData();
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ Gold Ingot dispatched with tracking: $tracking", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }
  } else {
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(backgroundColor: AppConstants.dangerRed, content: Text(res.data['message'] ?? "Dispatch failed.")),
  );
  }
  }
  } catch (_) {
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while dispatching order.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isActionBusy = false);
  }
  },
  child: const Text("Dispatch & Send Tracking", style: TextStyle(fontWeight: FontWeight.w700)),
  ),
  ],
  ),
  );
  }

  // Dialog: Reject & Refund Gold Bar + Courier Fee back to wallet[cite: 15, 16]
  void _confirmRejectOrder(BuildContext context, Map<String, dynamic> o, AdminProvider admin) {
  final tid = o['tid'].toString();
  final mob = o['mobile'].toString();
  final grams = o['grams'] as double;
  final fee = o['fee'] as double;

  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: const Row(
  children: [
  Icon(Icons.warning_amber_rounded, color: AppConstants.dangerRed),
  SizedBox(width: 8),
  Text("Reject Bullion Order", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
  ],
  ),
  content: Text(
  "Kya aap waqai Order #$tid ko REJECT karna chahte hain?\n\n"
  "Customer ($mob) ke account me:\n"
  "• ${grams.toStringAsFixed(4)}g 24K Gold wapis Gold Vault me chala jayega.\n"
  "• ₨ ${_currencyFormat.format(fee)} Courier Fee unke primary wallet me AUTO-REFUND ho jayegi.",
  style: const TextStyle(color: AppConstants.textMuted, fontSize: 13, height: 1.4),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Colors.white),
  onPressed: () async {
  Navigator.pop(ctx);
  setState(() => _isActionBusy = true);

  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'reject_gold_delivery'},
  data: {
  'mobile': mob,
  'tid': tid,
  'grams': grams,
  'fee': fee,
  },
  );

  if (res.data['status'] == 'success') {
  await admin.fetchAllData();
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ Order rejected! ${grams.toStringAsFixed(2)}g Gold & ₨ ${fee.toStringAsFixed(0)} fee refunded.", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }
  } else {
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(backgroundColor: AppConstants.dangerRed, content: Text(res.data['message'] ?? "Refund execution failed.")),
  );
  }
  }
  } catch (_) {
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while rejecting gold order.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isActionBusy = false);
  }
  },
  child: const Text("Reject & Refund Funds", style: TextStyle(fontWeight: FontWeight.w700)),
  ),
  ],
  ),
  );
  }
}
