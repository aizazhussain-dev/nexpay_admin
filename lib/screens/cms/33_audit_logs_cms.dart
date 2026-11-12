import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class AuditLogsCmsScreen extends StatefulWidget {
  const AuditLogsCmsScreen({super.key});

  @override
  State<AuditLogsCmsScreen> createState() => _AuditLogsCmsScreenState();
}

class _AuditLogsCmsScreenState extends State<AuditLogsCmsScreen> {
  final _searchCtrl = TextEditingController();
  String _severity = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _logs(AdminProvider admin) {
    final raw = admin.cmsConfig['auditLogs'];
    return raw is List ? raw.whereType().map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final logs = _logs(admin);
    final filtered = logs.where((l) {
      final sev = (l['severity'] ?? 'INFO').toString().toUpperCase();
      if (_severity != 'ALL' && sev != _severity) return false;
      if (_query.isEmpty) return true;
      return '${l['operator']} ${l['action']} ${l['target']} ${l['category']}'.toLowerCase().contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'System Configuration & Security Audit Logs',
        subtitle: 'Immutable trail of CMS configuration edits, security policy changes, and operator sessions',
        badgeText: '${logs.length} LOG ENTRIES',
        badgeColor: AppConstants.accentBlue,
        actions: [
          if (logs.isNotEmpty)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppConstants.dangerRed),
              onPressed: () async => await admin.saveCmsConfig({'auditLogs': []}),
              icon: const Icon(Icons.delete_sweep_rounded, size: 17),
              label: const Text('Clear Archived Logs'),
            ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search log by operator, action, target, or category...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'INFO', 'WARNING', 'CRITICAL'],
        selectedFilter: _severity,
        onFilterChanged: (f) => setState(() => _severity = f),
        resultSummary: 'Showing ${filtered.length} of ${logs.length} logs',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const InstitutionalEmptyState(
          icon: Icons.history_edu_rounded,
          title: 'No System Audit Logs Recorded',
          subtitle: 'Live administrative configuration and security logs from smartvest.tech will appear here.',
        ),
        columns: const [
          DataColumn(label: Text('TIMESTAMP')),
          DataColumn(label: Text('OPERATOR / ROLE')),
          DataColumn(label: Text('CATEGORY')),
          DataColumn(label: Text('ACTION')),
          DataColumn(label: Text('TARGET')),
          DataColumn(label: Text('SEVERITY')),
        ],
        rows: filtered.map((l) {
          return DataRow(
            cells: [
              DataCell(Text((l['timestamp'] ?? '-').toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
              DataCell(Text('${l['operator'] ?? 'admin'} (${l['role'] ?? 'ROOT'})', style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text((l['category'] ?? 'CMS').toString())),
              DataCell(Text((l['action'] ?? '-').toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text((l['target'] ?? '-').toString(), style: const TextStyle(fontSize: 12.5))),
              DataCell(NexPayStatusBadge(status: (l['severity'] ?? 'INFO').toString())),
            ],
          );
        }).toList(),
      ),
    );
  }
}