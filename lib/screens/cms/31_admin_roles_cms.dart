import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class AdminRolesCmsScreen extends StatefulWidget {
  const AdminRolesCmsScreen({super.key});

  @override
  State<AdminRolesCmsScreen> createState() => _AdminRolesCmsScreenState();
}

class _AdminRolesCmsScreenState extends State<AdminRolesCmsScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _list(AdminProvider admin) {
    final raw = admin.cmsConfig['adminStaff'];
    return raw is List ? raw.whereType().map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final staff = _list(admin);
    final filtered = staff.where((s) {
      final st = (s['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (_filter == 'ACTIVE' && st != 'ACTIVE') return false;
      if (_filter == 'SUSPENDED' && st == 'ACTIVE') return false;
      if (_query.isEmpty) return true;
      return '${s['name']} ${s['username']} ${s['email']} ${s['role']}'.toLowerCase().contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Administrative Staff RBAC & Role Permissions',
        subtitle: 'Provision internal compliance officers, treasury operators, and granular module access permissions',
        badgeText: '${staff.length} OPERATORS',
        badgeColor: AppConstants.accentBlue,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _openDrawer(context, admin, staff, null),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
            label: const Text('Add Staff Operator'),
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search operator by name, username, email, or role...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'ACTIVE', 'SUSPENDED'],
        selectedFilter: _filter,
        onFilterChanged: (f) => setState(() => _filter = f),
        resultSummary: 'Showing ${filtered.length} of ${staff.length} operators',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const InstitutionalEmptyState(
          icon: Icons.admin_panel_settings_outlined,
          title: 'No Additional Admin Staff Configured',
          subtitle: 'Click "Add Staff Operator" above to create role-based sub-admin accounts.',
        ),
        columns: const [
          DataColumn(label: Text('OPERATOR NAME')),
          DataColumn(label: Text('USERNAME / EMAIL')),
          DataColumn(label: Text('ASSIGNED ROLE')),
          DataColumn(label: Text('LAST LOGIN')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('RBAC CONTROLS')),
        ],
        rows: filtered.map((s) {
          return DataRow(
            cells: [
              DataCell(Text((s['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text('${s['username'] ?? '-'} • ${s['email'] ?? '-'}', style: const TextStyle(fontSize: 12.5))),
              DataCell(Text((s['role'] ?? 'TREASURY_OFFICER').toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.accentBlue))),
              DataCell(Text((s['lastLogin'] ?? 'Never').toString(), style: const TextStyle(color: AppConstants.textMuted, fontSize: 12))),
              DataCell(NexPayStatusBadge(status: (s['status'] ?? 'ACTIVE').toString())),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(onPressed: () => _openDrawer(context, admin, staff, s), child: const Text('Permissions')),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.dangerRed, size: 19),
                      onPressed: () async {
                        final updated = staff.where((x) => x['id'] != s['id']).toList();
                        await admin.saveCmsConfig({'adminStaff': updated});
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openDrawer(BuildContext context, AdminProvider admin, List staff, Map<String, dynamic>? existing) {
  final isEdit = existing != null;
  final nameCtrl = TextEditingController(text: (existing?['name'] ?? '').toString());
  final userCtrl = TextEditingController(text: (existing?['username'] ?? '').toString());
  final emailCtrl = TextEditingController(text: (existing?['email'] ?? '').toString());
  final roleCtrl = TextEditingController(text: (existing?['role'] ?? 'COMPLIANCE_OFFICER').toString());
  final perms = (existing?['permissions'] is Map) ? Map<String, dynamic>.from(existing!['permissions']) : <String, dynamic>{};

  bool canPayouts = perms['canApprovePayouts'] == true;
  bool canBalances = perms['canAdjustBalances'] == true;
  bool canKyc = perms['canReviewKyc'] != false;
  bool canFreeze = perms['canFreezeUsers'] == true;
  bool canCms = perms['canEditCms'] == true;
  bool canAudit = perms['canClearAuditLogs'] == true;
  bool active = existing == null || (existing['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';

  showNexPayInspectorDrawer(
  context: context,
  title: isEdit ? 'Edit Staff RBAC: ${nameCtrl.text}' : 'Provision Admin Staff Operator',
  subtitle: 'Configure role credentials and module-level security permissions',
  child: StatefulBuilder(
  builder: (ctx, setS) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(child: TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Operator Username'))),
  const SizedBox(width: 12),
  Expanded(child: TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role Title'))),
  ],
  ),
  const SizedBox(height: 12),
  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Official Email')),
  const Divider(height: 24),
  const Text('GRANULAR SECURITY PERMISSIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppConstants.textMuted)),
  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Approve IBFT Payouts & Deposits'), value: canPayouts, activeThumbColor: AppConstants.accentGreen, onChanged: (v) => setS(() => canPayouts = v)),
  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Credit / Debit Customer Wallets'), value: canBalances, activeThumbColor: AppConstants.accentGreen, onChanged: (v) => setS(() => canBalances = v)),
  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Review & Approve Biometric KYC'), value: canKyc, activeThumbColor: AppConstants.accentGreen, onChanged: (v) => setS(() => canKyc = v)),
  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Freeze / Unfreeze User Accounts'), value: canFreeze, activeThumbColor: AppConstants.accentGreen, onChanged: (v) => setS(() => canFreeze = v)),
  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Modify System CMS & Rates'), value: canCms, activeThumbColor: AppConstants.accentGreen, onChanged: (v) => setS(() => canCms = v)),
  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Clear Forensic Audit Logs'), value: canAudit, activeThumbColor: AppConstants.accentGreen, onChanged: (v) => setS(() => canAudit = v)),
  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Account Active (Uncheck to Suspend)'), value: active, activeThumbColor: AppConstants.accentGreen, onChanged: (v) => setS(() => active = v)),
  ],
  ),
  ),
  footerActions: [
  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
  const SizedBox(width: 12),
  ElevatedButton(
  onPressed: () async {
  if (nameCtrl.text.trim().isEmpty) return;
  Navigator.pop(context);
  final obj = {
  'id': isEdit ? existing['id'] : 'staff_${DateTime.now().millisecondsSinceEpoch}',
  'name': nameCtrl.text.trim(),
  'username': userCtrl.text.trim(),
  'email': emailCtrl.text.trim(),
  'role': roleCtrl.text.trim(),
  'lastLogin': existing?['lastLogin'] ?? 'Never',
  'status': active ? 'ACTIVE' : 'SUSPENDED',
  'permissions': {
  'canApprovePayouts': canPayouts,
  'canAdjustBalances': canBalances,
  'canReviewKyc': canKyc,
  'canFreezeUsers': canFreeze,
  'canEditCms': canCms,
  'canClearAuditLogs': canAudit,
  },
  };
  final updated = List.from(staff);
  if (isEdit) {
  final idx = updated.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) updated[idx] = obj;
  } else {
  updated.add(obj);
  }
  await admin.saveCmsConfig({'adminStaff': updated});
  },
  child: const Text('Save Operator'),
  ),
  ],
  );
  }
}