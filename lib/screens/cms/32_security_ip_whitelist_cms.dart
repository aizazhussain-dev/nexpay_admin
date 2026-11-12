import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class SecurityIpWhitelistCmsScreen extends StatefulWidget {
  const SecurityIpWhitelistCmsScreen({super.key});

  @override
  State<SecurityIpWhitelistCmsScreen> createState() => _SecurityIpWhitelistCmsScreenState();
}

class _SecurityIpWhitelistCmsScreenState extends State<SecurityIpWhitelistCmsScreen> {
  final _timeoutCtrl = TextEditingController(text: '30');
  final _attemptsCtrl = TextEditingController(text: '5');
  final _lockoutCtrl = TextEditingController(text: '15');
  final _searchCtrl = TextEditingController();
  bool _enforce2Fa = true;
  bool _enforceIp = false;
  bool _init = false;
  String _query = '';

  void _sync(AdminProvider admin) {
    final sec = (admin.cmsConfig['securityPolicy'] is Map) ? Map<String, dynamic>.from(admin.cmsConfig['securityPolicy']) : <String, dynamic>{};
    _enforce2Fa = sec['enforce2Fa'] != false;
    _enforceIp = sec['enforceIpWhitelist'] == true;
    _timeoutCtrl.text = (sec['sessionTimeoutMinutes'] ?? 30).toString();
    _attemptsCtrl.text = (sec['maxFailedAttempts'] ?? 5).toString();
    _lockoutCtrl.text = (sec['lockoutDurationMinutes'] ?? 15).toString();
    _init = true;
  }

  @override
  void dispose() {
    _timeoutCtrl.dispose();
    _attemptsCtrl.dispose();
    _lockoutCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List _ips(AdminProvider admin) {
    final raw = admin.cmsConfig['whitelistedIps'];
    return raw is List ? raw.whereType().map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (!_init && admin.cmsConfig.isNotEmpty) _sync(admin);
    final ips = _ips(admin);
    final filtered = ips.where((ip) => _query.isEmpty || '${ip['ipAddress']} ${ip['label']}'.toLowerCase().contains(_query)).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'IP Whitelist Firewall & Session Security Policy',
        subtitle: 'Enforce 2FA authentication, session auto-lockout, and static IP access restrictions',
        badgeText: _enforceIp ? 'IP FIREWALL STRICT' : 'STANDARD ACCESS',
        badgeColor: _enforceIp ? AppConstants.accentGreen : AppConstants.accentBlue,
        actions: [
          OutlinedButton.icon(
            onPressed: () => _openAddIpDrawer(context, admin, ips),
            icon: const Icon(Icons.add_moderator_rounded, size: 17),
            label: const Text('Whitelist Static IP'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final ok = await admin.saveCmsConfig({
                'securityPolicy': {
                  'enforce2Fa': _enforce2Fa,
                  'enforceIpWhitelist': _enforceIp,
                  'sessionTimeoutMinutes': int.tryParse(_timeoutCtrl.text.trim()) ?? 30,
                  'maxFailedAttempts': int.tryParse(_attemptsCtrl.text.trim()) ?? 5,
                  'lockoutDurationMinutes': int.tryParse(_lockoutCtrl.text.trim()) ?? 15,
                  'updatedAt': DateTime.now().toIso8601String(),
                },
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Security policy saved!' : 'Save failed.'), backgroundColor: ok ? AppConstants.accentGreen : AppConstants.dangerRed),
                );
              }
            },
            icon: const Icon(Icons.shield_rounded, size: 17),
            label: const Text('Save Security Policy'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppConstants.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppConstants.borderColor)),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enforce Mandatory Two-Factor Authentication (2FA) for All Operators', style: TextStyle(fontWeight: FontWeight.w700)),
                  value: _enforce2Fa,
                  activeThumbColor: AppConstants.accentGreen,
                  onChanged: (v) => setState(() => _enforce2Fa = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Strict Static IP Whitelist Mode (Block Unlisted IP Addresses)', style: TextStyle(fontWeight: FontWeight.w700)),
                  value: _enforceIp,
                  activeThumbColor: AppConstants.accentGreen,
                  onChanged: (v) => setState(() => _enforceIp = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _timeoutCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Session Auto-Logout (Minutes)'))),
                    const SizedBox(width: 14),
                    Expanded(child: TextField(controller: _attemptsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Failed Login Attempts'))),
                    const SizedBox(width: 14),
                    Expanded(child: TextField(controller: _lockoutCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Lockout Duration (Minutes)'))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          NexPayFilterBar(
            searchController: _searchCtrl,
            searchHint: 'Search whitelisted IP address or office label...',
            onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            filters: const ['ALL'],
            selectedFilter: 'ALL',
            onFilterChanged: (_) {},
            resultSummary: '${filtered.length} whitelisted IPs',
          ),
          const SizedBox(height: 14),
          NexPayFullWidthTable(
            minTableWidth: 960,
            emptyState: const InstitutionalEmptyState(
              icon: Icons.lan_outlined,
              title: 'No Whitelisted IP Addresses',
              subtitle: 'Click "Whitelist Static IP" above to authorize office or VPN IP addresses.',
            ),
            columns: const [
              DataColumn(label: Text('IP ADDRESS / CIDR')),
              DataColumn(label: Text('LOCATION / LABEL')),
              DataColumn(label: Text('ADDED AT')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTION')),
            ],
            rows: filtered.map((ip) {
              return DataRow(
                cells: [
                  DataCell(Text((ip['ipAddress'] ?? '').toString(), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppConstants.accentBlue))),
                  DataCell(Text((ip['label'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text((ip['addedAt'] ?? '-').toString(), style: const TextStyle(color: AppConstants.textMuted, fontSize: 12))),
                  DataCell(NexPayStatusBadge(status: (ip['status'] ?? 'ACTIVE').toString())),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.dangerRed, size: 19),
                      onPressed: () async {
                        final updated = ips.where((x) => x['id'] != ip['id']).toList();
                        await admin.saveCmsConfig({'whitelistedIps': updated});
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _openAddIpDrawer(BuildContext context, AdminProvider admin, List ips) {
    final ipCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    showNexPayInspectorDrawer(
      context: context,
      title: 'Authorize Static IP Address',
      subtitle: 'Add an approved IPv4/IPv6 address to the admin firewall whitelist',
      child: Column(
        children: [
          TextField(controller: ipCtrl, decoration: const InputDecoration(labelText: 'Static IP Address (e.g. 182.176.44.12)')),
          const SizedBox(height: 12),
          TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Office / Terminal Label (e.g. Head Office Fiber)')),
        ],
      ),
      footerActions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () async {
            if (ipCtrl.text.trim().isEmpty) return;
            Navigator.pop(context);
            final updated = List.from(ips)
              ..add({
                'id': 'ip_${DateTime.now().millisecondsSinceEpoch}',
                'ipAddress': ipCtrl.text.trim(),
                'label': labelCtrl.text.trim().isEmpty ? 'Authorized Terminal' : labelCtrl.text.trim(),
                'status': 'ACTIVE',
                'addedAt': DateTime.now().toIso8601String(),
              });
            await admin.saveCmsConfig({'whitelistedIps': updated});
          },
          child: const Text('Add IP'),
        ),
      ],
    );
  }
}