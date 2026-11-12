import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class SecurityIpWhitelistCmsScreen extends StatefulWidget {
  const SecurityIpWhitelistCmsScreen({super.key});

  @override
  State<SecurityIpWhitelistCmsScreen> createState() => _SecurityIpWhitelistCmsScreenState();
}

class _SecurityIpWhitelistCmsScreenState extends State<SecurityIpWhitelistCmsScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _sessionTimeoutController;
  late TextEditingController _maxFailedAttemptsController;
  late TextEditingController _lockoutDurationController;

  bool _enforce2Fa = true;
  bool _enforceIpWhitelist = false;
  List _whitelistedIps = [];

  String _searchQuery = "";
  bool _isSaving = false;
  bool _isInitialized = false;

  // Default IP Whitelist fallback
  final List _defaultIps = [
  {
  'id': 'ip_office_primary',
  'ipAddress': '182.185.120.45',
  'label': 'Main Head Office Static Fiber',
  'status': 'ACTIVE',
  'addedAt': '2026-01-10',
  },
  {
  'id': 'ip_cloud_gateway',
  'ipAddress': '104.28.19.102',
  'label': 'Cloudflare Origin Gateway Node',
  'status': 'ACTIVE',
  'addedAt': '2026-02-15',
  },
  {
  'id': 'ip_vpn_tunnel',
  'ipAddress': '172.16.0.1/24',
  'label': 'Internal Ops WireGuard VPN Subnet',
  'status': 'ACTIVE',
  'addedAt': '2026-03-01',
  },
  ];

  @override
  void initState() {
    super.initState();
    _sessionTimeoutController = TextEditingController();
    _maxFailedAttemptsController = TextEditingController();
    _lockoutDurationController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadConfigFromProvider();
      _isInitialized = true;
    }
  }

  void _loadConfigFromProvider() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;

    final sec = (cfg['securityPolicy'] is Map)
        ? Map<String, dynamic>.from(cfg['securityPolicy'])
        : <String, dynamic>{};

    _enforce2Fa = sec['enforce2Fa'] ?? true;
    _enforceIpWhitelist = sec['enforceIpWhitelist'] ?? false;
    _sessionTimeoutController.text = (sec['sessionTimeoutMinutes'] ?? 30).toString();
    _maxFailedAttemptsController.text = (sec['maxFailedAttempts'] ?? 5).toString();
    _lockoutDurationController.text = (sec['lockoutDurationMinutes'] ?? 15).toString();

    if (cfg['whitelistedIps'] is List && (cfg['whitelistedIps'] as List).isNotEmpty) {
      final list = (cfg['whitelistedIps'] as List)
          .whereType()
          .map((ip) => Map<String, dynamic>.from(ip))
          .toList();
      setState(() => _whitelistedIps = list);
    } else {
      setState(() {
        _whitelistedIps = _defaultIps.map((ip) => Map<String, dynamic>.from(ip)).toList();
      });
    }
  }

  @override
  void dispose() {
    _sessionTimeoutController.dispose();
    _maxFailedAttemptsController.dispose();
    _lockoutDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredIps = _whitelistedIps.where((ip) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final addr = (ip['ipAddress'] ?? '').toString().toLowerCase();
        final label = (ip['label'] ?? '').toString().toLowerCase();
        return addr.contains(q) || label.contains(q);
      }
      return true;
    }).toList();

    int activeIpsCount = _whitelistedIps.where((ip) => (ip['status'] ?? 'ACTIVE') == 'ACTIVE').length;

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
                          "System Security, 2FA & IP Whitelist CMS",
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: (_enforceIpWhitelist ? AppConstants.dangerRed : AppConstants.accentGreen).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (_enforceIpWhitelist ? AppConstants.dangerRed : AppConstants.accentGreen).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _enforceIpWhitelist ? "● IP SHIELD ACTIVE" : "○ OPEN ACCESS (ALL IPS)",
                            style: TextStyle(
                              color: _enforceIpWhitelist ? AppConstants.dangerRed : AppConstants.accentGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Enforce console operator Two-Factor Authentication, subnet whitelists, and brute-force lockout rules",
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
                      foregroundColor: Color(0xFF021A13),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openAddEditIpDialog(context, null, admin),
                    icon: const Icon(Icons.add_moderator_rounded, size: 18),
                    label: const Text("Authorize New IP", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFF94A3B8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _loadConfigFromProvider();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✓ Reloaded security policies from memory.")),
                      );
                    },
                    icon: const Icon(Icons.sync_rounded, size: 18, color: AppConstants.accentGreen),
                    label: const Text("Sync Memory", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
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
              _buildMetricCard(
                "2FA OPERATOR STATUS",
                _enforce2Fa ? "MANDATORY (ON)" : "OPTIONAL (OFF)",
                _enforce2Fa ? AppConstants.accentGreen : Colors.amber,
                isDesktop,
              ),
              _buildMetricCard(
                "IP WHITELIST SHIELD",
                _enforceIpWhitelist ? "RESTRICTED (LIVE)" : "BYPASS (ANY IP)",
                _enforceIpWhitelist ? AppConstants.dangerRed : AppConstants.accentGreen,
                isDesktop,
              ),
              _buildMetricCard(
                "AUTHORIZED IP NODES",
                "$activeIpsCount IPs Allowed",
                AppConstants.accentBlue,
                isDesktop,
              ),
              _buildMetricCard(
                "SESSION INACTIVITY TIMEOUT",
                "${_sessionTimeoutController.text} Minutes",
                Color(0xFFA855F7),
                isDesktop,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Screen Sections
          Expanded(
            child: SingleChildScrollView(
              child: isDesktop ? _buildDesktopLayout(admin, filteredIps) : _buildMobileLayout(admin, filteredIps),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(AdminProvider admin, List filteredIps) {
  return Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  // Left Column: Security Policy & Thresholds
  Expanded(
  flex: 5,
  child: _buildPolicySettingsCard(admin),
  ),
  const SizedBox(width: 20),
  // Right Column: Whitelisted IPs Registry
  Expanded(
  flex: 6,
  child: _buildIpRegistryCard(admin, filteredIps),
  ),
  ],
  );
  }

  Widget _buildMobileLayout(AdminProvider admin, List filteredIps) {
  return Column(
  children: [
  _buildPolicySettingsCard(admin),
  const SizedBox(height: 20),
  _buildIpRegistryCard(admin, filteredIps),
  ],
  );
  }

  // Security Policy & Brute-Force Defense Card
  Widget _buildPolicySettingsCard(AdminProvider admin) {
  return Container(
  padding: const EdgeInsets.all(22),
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: Color(0xFFE2E8F0)),
  ),
  child: Form(
  key: _formKey,
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  children: const [
  Icon(Icons.security_rounded, color: AppConstants.accentGreen, size: 22),
  SizedBox(width: 8),
  Text(
  "CONSOLE ACCESS SECURITY POLICY",
  style: TextStyle(
  color: AppConstants.accentGreen,
  fontSize: 12.5,
  fontWeight: FontWeight.w900,
  letterSpacing: 0.8,
  ),
  ),
  ],
  ),
  const SizedBox(height: 18),

  // 2FA Mandatory Switch
  _buildSwitchTile(
  title: "Mandatory Operator Two-Factor (2FA)",
  subtitle: "Staff login par OTP verification code lazmi mangega.",
  value: _enforce2Fa,
  activeColor: AppConstants.accentGreen,
  onChanged: (v) => setState(() => _enforce2Fa = v),
  ),
  const Divider(color: Color(0xFFE2E8F0), height: 22),

  // IP Whitelist Strict Mode Switch
  _buildSwitchTile(
  title: "Enforce Strict IP Whitelisting Shield",
  subtitle: "Sirf neeche diye gaye authorized IPs se hi console access allow hogi.",
  value: _enforceIpWhitelist,
  activeColor: AppConstants.dangerRed,
  onChanged: (v) => setState(() => _enforceIpWhitelist = v),
  ),
  const Divider(color: Color(0xFFE2E8F0), height: 22),

  // Session Timeout
  TextFormField(
  controller: _sessionTimeoutController,
  keyboardType: TextInputType.number,
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
  decoration: InputDecoration(
  labelText: "INACTIVITY AUTO-LOGOUT (MINUTES)",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "30",
  suffixText: "Mins",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  onChanged: (_) => setState(() {}),
  validator: (v) {
  final n = int.tryParse(v ?? '');
  return (n == null || n < 5) ? "Min timeout is 5 minutes" : null;
  },
  ),
  const SizedBox(height: 14),

  // Failed Attempts & Lockout Row
  Row(
  children: [
  Expanded(
  child: TextFormField(
  controller: _maxFailedAttemptsController,
  keyboardType: TextInputType.number,
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
  decoration: InputDecoration(
  labelText: "MAX FAILED LOGINS",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "5",
  suffixText: "Tries",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  validator: (v) => (int.tryParse(v ?? '') == null) ? "Invalid" : null,
  ),
  ),
  const SizedBox(width: 12),
  Expanded(
  child: TextFormField(
  controller: _lockoutDurationController,
  keyboardType: TextInputType.number,
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
  decoration: InputDecoration(
  labelText: "LOCKOUT DURATION",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "15",
  suffixText: "Mins",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  validator: (v) => (int.tryParse(v ?? '') == null) ? "Invalid" : null,
  ),
  ),
  ],
  ),
  const SizedBox(height: 24),

  // Deploy Policy Button
  SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: AppConstants.accentGreen,
  foregroundColor: Color(0xFF021A13),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  onPressed: _isSaving ? null : () => _saveSecurityPolicy(admin),
  icon: _isSaving
  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF021A13), strokeWidth: 2))
      : const Icon(Icons.shield_rounded, size: 20),
  label: Text(
  _isSaving ? "Deploying Security Rules..." : "Save & Enforce Security Policy",
  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
  ),
  ),
  ),
  ],
  ),
  ),
  );
  }

  // Whitelisted IPs Registry Card
  Widget _buildIpRegistryCard(AdminProvider admin, List list) {
  return Container(
  padding: const EdgeInsets.all(22),
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: Color(0xFFE2E8F0)),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Row(
  children: const [
  Icon(Icons.lan_rounded, color: AppConstants.accentBlue, size: 22),
  SizedBox(width: 8),
  Text(
  "AUTHORIZED IP ADDRESS WHITELIST",
  style: TextStyle(
  color: AppConstants.accentBlue,
  fontSize: 12.5,
  fontWeight: FontWeight.w900,
  letterSpacing: 0.8,
  ),
  ),
  ],
  ),
  Text("${list.length} Node(s)", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
  ],
  ),
  const SizedBox(height: 14),

  // Search Field
  TextField(
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5),
  decoration: InputDecoration(
  hintText: "Search IP Address or Location Label...",
  hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5),
  prefixIcon: const Icon(Icons.search_rounded, color: AppConstants.textMuted, size: 18),
  filled: true,
  fillColor: AppConstants.surfaceCard,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  onChanged: (val) => setState(() => _searchQuery = val.trim()),
  ),
  const SizedBox(height: 14),

  // List of IPs
  list.isEmpty
  ? Container(
  padding: const EdgeInsets.all(20),
  child: const Center(
  child: Text(
  "No whitelisted IP nodes matching criteria.",
  style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
  ),
  ),
  )
      : ListView.separated(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: list.length,
  separatorBuilder: (_, __) => const SizedBox(height: 8),
  itemBuilder: (ctx, idx) {
  final item = list[idx];
  final isActive = (item['status'] ?? 'ACTIVE') == 'ACTIVE';

  return Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
  color: isActive ? AppConstants.accentBlue.withValues(alpha: 0.25) : Color(0xFFE2E8F0),
  ),
  ),
  child: Row(
  children: [
  Icon(
  Icons.dns_rounded,
  color: isActive ? AppConstants.accentBlue : AppConstants.textMuted,
  size: 20,
  ),
  const SizedBox(width: 12),
  Expanded(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text(
  item['ipAddress'] ?? '0.0.0.0',
  style: const TextStyle(
  color: Color(0xFF0F172A),
  fontFamily: 'monospace',
  fontWeight: FontWeight.w900,
  fontSize: 13,
  ),
  ),
  const SizedBox(height: 2),
  Text(
  item['label'] ?? '-',
  style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  ),
  ],
  ),
  ),
  IconButton(
  icon: Icon(
  isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
  color: isActive ? AppConstants.accentGreen : AppConstants.textMuted,
  size: 26,
  ),
  tooltip: isActive ? "Deactivate IP" : "Activate IP",
  onPressed: () => _toggleIpStatus(item, admin),
  ),
  IconButton(
  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.dangerRed),
  tooltip: "Remove IP",
  onPressed: () => _confirmDeleteIp(context, item, admin),
  ),
  ],
  ),
  );
  },
  ),
  ],
  ),
  );
  }

  Widget _buildSwitchTile({
  required String title,
  required String subtitle,
  required bool value,
  required Color activeColor,
  required ValueChanged<bool> onChanged,
  }) {
  return Row(
  children: [
  Expanded(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
  const SizedBox(height: 2),
  Text(subtitle, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
  ],
  ),
  ),
  Switch(
  value: value,
  activeColor: activeColor,
  onChanged: onChanged,
  ),
  ],
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
  Text(value, style: TextStyle(color: color, fontSize: 15.5, fontWeight: FontWeight.w900)),
  ],
  ),
  );
  }

  // Add / Edit Whitelisted IP Modal
  void _openAddEditIpDialog(BuildContext context, Map<String, dynamic>? existing, AdminProvider admin) {
  final ipController = TextEditingController(text: existing != null ? existing['ipAddress'] : '');
  final labelController = TextEditingController(text: existing != null ? existing['label'] : '');

  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: const Text("Authorize IP / Subnet", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18)),
  content: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
  TextField(
  controller: ipController,
  style: const TextStyle(color: Color(0xFF0F172A), fontFamily: 'monospace', fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "IP ADDRESS OR CIDR BLOCK",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. 182.185.120.45 or 192.168.1.0/24",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  const SizedBox(height: 12),
  TextField(
  controller: labelController,
  style: const TextStyle(color: Color(0xFF0F172A)),
  decoration: InputDecoration(
  labelText: "IDENTIFIER / LOCATION LABEL",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. Hyderabad Ops Center Static Fiber",
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
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: Color(0xFF021A13)),
  onPressed: () async {
  final ip = ipController.text.trim();
  final label = labelController.text.trim();
  if (ip.isEmpty) return;

  Navigator.pop(ctx);

  final newEntry = {
  'id': 'ip_${DateTime.now().millisecondsSinceEpoch}',
  'ipAddress': ip,
  'label': label.isNotEmpty ? label : 'Authorized Operator Node',
  'status': 'ACTIVE',
  'addedAt': DateTime.now().toIso8601String().split('T').first,
  };

  final updated = List.from(_whitelistedIps)..add(newEntry);
  await _saveIpsList(updated, admin);
  },
  child: const Text("Authorize Node", style: TextStyle(fontWeight: FontWeight.w900)),
  ),
  ],
  ),
  );
  }

  // Toggle IP Status
  Future<void> _toggleIpStatus(Map<String, dynamic> item, AdminProvider admin) async {
  final currentStatus = (item['status'] ?? 'ACTIVE').toString().toUpperCase();
  final newStatus = currentStatus == 'ACTIVE' ? 'DISABLED' : 'ACTIVE';

  final updated = List.from(_whitelistedIps);
  final idx = updated.indexWhere((x) => x['id'] == item['id']);
  if (idx != -1) {
  updated[idx]['status'] = newStatus;
  await _saveIpsList(updated, admin);
  }
  }

  // Delete IP Node
  void _confirmDeleteIp(BuildContext context, Map<String, dynamic> item, AdminProvider admin) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: const Text("Remove Authorized IP?", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w900)),
  content: Text("Kya aap waqai node ${item['ipAddress']} (${item['label']}) ki console access revoke karna chahte hain?", style: const TextStyle(color: AppConstants.textMuted)),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Color(0xFF0F172A)),
  onPressed: () async {
  Navigator.pop(ctx);
  final updated = List.from(_whitelistedIps)
  ..removeWhere((x) => x['id'] == item['id']);
  await _saveIpsList(updated, admin);
  },
  child: const Text("Revoke Access"),
  ),
  ],
  ),
  );
  }

  Future<void> _saveIpsList(List updated, AdminProvider admin) async {
  setState(() => _isSaving = true);
  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'save_config'},
  data: {'whitelistedIps': updated},
  );

  if (res.data['status'] == 'success') {
  setState(() => _whitelistedIps = updated);
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ Whitelisted IP nodes updated live!", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }
  }
  } catch (_) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Failed to update IP whitelist.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isSaving = false);
  }
  }

  Future<void> _saveSecurityPolicy(AdminProvider admin) async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSaving = true);

  final policy = {
  'enforce2Fa': _enforce2Fa,
  'enforceIpWhitelist': _enforceIpWhitelist,
  'sessionTimeoutMinutes': int.tryParse(_sessionTimeoutController.text.trim()) ?? 30,
  'maxFailedAttempts': int.tryParse(_maxFailedAttemptsController.text.trim()) ?? 5,
  'lockoutDurationMinutes': int.tryParse(_lockoutDurationController.text.trim()) ?? 15,
  'updatedAt': DateTime.now().toIso8601String(),
  };

  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'save_config'},
  data: {'securityPolicy': policy},
  );

  if (res.data['status'] == 'success') {
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ Security policy & lockout parameters enforced live!", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }
  }
  } catch (_) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Failed to deploy security policy.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isSaving = false);
  }
  }
}
