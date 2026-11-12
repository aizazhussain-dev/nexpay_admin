import '../../widgets/institutional_scroll.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class AuditLogsCmsScreen extends StatefulWidget {
  const AuditLogsCmsScreen({super.key});

  @override
  State<AuditLogsCmsScreen> createState() => _AuditLogsCmsScreenState();
}

class _AuditLogsCmsScreenState extends State<AuditLogsCmsScreen> {
  final ApiClient _api = ApiClient();
  final DateFormat _dateFormatter = DateFormat("dd MMM yyyy, hh:mm:ss a");

  List _logsList = [];
  String _searchQuery = "";
  String _categoryFilter = "ALL"; // ALL, TREASURY, COMPLIANCE, SECURITY, CMS, USERS
  String _severityFilter = "ALL"; // ALL, INFO, WARNING, CRITICAL

  bool _isLoading = false;
  bool _isInitialized = false;

  // National Financial Audit Trail fallback logs
  final List _defaultAuditLogs = [
  {
  'id': 'log_90210',
  'timestamp': '2026-11-12T04:25:10Z',
  'operator': 'root_admin',
  'role': 'SUPER_ADMIN',
  'action': 'APPROVED_PAYOUT',
  'category': 'TREASURY',
  'severity': 'INFO',
  'target': 'TRX-98210381 (03330640148)',
  'ipAddress': '182.185.120.45',
  'details': {
  'amount': 25000.0,
  'channel': 'Bank Transfer (Meezan)',
  'fee': 0.0,
  'beneficiaryIban': 'PK76MEZN0001020304050607',
  },
  },
  {
  'id': 'log_90209',
  'timestamp': '2026-11-12T03:50:44Z',
  'operator': 'fatima_aml',
  'role': 'COMPLIANCE',
  'action': 'KYC_TIER2_APPROVED',
  'category': 'COMPLIANCE',
  'severity': 'INFO',
  'target': 'Customer: 03001234567',
  'ipAddress': '182.185.120.45',
  'details': {
  'cnic': '41304-1234567-1',
  'motherName': 'Khatoon Bibi',
  'upgradedLimit': '₨ 1,000,000 Monthly',
  },
  },
  {
  'id': 'log_90208',
  'timestamp': '2026-11-12T02:15:30Z',
  'operator': 'hamza_treasury',
  'role': 'TREASURY',
  'action': 'UPDATED_GOLD_SPOT',
  'category': 'CMS',
  'severity': 'WARNING',
  'target': '24K Physical Bullion Ticker',
  'ipAddress': '104.28.19.102',
  'details': {
  'oldPerGram': 24200.0,
  'newPerGram': 24500.0,
  'spread': '1.5%',
  },
  },
  {
  'id': 'log_90207',
  'timestamp': '2026-11-11T22:40:12Z',
  'operator': 'SYSTEM_FIREWALL',
  'role': 'SECURITY_DAEMON',
  'action': 'BRUTE_FORCE_BLOCKED',
  'category': 'SECURITY',
  'severity': 'CRITICAL',
  'target': 'IP: 103.21.244.2',
  'ipAddress': '103.21.244.2',
  'details': {
  'reason': '5 consecutive failed password attempts for user: root_admin',
  'lockoutMinutes': 15,
  },
  },
  {
  'id': 'log_90206',
  'timestamp': '2026-11-11T18:10:05Z',
  'operator': 'root_admin',
  'role': 'SUPER_ADMIN',
  'action': 'ACCOUNT_FROZEN',
  'category': 'USERS',
  'severity': 'CRITICAL',
  'target': 'Customer: 03129876543',
  'ipAddress': '182.185.120.45',
  'details': {
  'reason': 'Reported suspicious reverse velocity pattern',
  'walletBalanceAtFreeze': '₨ 145,200',
  },
  },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadLogs();
      _isInitialized = true;
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;

    if (cfg['auditLogs'] is List && (cfg['auditLogs'] as List).isNotEmpty) {
      final list = (cfg['auditLogs'] as List)
          .whereType()
          .map((l) => Map<String, dynamic>.from(l))
          .toList();
      setState(() => _logsList = list);
    } else {
      setState(() {
        _logsList = [];
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredLogs = _logsList.where((log) {
      final cat = (log['category'] ?? 'SYSTEM').toString().toUpperCase();
      final sev = (log['severity'] ?? 'INFO').toString().toUpperCase();

      if (_categoryFilter != "ALL" && cat != _categoryFilter) return false;
      if (_severityFilter != "ALL" && sev != _severityFilter) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final op = (log['operator'] ?? '').toString().toLowerCase();
        final action = (log['action'] ?? '').toString().toLowerCase();
        final target = (log['target'] ?? '').toString().toLowerCase();
        final ip = (log['ipAddress'] ?? '').toString().toLowerCase();
        return op.contains(q) || action.contains(q) || target.contains(q) || ip.contains(q);
      }
      return true;
    }).toList();

    // Operational Metrics
    int criticalCount = _logsList.where((l) => (l['severity'] ?? '').toString().toUpperCase() == 'CRITICAL').length;
    int treasuryCount = _logsList.where((l) => (l['category'] ?? '').toString().toUpperCase() == 'TREASURY').length;
    int complianceCount = _logsList.where((l) => (l['category'] ?? '').toString().toUpperCase() == 'COMPLIANCE').length;

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
                        const Text(
                          "System Audit Logs & Financial Activity Trail",
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppConstants.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            "IMMUTABLE LEDGER",
                            style: TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Comprehensive forensic activity audit trail recording operator actions, payout decisions, and security alerts",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _exportLogsToCsv,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text("Export CSV Audit", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.dangerRed,
                      side: BorderSide(color: AppConstants.dangerRed.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirmPurgeLogs(context, admin),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text("Purge Trail", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operational Metric Badges
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard("TOTAL AUDIT EVENTS", "${_logsList.length} Entries Recorded", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("CRITICAL SECURITY ALERTS", "$criticalCount Alerts", criticalCount > 0 ? AppConstants.dangerRed : AppConstants.accentGreen, isDesktop),
              _buildMetricCard("TREASURY DISPATCHES", "$treasuryCount Payout Actions", AppConstants.accentGold, isDesktop),
              _buildMetricCard("COMPLIANCE AUDITS", "$complianceCount KYC Approvals", AppConstants.accentGreen, isDesktop),
            ],
          ),
          const SizedBox(height: 20),

          // Filters & Search Bar
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isDesktop ? 320 : double.infinity,
                child: TextField(
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search Operator, Action, Target, IP...",
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
              _buildCategoryChip("ALL", "All Categories"),
              _buildCategoryChip("TREASURY", "💰 Treasury"),
              _buildCategoryChip("COMPLIANCE", "🛡️ Compliance"),
              _buildCategoryChip("USERS", "👥 User Control"),
              _buildCategoryChip("SECURITY", "🔒 Security"),
              _buildCategoryChip("CMS", "⚙️ CMS Config"),
              const SizedBox(width: 8),
              _buildSeverityChip("ALL", "All"),
              _buildSeverityChip("INFO", "Info", AppConstants.accentGreen),
              _buildSeverityChip("WARNING", "Warning", Colors.amber),
              _buildSeverityChip("CRITICAL", "Critical", AppConstants.dangerRed),
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
                  Icon(Icons.history_toggle_off_rounded, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No audit trail events matching search criteria",
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
          Text(value, style: TextStyle(color: color, fontSize: 16.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
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

  Widget _buildSeverityChip(String key, String label, [Color? color]) {
    final isSelected = _severityFilter == key;
    final activeColor = color ?? Color(0xFF0F172A);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: activeColor.withValues(alpha: 0.25),
      backgroundColor: AppConstants.surface,
      labelStyle: TextStyle(
        color: isSelected ? activeColor : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 11,
      ),
      side: BorderSide(color: isSelected ? activeColor : Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => setState(() => _severityFilter = key),
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
  child: InstitutionalVScroll(
  scrollDirection: Axis.vertical,
  child: InstitutionalHScroll(
  child: DataTable(
  headingRowColor: WidgetStateProperty.all(AppConstants.surfaceCard),
  dataRowColor: WidgetStateProperty.all(Colors.transparent),
  horizontalMargin: 20,
  columnSpacing: 26,
  columns: const [
  DataColumn(label: Text("TIMESTAMP", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("OPERATOR / PRINCIPAL", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("ACTION / EVENT", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("TARGET RESOURCE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("IP ORIGIN", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("SEVERITY", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("INSPECT", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((log) {
  final tsStr = (log['timestamp'] ?? '').toString();
  String formattedDate = tsStr;
  try {
  final parsed = DateTime.parse(tsStr);
  formattedDate = _dateFormatter.format(parsed);
  } catch (_) {}

  final op = (log['operator'] ?? 'SYSTEM').toString();
  final role = (log['role'] ?? '-').toString();
  final action = (log['action'] ?? 'ACTION').toString();
  final target = (log['target'] ?? '-').toString();
  final ip = (log['ipAddress'] ?? '-').toString();
  final sev = (log['severity'] ?? 'INFO').toString().toUpperCase();

  return DataRow(
  cells: [
  DataCell(Text(formattedDate, style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'monospace', fontSize: 11.5))),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text("@$op", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 13)),
  Text(role, style: const TextStyle(color: AppConstants.textMuted, fontSize: 10)),
  ],
  ),
  ),
  DataCell(
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: Color(0xFFE2E8F0),
  borderRadius: BorderRadius.circular(6),
  ),
  child: Text(action, style: const TextStyle(color: Color(0xFF0F172A), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11)),
  ),
  ),
  DataCell(
  Container(
  constraints: const BoxConstraints(maxWidth: 220),
  child: Text(target, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 12)),
  ),
  ),
  DataCell(Text(ip, style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'monospace', fontSize: 11.5))),
  DataCell(_buildSeverityBadge(sev)),
  DataCell(
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: AppConstants.surfaceCard,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  onPressed: () => _openLogDetailsModal(context, log),
  icon: const Icon(Icons.data_object_rounded, size: 14, color: AppConstants.accentGreen),
  label: const Text("Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
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
  final log = list[idx];
  final tsStr = (log['timestamp'] ?? '').toString();
  String formattedDate = tsStr;
  try {
  final parsed = DateTime.parse(tsStr);
  formattedDate = _dateFormatter.format(parsed);
  } catch (_) {}

  final op = (log['operator'] ?? 'SYSTEM').toString();
  final action = (log['action'] ?? 'ACTION').toString();
  final target = (log['target'] ?? '-').toString();
  final ip = (log['ipAddress'] ?? '-').toString();
  final sev = (log['severity'] ?? 'INFO').toString().toUpperCase();

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
  Text("@$op", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14)),
  _buildSeverityBadge(sev),
  ],
  ),
  const SizedBox(height: 6),
  Text(action, style: const TextStyle(color: AppConstants.accentGreen, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
  const SizedBox(height: 4),
  Text("Target: $target", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
  const Divider(color: Color(0xFFE2E8F0), height: 18),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text(formattedDate, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5, fontFamily: 'monospace')),
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.accentBlue),
  onPressed: () => _openLogDetailsModal(context, log),
  icon: const Icon(Icons.data_object_rounded, size: 14),
  label: const Text("View JSON", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
  ),
  ],
  ),
  ],
  ),
  );
  },
  );
  }

  Widget _buildSeverityBadge(String sev) {
  Color color = AppConstants.accentGreen;
  if (sev == 'WARNING') color = Colors.amber;
  if (sev == 'CRITICAL') color = AppConstants.dangerRed;

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: color.withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: color.withValues(alpha: 0.3)),
  ),
  child: Text(sev, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w700)),
  );
  }

  // =========================================================================
  // LOG DETAILS & RAW JSON INSPECTION MODAL
  // =========================================================================
  void _openLogDetailsModal(BuildContext context, Map<String, dynamic> log) {
  const encoder = JsonEncoder.withIndent('  ');
  final prettyJson = encoder.convert(log);

  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: Row(
  children: [
  const Icon(Icons.data_object_rounded, color: AppConstants.accentGreen),
  const SizedBox(width: 8),
  Expanded(
  child: Text("Audit Payload: ${log['action']}", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 16)),
  ),
  ],
  ),
  content: Container(
  constraints: const BoxConstraints(maxWidth: 580, maxHeight: 480),
  child: InstitutionalVScroll(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text("Operator: @${log['operator']}", style: const TextStyle(color: AppConstants.accentBlue, fontWeight: FontWeight.bold, fontSize: 12)),
  Text("IP: ${log['ipAddress']}", style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'monospace', fontSize: 12)),
  ],
  ),
  const SizedBox(height: 10),
  Container(
  width: double.infinity,
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
  color: Colors.black,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Color(0xFFE2E8F0)),
  ),
  child: SelectableText(
  prettyJson,
  style: const TextStyle(color: Color(0xFF86EFAC), fontFamily: 'monospace', fontSize: 11.5, height: 1.4),
  ),
  ),
  ],
  ),
  ),
  ),
  actions: [
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.accentGreen),
  onPressed: () {
  Clipboard.setData(ClipboardData(text: prettyJson));
  Navigator.pop(ctx);
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text("✓ Raw JSON copied to clipboard!")),
  );
  },
  icon: const Icon(Icons.copy_rounded, size: 16),
  label: const Text("Copy JSON"),
  ),
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Color(0xFF64748B)))),
  ],
  ),
  );
  }

  // Export to CSV
  void _exportLogsToCsv() {
  final StringBuffer csv = StringBuffer();
  csv.writeln("Log ID,Timestamp,Operator,Role,Action,Category,Severity,Target,IP Address");

  for (var l in _logsList) {
  csv.writeln(
  '"${l['id']}","${l['timestamp']}","${l['operator']}","${l['role']}","${l['action']}","${l['category']}","${l['severity']}","${l['target']}","${l['ipAddress']}"',
  );
  }

  Clipboard.setData(ClipboardData(text: csv.toString()));
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ Audit trail exported to CSV! Data copied to clipboard.", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }

  // Purge Logs Safeguard
  void _confirmPurgeLogs(BuildContext context, AdminProvider admin) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: const Text("Purge Audit Trail?", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w700)),
  content: const Text(
  "WARNING: Audit logs provide legal compliance and regulatory dispute defense. Clearing them will permanently delete historical activity trail records.",
  style: TextStyle(color: AppConstants.textMuted, height: 1.4),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Colors.white),
  onPressed: () async {
  Navigator.pop(ctx);
  setState(() => _logsList = []);
  await _api.dio.post(
  '',
  queryParameters: {'action': 'save_config'},
  data: {'auditLogs': []},
  );
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text("Audit trail purged.")),
  );
  }
  },
  child: const Text("Confirm Purge"),
  ),
  ],
  ),
  );
  }
}
