import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
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
    return raw is List
        ? raw.whereType().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final logs = _logs(admin);

    int infoCount = 0;
    int warnCount = 0;
    int critCount = 0;
    for (final l in logs) {
      final sev = (l['severity'] ?? 'INFO').toString().toUpperCase();
      if (sev == 'CRITICAL') {
        critCount++;
      } else if (sev == 'WARNING') {
        warnCount++;
      } else {
        infoCount++;
      }
    }

    final filtered = logs.where((l) {
      final sev = (l['severity'] ?? 'INFO').toString().toUpperCase();
      if (_severity != 'ALL' && sev != _severity) return false;
      if (_query.isEmpty) return true;
      return '${l['operator']} ${l['action']} ${l['target']} ${l['category']}'
          .toLowerCase()
          .contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'System Configuration & Security Audit Logs',
        subtitle:
        'Immutable trail of CMS configuration edits, security policy changes, and operator sessions',
        badgeText: '${logs.length} LOG ENTRIES',
        badgeColor: AppConstants.accentBlue,
        actions: [
          if (logs.isNotEmpty)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.dangerRed),
              onPressed: () async {
                final confirmed = await showNexPayConfirmDialog(
                  context: context,
                  title: 'Clear Archived Audit Logs',
                  message:
                  'Purge all ${logs.length} archived configuration log entries from CMS storage?',
                  confirmLabel: 'Clear Logs',
                  confirmColor: AppConstants.dangerRed,
                  icon: Icons.delete_sweep_rounded,
                );
                if (!confirmed || !context.mounted) return;
                await admin.saveCmsConfig({'auditLogs': []});
              },
              icon: const Icon(Icons.delete_sweep_rounded, size: 17),
              label: const Text('Clear Archived Logs'),
            ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Total System Logs',
            value: '${logs.length} Entries',
            sublabel: 'Live smartvest.tech configuration trail',
            icon: Icons.history_edu_rounded,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Informational Events',
            value: '$infoCount Info',
            sublabel: 'Standard CMS & catalog updates',
            icon: Icons.info_outline_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Security Warnings',
            value: '$warnCount Warnings',
            sublabel: 'Elevated operator parameter changes',
            icon: Icons.warning_amber_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Critical Alerts',
            value: '$critCount Critical',
            sublabel: 'High-impact lockouts & policy shifts',
            icon: Icons.gpp_maybe_rounded,
            color: AppConstants.dangerRed,
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
        emptyState: const NexPayEmptyState(
          icon: Icons.history_edu_rounded,
          title: 'No System Audit Logs Recorded',
          subtitle:
          'Live administrative configuration and security logs from smartvest.tech will appear here.',
        ),
        columns: const [
          DataColumn(label: Text('TIMESTAMP')),
          DataColumn(label: Text('OPERATOR / ROLE')),
          DataColumn(label: Text('CATEGORY')),
          DataColumn(label: Text('ACTION')),
          DataColumn(label: Text('TARGET')),
          DataColumn(label: Text('SEVERITY')),
          DataColumn(label: Text('INSPECT')),
        ],
        rows: filtered.map((l) {
          final ts = (l['timestamp'] ?? '-').toString();
          final op = '${l['operator'] ?? 'admin'} (${l['role'] ?? 'ROOT'})';
          final cat = (l['category'] ?? 'CMS').toString();
          final act = (l['action'] ?? '-').toString();
          final tgt = (l['target'] ?? '-').toString();
          final sev = (l['severity'] ?? 'INFO').toString();

          return DataRow(
            cells: [
              DataCell(Text(ts,
                  style: TextStyle(
                      color: AppConstants.textMuted,
                      fontFamily: 'Consolas',
                      fontSize: 12))),
              DataCell(Text(op,
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w700))),
              DataCell(
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: Text(cat,
                      style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              DataCell(Text(act,
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600))),
              DataCell(Text(tgt,
                  style: TextStyle(
                      color: AppConstants.textSecondary, fontSize: 12.5))),
              DataCell(NexPayStatusBadge(status: sev)),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () {
                    showNexPayInspectorDrawer(
                      context: context,
                      title: 'System Audit Log Entry',
                      subtitle: '$cat • $ts',
                      child: NexPayDetailSection(
                        title: 'Forensic Event Telemetry',
                        children: [
                          NexPayKeyValueRow(label: 'Timestamp', value: ts),
                          NexPayKeyValueRow(label: 'Operator / Role', value: op),
                          NexPayKeyValueRow(label: 'Module Category', value: cat),
                          NexPayKeyValueRow(label: 'Action', value: act),
                          NexPayKeyValueRow(
                              label: 'Target', value: tgt, copyable: true),
                          NexPayKeyValueRow(label: 'Severity', value: sev),
                        ],
                      ),
                      footerActions: [
                        OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close')),
                      ],
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: const Text('Details'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}