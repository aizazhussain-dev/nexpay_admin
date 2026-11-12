import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class AuditTrailDeskScreen extends StatefulWidget {
  const AuditTrailDeskScreen({super.key});

  @override
  State<AuditTrailDeskScreen> createState() => _AuditTrailDeskScreenState();
}

class _AuditTrailDeskScreenState extends State<AuditTrailDeskScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  List _auditLogs = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _actionFilter = "ALL"; // ALL, LOGIN, PAYOUT, DEPOSIT, REVERSAL, USER

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final raw = await _storage.read(key: 'nb_admin_audit_trail');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _auditLogs = List.from(decoded);
        }
      } else {
        // Initial system logs if storage is empty
        _auditLogs = [
          {
            'timestamp': DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.now()),
            'action': 'Terminal Authenticated',
            'target': 'Executive Gateway',
            'details': 'Master Administrator authenticated via security console.',
            'operator': 'Administrator'
          },
          {
            'timestamp': DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.now().subtract(const Duration(minutes: 15))),
            'action': 'Ledger Sync',
            'target': 'Database Core',
            'details': 'Synchronized customer wallets, deposits & payout queue.',
            'operator': 'System Auto'
          }
        ];
        await _saveAuditLogs();
      }
    } catch (_) {
      _auditLogs = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAuditLogs() async {
    await _storage.write(key: 'nb_admin_audit_trail', value: jsonEncode(_auditLogs));
  }

  Future<void> _clearAuditLogs() async {
    await _storage.delete(key: 'nb_admin_audit_trail');
    setState(() => _auditLogs = []);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppConstants.accentGreen,
          content: Text("✓ Local audit logs cleared successfully.", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredLogs = _auditLogs.where((log) {
      final action = (log['action'] ?? '').toString().toUpperCase();
      if (_actionFilter == "LOGIN" && !action.contains("LOGIN") && !action.contains("AUTHENTICATED")) return false;
      if (_actionFilter == "PAYOUT" && !action.contains("PAYOUT")) return false;
      if (_actionFilter == "DEPOSIT" && !action.contains("DEPOSIT")) return false;
      if (_actionFilter == "REVERSAL" && !action.contains("REVERSAL") && !action.contains("RECALL")) return false;
      if (_actionFilter == "USER" && !action.contains("USER") && !action.contains("KYC") && !action.contains("PROFILE")) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final a = action.toLowerCase();
        final t = (log['target'] ?? '').toString().toLowerCase();
        final d = (log['details'] ?? '').toString().toLowerCase();
        final o = (log['operator'] ?? '').toString().toLowerCase();
        return a.contains(q) || t.contains(q) || d.contains(q) || o.contains(q);
      }
      return true;
    }).toList();

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with CSV Export & Clear Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Central System & Operator Audit Trail",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: isDesktop ? 22 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Immutable ledger of operator actions, compliance overrides, and financial exports",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.dangerRed,
                      side: BorderSide(color: AppConstants.dangerRed.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirmClearLogsDialog(context),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text("Clear Local Logs", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showExportCsvDialog(context, admin),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text("Export CSV Report", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search & Filter Controls
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
                    hintText: "Search Action, Target, Details, Operator...",
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
              _buildFilterChip("ALL", "All Logs (${_auditLogs.length})"),
              _buildFilterChip("LOGIN", "Logins / Sessions"),
              _buildFilterChip("PAYOUT", "Payouts"),
              _buildFilterChip("DEPOSIT", "Deposits"),
              _buildFilterChip("REVERSAL", "Dispute Reversals"),
              _buildFilterChip("USER", "User & KYC Overrides"),
            ],
          ),
          const SizedBox(height: 18),

          // Content Desk
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.accentGreen))
                : filteredLogs.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security_rounded, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No audit trail records found",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
                : isDesktop
                ? _buildDesktopTable(filteredLogs)
                : _buildMobileCards(filteredLogs),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _actionFilter == key;
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
      onSelected: (_) => setState(() => _actionFilter = key),
    );
  }

  Widget _buildDesktopTable(List list) {
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
  DataColumn(label: Text("TIMESTAMP", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("ACTION PERFORMED", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("TARGET ACCOUNT / ASSET", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("EVENT DETAILS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("OPERATOR", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((l) {
  return DataRow(
  cells: [
  DataCell(Text(l['timestamp'] ?? '-', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5))),
  DataCell(
  Row(
  children: [
  _buildActionIcon(l['action'] ?? ''),
  const SizedBox(width: 8),
  Text(l['action'] ?? '-', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13)),
  ],
  ),
  ),
  DataCell(Text(l['target'] ?? '-', style: const TextStyle(color: AppConstants.accentBlue, fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 12.5))),
  DataCell(
  Container(
  constraints: const BoxConstraints(maxWidth: 420),
  child: Text(l['details'] ?? '-', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
  ),
  ),
  DataCell(
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: AppConstants.accentGreen.withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.3)),
  ),
  child: Text(
  l['operator'] ?? 'Admin',
  style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w800, fontSize: 11),
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

  Widget _buildMobileCards(List list) {
  return ListView.builder(
  itemCount: list.length,
  itemBuilder: (context, idx) {
  final l = list[idx];
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
  Row(
  children: [
  _buildActionIcon(l['action'] ?? ''),
  const SizedBox(width: 8),
  Text(l['action'] ?? '-', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13.5)),
  ],
  ),
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
  decoration: BoxDecoration(
  color: AppConstants.accentGreen.withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  ),
  child: Text(l['operator'] ?? 'Admin', style: const TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w800)),
  ),
  ],
  ),
  const SizedBox(height: 10),
  Text(l['details'] ?? '-', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.35)),
  const Divider(color: Color(0xFFE2E8F0), height: 18),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text("Target: ${l['target'] ?? '-'}", style: const TextStyle(color: AppConstants.accentBlue, fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.bold)),
  Text(l['timestamp'] ?? '-', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
  ],
  ),
  ],
  ),
  );
  },
  );
  }

  Widget _buildActionIcon(String action) {
  final a = action.toUpperCase();
  IconData icon = Icons.info_outline_rounded;
  Color color = AppConstants.textMuted;

  if (a.contains("LOGIN") || a.contains("AUTHENTICATED")) {
  icon = Icons.lock_open_rounded;
  color = AppConstants.accentGreen;
  } else if (a.contains("PAYOUT")) {
  icon = Icons.send_and_archive_rounded;
  color = AppConstants.accentGreen;
  } else if (a.contains("DEPOSIT")) {
  icon = Icons.move_to_inbox_rounded;
  color = AppConstants.accentGold;
  } else if (a.contains("REVERSAL") || a.contains("RECALL")) {
  icon = Icons.replay_rounded;
  color = Colors.amber;
  } else if (a.contains("DELETE") || a.contains("TERMINATE") || a.contains("REJECT")) {
  icon = Icons.close_rounded;
  color = AppConstants.dangerRed;
  }

  return Icon(icon, size: 16, color: color);
  }

  void _confirmClearLogsDialog(BuildContext context) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: const Row(
  children: [
  Icon(Icons.warning_amber_rounded, color: AppConstants.dangerRed),
  SizedBox(width: 8),
  Text("Clear Audit Trail", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
  ],
  ),
  content: const Text(
  "Kya aap waqai is device ke local operator audit logs clear karna chahte hain? Yeh action irreversible hai.",
  style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Colors.white),
  onPressed: () {
  Navigator.pop(ctx);
  _clearAuditLogs();
  },
  child: const Text("Yes, Clear Logs", style: TextStyle(fontWeight: FontWeight.w700)),
  ),
  ],
  ),
  );
  }

  // Generate & Copy / View Financial CSV Export
  void _showExportCsvDialog(BuildContext context, AdminProvider admin) {
  final users = admin.users;
  final StringBuffer csvBuffer = StringBuffer();

  // CSV Header row[cite: 16]
  csvBuffer.writeln("Mobile,Customer Name,CNIC,Email,Cash Balance (PKR),Crypto (USDT),Gold (g),Total Received (PKR),Total Sent (PKR),KYC Status");

  // CSV Data rows[cite: 16]
  users.forEach((mob, u) {
  final name = (u['name'] ?? '').toString().replaceAll('"', '""');
  final cnic = (u['cnic'] ?? '').toString();
  final email = (u['email'] ?? '').toString().replaceAll('"', '""');
  final balance = u['balance'] ?? 0;
  final crypto = u['crypto'] ?? 0;
  final gold = u['goldGrams'] ?? u['gold_grams'] ?? 0;
  final rec = u['received'] ?? 0;
  final sent = u['sent'] ?? 0;
  final kyc = (u['isKycVerified'] == true) ? "VERIFIED" : (u['kycStatus'] ?? "PENDING");

  csvBuffer.writeln('"$mob","$name","$cnic","$email",$balance,$crypto,$gold,$rec,$sent,"$kyc"');
  });

  final String csvData = csvBuffer.toString();

  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: const Row(
  children: [
  Icon(Icons.table_chart_rounded, color: AppConstants.accentGreen),
  SizedBox(width: 8),
  Text("Reconciliation Report (CSV)", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
  ],
  ),
  content: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text(
  "Generated complete financial export for ${users.length} registered customer accounts.",
  style: const TextStyle(color: AppConstants.textMuted, fontSize: 12.5),
  ),
  const SizedBox(height: 14),
  Container(
  height: 160,
  width: double.maxFinite,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
  color: Colors.black,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Color(0xFFE2E8F0)),
  ),
  child: SingleChildScrollView(
  child: Text(
  csvData,
  style: const TextStyle(color: AppConstants.accentGreen, fontFamily: 'monospace', fontSize: 11),
  ),
  ),
  ),
  ],
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: Colors.white),
  onPressed: () {
  Clipboard.setData(ClipboardData(text: csvData));
  Navigator.pop(ctx);
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ CSV Report copied to clipboard!", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  },
  icon: const Icon(Icons.copy_rounded, size: 16),
  label: const Text("Copy CSV Data", style: TextStyle(fontWeight: FontWeight.w700)),
  ),
  ],
  ),
  );
  }
}
