import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class SecurityIpWhitelistCmsScreen extends StatefulWidget {
  const SecurityIpWhitelistCmsScreen({super.key});

  @override
  State<SecurityIpWhitelistCmsScreen> createState() =>
      _SecurityIpWhitelistCmsScreenState();
}

class _SecurityIpWhitelistCmsScreenState
    extends State<SecurityIpWhitelistCmsScreen> {
  final _timeoutCtrl = TextEditingController(text: '30');
  final _attemptsCtrl = TextEditingController(text: '5');
  final _lockoutCtrl = TextEditingController(text: '15');
  final _searchCtrl = TextEditingController();
  bool _enforce2Fa = true;
  bool _enforceIp = false;
  bool _init = false;
  String _query = '';

  void _sync(AdminProvider admin) {
    final sec = (admin.cmsConfig['securityPolicy'] is Map)
        ? Map<String, dynamic>.from(admin.cmsConfig['securityPolicy'])
        : <String, dynamic>{};
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
    return raw is List
        ? raw.whereType().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (!_init && admin.cmsConfig.isNotEmpty) _sync(admin);
    final ips = _ips(admin);
    final filtered = ips
        .where((ip) =>
    _query.isEmpty ||
        '${ip['ipAddress']} ${ip['label']}'
            .toLowerCase()
            .contains(_query))
        .toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'IP Whitelist Firewall & Session Security Policy',
        subtitle:
        'Enforce 2FA authentication, session auto-lockout, and static IP access restrictions',
        badgeText: _enforceIp ? 'IP FIREWALL STRICT' : 'STANDARD ACCESS',
        badgeColor:
        _enforceIp ? AppConstants.accentGreen : AppConstants.accentBlue,
        actions: [
          OutlinedButton.icon(
            onPressed: () => _openAddIpDrawer(context, admin, ips),
            icon: const Icon(Icons.add_moderator_rounded, size: 17),
            label: const Text('Whitelist Static IP'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final confirmed = await showNexPayConfirmDialog(
                context: context,
                title: 'Enforce Security Policy',
                message: _enforceIp
                    ? 'Strict Static IP Whitelist Mode is ON. Only listed IP addresses will be allowed console access. Save policy?'
                    : 'Update session timeout, 2FA, and brute-force lockout security policies?',
                confirmLabel: 'Save Security Policy',
              );
              if (!confirmed || !context.mounted) return;
              final ok = await admin.saveCmsConfig({
                'securityPolicy': {
                  'enforce2Fa': _enforce2Fa,
                  'enforceIpWhitelist': _enforceIp,
                  'sessionTimeoutMinutes':
                  int.tryParse(_timeoutCtrl.text.trim()) ?? 30,
                  'maxFailedAttempts':
                  int.tryParse(_attemptsCtrl.text.trim()) ?? 5,
                  'lockoutDurationMinutes':
                  int.tryParse(_lockoutCtrl.text.trim()) ?? 15,
                  'updatedAt': DateTime.now().toIso8601String(),
                },
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                      Text(ok ? 'Security policy saved!' : 'Save failed.'),
                      backgroundColor: ok
                          ? AppConstants.accentGreen
                          : AppConstants.dangerRed),
                );
              }
            },
            icon: const Icon(Icons.shield_rounded, size: 17),
            label: const Text('Save Security Policy'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Operator 2FA Shield',
            value: _enforce2Fa ? 'ENFORCED' : 'OPTIONAL',
            sublabel: 'Multi-factor login verification',
            icon: Icons.verified_user_rounded,
            color: _enforce2Fa
                ? AppConstants.accentGreen
                : AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'IP Firewall Mode',
            value: _enforceIp ? 'STRICT LOCK' : 'STANDARD',
            sublabel: '${ips.length} static IPs authorized',
            icon: Icons.security_rounded,
            color:
            _enforceIp ? AppConstants.accentGreen : AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Idle Auto-Logout',
            value: '${_timeoutCtrl.text} Mins',
            sublabel: 'Automatic terminal session lock',
            icon: Icons.timer_outlined,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Brute-Force Guard',
            value: '${_attemptsCtrl.text} Tries',
            sublabel: '${_lockoutCtrl.text} min lockout on breach',
            icon: Icons.lock_clock_rounded,
            color: AppConstants.dangerRed,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppConstants.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.borderColor),
                boxShadow: AppConstants.cardShadow),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      'Enforce Mandatory Two-Factor Authentication (2FA) for All Operators',
                      style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w700)),
                  value: _enforce2Fa,
                  activeThumbColor: AppConstants.accentGreen,
                  onChanged: (v) => setState(() => _enforce2Fa = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      'Strict Static IP Whitelist Mode (Block Unlisted IP Addresses)',
                      style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w700)),
                  value: _enforceIp,
                  activeThumbColor: AppConstants.accentGreen,
                  onChanged: (v) => setState(() => _enforceIp = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: _timeoutCtrl,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppConstants.textPrimary),
                            decoration: const InputDecoration(
                                labelText: 'Session Auto-Logout (Minutes)'))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: TextField(
                            controller: _attemptsCtrl,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppConstants.textPrimary),
                            decoration: const InputDecoration(
                                labelText: 'Max Failed Login Attempts'))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: TextField(
                            controller: _lockoutCtrl,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppConstants.textPrimary),
                            decoration: const InputDecoration(
                                labelText: 'Lockout Duration (Minutes)'))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          NexPayFilterBar(
            searchController: _searchCtrl,
            searchHint: 'Search whitelisted IP address or office label...',
            onSearchChanged: (v) =>
                setState(() => _query = v.trim().toLowerCase()),
            filters: const ['ALL'],
            selectedFilter: 'ALL',
            onFilterChanged: (_) {},
            resultSummary: '${filtered.length} whitelisted IPs',
          ),
          const SizedBox(height: 14),
          NexPayFullWidthTable(
            minTableWidth: 960,
            emptyState: const NexPayEmptyState(
              icon: Icons.lan_outlined,
              title: 'No Whitelisted IP Addresses',
              subtitle:
              'Click "Whitelist Static IP" above to authorize office or VPN IP addresses.',
            ),
            columns: const [
              DataColumn(label: Text('IP ADDRESS / CIDR')),
              DataColumn(label: Text('LOCATION / LABEL')),
              DataColumn(label: Text('ADDED AT')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTION')),
            ],
            rows: filtered.map((ip) {
              final addr = (ip['ipAddress'] ?? '').toString();
              return DataRow(
                cells: [
                  DataCell(
                      NexPayCopyableId(text: addr, label: 'IP Address')),
                  DataCell(Text((ip['label'] ?? '').toString(),
                      style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w600))),
                  DataCell(Text((ip['addedAt'] ?? '-').toString(),
                      style: TextStyle(
                          color: AppConstants.textMuted, fontSize: 12))),
                  DataCell(NexPayStatusBadge(
                      status: (ip['status'] ?? 'ACTIVE').toString())),
                  DataCell(
                    IconButton(
                      tooltip: 'Remove IP',
                      icon: Icon(Icons.delete_outline_rounded,
                          color: AppConstants.dangerRed, size: 19),
                      onPressed: () async {
                        final confirmed = await showNexPayConfirmDialog(
                          context: context,
                          title: 'Remove Whitelisted IP',
                          message:
                          'Revoke console firewall authorization for $addr?',
                          confirmLabel: 'Remove IP',
                          confirmColor: AppConstants.dangerRed,
                        );
                        if (!confirmed || !context.mounted) return;
                        final updated =
                        ips.where((x) => x['id'] != ip['id']).toList();
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

  void _openAddIpDrawer(BuildContext context, AdminProvider admin,
  List ips) {
  final ipCtrl = TextEditingController();
  final labelCtrl = TextEditingController();
  showNexPayInspectorDrawer(
  context: context,
  title: 'Authorize Static IP Address',
  subtitle:
  'Add an approved IPv4/IPv6 address to the admin firewall whitelist',
  child: Column(
  children: [
  TextField(
  controller: ipCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Static IP Address (e.g. 182.176.44.12)')),
  const SizedBox(height: 12),
  TextField(
  controller: labelCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText:
  'Office / Terminal Label (e.g. Head Office Fiber)')),
  ],
  ),
  footerActions: [
  OutlinedButton(
  onPressed: () => Navigator.pop(context),
  child: const Text('Cancel')),
  ElevatedButton(
  onPressed: () async {
  if (ipCtrl.text.trim().isEmpty) return;
  Navigator.pop(context);
  final updated = List.from(ips)
  ..add({
  'id': 'ip_${DateTime.now().millisecondsSinceEpoch}',
  'ipAddress': ipCtrl.text.trim(),
  'label': labelCtrl.text.trim().isEmpty
  ? 'Authorized Terminal'
      : labelCtrl.text.trim(),
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