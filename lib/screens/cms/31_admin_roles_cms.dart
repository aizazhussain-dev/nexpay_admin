import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class AdminRolesCmsScreen extends StatefulWidget {
  const AdminRolesCmsScreen({super.key});

  @override
  State<AdminRolesCmsScreen> createState() => _AdminRolesCmsScreenState();
}

class _AdminRolesCmsScreenState extends State<AdminRolesCmsScreen> {
  final ApiClient _api = ApiClient();

  List _staffList = [];
  String _searchQuery = "";
  String _roleFilter = "ALL"; // ALL, SUPER_ADMIN, TREASURY, COMPLIANCE, SUPPORT
  String _statusFilter = "ALL"; // ALL, ACTIVE, SUSPENDED
  bool _isSaving = false;
  bool _isInitialized = false;

  // Default internal security roles fallback
  final List _defaultStaff = [
  {
  'id': 'staff_super_root',
  'name': 'Master Administrator',
  'email': 'admin@nexpay.vip',
  'username': 'root_admin',
  'role': 'SUPER_ADMIN',
  'status': 'ACTIVE',
  'lastLogin': '10 mins ago',
  'permissions': {
  'canApprovePayouts': true,
  'canAdjustBalances': true,
  'canReviewKyc': true,
  'canFreezeUsers': true,
  'canEditCms': true,
  'canClearAuditLogs': true,
  },
  },
  {
  'id': 'staff_treasury_01',
  'name': 'Hamza Ali (Treasury Lead)',
  'email': 'treasury@nexpay.vip',
  'username': 'hamza_treasury',
  'role': 'TREASURY',
  'status': 'ACTIVE',
  'lastLogin': '2 hours ago',
  'permissions': {
  'canApprovePayouts': true,
  'canAdjustBalances': false,
  'canReviewKyc': false,
  'canFreezeUsers': false,
  'canEditCms': true,
  'canClearAuditLogs': false,
  },
  },
  {
  'id': 'staff_compliance_02',
  'name': 'Fatima Zahra (AML / KYC Officer)',
  'email': 'compliance@nexpay.vip',
  'username': 'fatima_aml',
  'role': 'COMPLIANCE',
  'status': 'ACTIVE',
  'lastLogin': 'Yesterday, 04:30 PM',
  'permissions': {
  'canApprovePayouts': false,
  'canAdjustBalances': false,
  'canReviewKyc': true,
  'canFreezeUsers': true,
  'canEditCms': false,
  'canClearAuditLogs': false,
  },
  },
  {
  'id': 'staff_support_03',
  'name': 'Usman Tariq (Helpdesk Ops)',
  'email': 'support@nexpay.vip',
  'username': 'usman_helpdesk',
  'role': 'SUPPORT',
  'status': 'ACTIVE',
  'lastLogin': '3 days ago',
  'permissions': {
  'canApprovePayouts': false,
  'canAdjustBalances': false,
  'canReviewKyc': false,
  'canFreezeUsers': false,
  'canEditCms': false,
  'canClearAuditLogs': false,
  },
  },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadStaffFromProvider();
      _isInitialized = true;
    }
  }

  void _loadStaffFromProvider() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;

    if (cfg['adminStaff'] is List && (cfg['adminStaff'] as List).isNotEmpty) {
      final list = (cfg['adminStaff'] as List)
          .whereType()
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
      setState(() => _staffList = list);
    } else {
      setState(() {
        _staffList = _defaultStaff.map((s) => Map<String, dynamic>.from(s)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredList = _staffList.where((s) {
      final role = (s['role'] ?? 'SUPPORT').toString().toUpperCase();
      final status = (s['status'] ?? 'ACTIVE').toString().toUpperCase();

      if (_roleFilter != "ALL" && role != _roleFilter) return false;
      if (_statusFilter == "ACTIVE" && status != "ACTIVE") return false;
      if (_statusFilter == "SUSPENDED" && status != "SUSPENDED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (s['name'] ?? '').toString().toLowerCase();
        final email = (s['email'] ?? '').toString().toLowerCase();
        final username = (s['username'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q) || username.contains(q) || role.contains(q);
      }
      return true;
    }).toList();

    int activeCount = _staffList.where((s) => (s['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE').length;
    int superAdminCount = _staffList.where((s) => (s['role'] ?? '').toString().toUpperCase() == 'SUPER_ADMIN').length;
    int operationalStaffCount = _staffList.length - superAdminCount;

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
                          "Administrator Roles & RBAC Matrix CMS",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppConstants.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            "$activeCount OPERATORS ACTIVE",
                            style: const TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Manage operator credentials, granular screen authority, compliance approval privileges, and access lockout",
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
                      foregroundColor: const Color(0xFF021A13),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openAddEditStaffDialog(context, null, admin),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text("Register Staff Member", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () {
                      _loadStaffFromProvider();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✓ Reloaded operator staff from memory.")),
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

          // Operational Metric Cards
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard("SUPER ADMINISTRATORS", "$superAdminCount Full Access", const Color(0xFFEF4444), isDesktop),
              _buildMetricCard("OPERATIONAL STAFF", "$operationalStaffCount Operators", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("ACCESS ACTIVE", "$activeCount Online", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("SECURITY PROTOCOL", "RBAC Role-Enforced", const Color(0xFFA855F7), isDesktop),
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
                width: isDesktop ? 300 : double.infinity,
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search Name, Email, Username, Role...",
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
              _buildRoleFilterChip("ALL", "All Roles"),
              _buildRoleFilterChip("SUPER_ADMIN", "👑 Super Admin", const Color(0xFFEF4444)),
              _buildRoleFilterChip("TREASURY", "💰 Treasury Ops", AppConstants.accentGold),
              _buildRoleFilterChip("COMPLIANCE", "🛡️ AML / KYC", AppConstants.accentBlue),
              _buildRoleFilterChip("SUPPORT", "🎧 Support Desk", const Color(0xFFA855F7)),
              const SizedBox(width: 8),
              _buildStatusFilterChip("ALL", "All Status"),
              _buildStatusFilterChip("ACTIVE", "Active"),
              _buildStatusFilterChip("SUSPENDED", "Suspended"),
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
                  Icon(Icons.admin_panel_settings_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No staff operators found matching query",
                    style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
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
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppConstants.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 16.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String key, String label, [Color? activeColor]) {
    final isSelected = _roleFilter == key;
    final color = activeColor ?? AppConstants.accentGreen;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.25),
      backgroundColor: AppConstants.surface,
      labelStyle: TextStyle(
        color: isSelected ? color : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? color : Colors.white10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() => _roleFilter = key),
    );
  }

  Widget _buildStatusFilterChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.white24,
      backgroundColor: AppConstants.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 11,
      ),
      side: BorderSide(color: isSelected ? Colors.white38 : Colors.white10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => setState(() => _statusFilter = key),
    );
  }

  Widget _buildDesktopTable(List list, AdminProvider admin) {
  return Container(
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: Colors.white10),
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
  DataColumn(label: Text("OPERATOR PROFILE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("SYSTEM ROLE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("PERMISSIONS SCOPE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("LAST CONSOLE LOGIN", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("EXECUTIVE ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((s) {
  final status = (s['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final role = (s['role'] ?? 'SUPPORT').toString().toUpperCase();
  final perms = s['permissions'];
  final isRoot = s['id'] == 'staff_super_root';

  return DataRow(
  cells: [
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Row(
  children: [
  Text(s['name'] ?? 'Staff', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
  if (isRoot) ...[
  const SizedBox(width: 6),
  const Text("🛡️ ROOT", style: TextStyle(color: Color(0xFFEF4444), fontSize: 9.5, fontWeight: FontWeight.w900)),
  ],
  ],
  ),
  Text(
  "${s['email'] ?? '-'} • @${s['username'] ?? '-'}",
  style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  ),
  ],
  ),
  ),
  DataCell(_buildRoleBadge(role)),
  DataCell(_buildPermissionChipsRow(perms, role)),
  DataCell(
  Text(
  (s['lastLogin'] ?? 'Unknown').toString(),
  style: const TextStyle(color: Colors.white70, fontSize: 12),
  ),
  ),
  DataCell(_buildStatusBadge(isActive)),
  DataCell(
  Row(
  children: [
  if (!isRoot) ...[
  IconButton(
  icon: Icon(
  isActive ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
  color: isActive ? AppConstants.accentGreen : AppConstants.dangerRed,
  size: 22,
  ),
  tooltip: isActive ? "Suspend Access" : "Restore Access",
  onPressed: () => _toggleStaffStatus(s, admin),
  ),
  ],
  IconButton(
  icon: const Icon(Icons.rule_folder_rounded, size: 18, color: AppConstants.accentBlue),
  tooltip: "Configure Permissions Matrix",
  onPressed: () => _openPermissionsMatrixModal(context, s, admin),
  ),
  IconButton(
  icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppConstants.accentGold),
  tooltip: "Edit Profile & Credentials",
  onPressed: () => _openAddEditStaffDialog(context, s, admin),
  ),
  if (!isRoot) ...[
  IconButton(
  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.dangerRed),
  tooltip: "Delete Staff Account",
  onPressed: () => _confirmDeleteStaff(context, s, admin),
  ),
  ],
  ],
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
  final s = list[idx];
  final status = (s['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final role = (s['role'] ?? 'SUPPORT').toString().toUpperCase();
  final perms = s['permissions'];
  final isRoot = s['id'] == 'staff_super_root';

  return Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: isActive ? AppConstants.accentGreen.withValues(alpha: 0.3) : Colors.white10),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Expanded(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  children: [
  Flexible(
  child: Text(
  s['name'] ?? 'Staff',
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5),
  overflow: TextOverflow.ellipsis,
  ),
  ),
  if (isRoot) ...[
  const SizedBox(width: 6),
  const Text("🛡️ ROOT", style: TextStyle(color: Color(0xFFEF4444), fontSize: 9.5, fontWeight: FontWeight.w900)),
  ],
  ],
  ),
  Text(
  "${s['email'] ?? '-'} • @${s['username'] ?? '-'}",
  style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  ),
  ],
  ),
  ),
  const SizedBox(width: 8),
  _buildStatusBadge(isActive),
  ],
  ),
  const SizedBox(height: 8),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  _buildRoleBadge(role),
  Text("Last login: ${s['lastLogin'] ?? '-'}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
  ],
  ),
  const SizedBox(height: 8),
  _buildPermissionChipsRow(perms, role),
  const Divider(color: Colors.white10, height: 20),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  if (!isRoot) ...[
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: isActive ? AppConstants.dangerRed.withValues(alpha: 0.15) : AppConstants.accentGreen.withValues(alpha: 0.15),
  foregroundColor: isActive ? AppConstants.dangerRed : AppConstants.accentGreen,
  elevation: 0,
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  ),
  onPressed: () => _toggleStaffStatus(s, admin),
  icon: Icon(isActive ? Icons.lock_outline_rounded : Icons.lock_open_rounded, size: 14),
  label: Text(isActive ? "Suspend" : "Activate", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
  ),
  ] else ...[
  const Text("Protected Account", style: TextStyle(color: AppConstants.textMuted, fontSize: 11)),
  ],
  Row(
  children: [
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.accentBlue),
  onPressed: () => _openPermissionsMatrixModal(context, s, admin),
  icon: const Icon(Icons.rule_folder_rounded, size: 16),
  label: const Text("Privileges", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ),
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.accentGold),
  onPressed: () => _openAddEditStaffDialog(context, s, admin),
  icon: const Icon(Icons.edit_note_rounded, size: 16),
  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ),
  ],
  ),
  ],
  ),
  ],
  ),
  );
  },
  );
  }

  Widget _buildStatusBadge(bool isActive) {
  final color = isActive ? AppConstants.accentGreen : AppConstants.dangerRed;
  final label = isActive ? "ACTIVE" : "SUSPENDED";

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: color.withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: color.withValues(alpha: 0.3)),
  ),
  child: Text(
  label,
  style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900),
  ),
  );
  }

  Widget _buildRoleBadge(String role) {
  Color color = AppConstants.accentGreen;
  String label = role;

  if (role == 'SUPER_ADMIN') {
  color = const Color(0xFFEF4444);
  label = "SUPER ADMIN";
  } else if (role == 'TREASURY') {
  color = AppConstants.accentGold;
  label = "TREASURY OPS";
  } else if (role == 'COMPLIANCE') {
  color = AppConstants.accentBlue;
  label = "COMPLIANCE & AML";
  } else if (role == 'SUPPORT') {
  color = const Color(0xFFA855F7);
  label = "SUPPORT DESK";
  }

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: color.withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: color.withValues(alpha: 0.3)),
  ),
  child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
  );
  }

  Widget _buildPermissionChipsRow(dynamic perms, String role) {
  if (role == 'SUPER_ADMIN') {
  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(6),
  ),
  child: const Text(
  "All Privileges Granted (Unrestricted)",
  style: TextStyle(color: Color(0xFFEF4444), fontSize: 10.5, fontWeight: FontWeight.bold),
  ),
  );
  }

  if (perms is! Map) {
  return const Text("Read-Only Console", style: TextStyle(color: AppConstants.textMuted, fontSize: 11));
  }

  final List<String> activePerms = [];
  if (perms['canApprovePayouts'] == true) activePerms.add("Payouts");
  if (perms['canAdjustBalances'] == true) activePerms.add("Balances");
  if (perms['canReviewKyc'] == true) activePerms.add("KYC");
  if (perms['canFreezeUsers'] == true) activePerms.add("Freeze");
  if (perms['canEditCms'] == true) activePerms.add("CMS");
  if (perms['canClearAuditLogs'] == true) activePerms.add("Logs");

  if (activePerms.isEmpty) {
  return const Text("Read-Only Console", style: TextStyle(color: AppConstants.textMuted, fontSize: 11));
  }

  return Wrap(
  spacing: 4,
  runSpacing: 4,
  children: activePerms.map((p) {
  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(
  color: Colors.white10,
  borderRadius: BorderRadius.circular(4),
  ),
  child: Text(p, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
  );
  }).toList(),
  );
  }

  // =========================================================================
  // GRANULAR PERMISSIONS MATRIX MODAL (RBAC)
  // =========================================================================
  void _openPermissionsMatrixModal(BuildContext context, Map<String, dynamic> staff, AdminProvider admin) {
  final Map<String, dynamic> currentPerms = (staff['permissions'] is Map)
  ? Map<String, dynamic>.from(staff['permissions'])
      : <String, dynamic>{};

  final isRoot = staff['id'] == 'staff_super_root';

  showDialog(
  context: context,
  builder: (ctx) => StatefulBuilder(
  builder: (ctx, setMatrixState) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Colors.white12)),
  title: Row(
  children: [
  const Icon(Icons.rule_folder_rounded, color: AppConstants.accentBlue),
  const SizedBox(width: 8),
  Expanded(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text("RBAC Privileges: ${staff['name']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
  Text("Role: ${staff['role']}", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
  ],
  ),
  ),
  ],
  ),
  content: Container(
  constraints: const BoxConstraints(maxWidth: 520),
  child: SingleChildScrollView(
  child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
  if (isRoot) ...[
  Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
  ),
  child: const Row(
  children: [
  Icon(Icons.shield_rounded, color: Color(0xFFEF4444), size: 20),
  SizedBox(width: 8),
  Expanded(
  child: Text(
  "Root Super Administrator has absolute unrestricted authority across all desks. Privileges cannot be revoked.",
  style: TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3),
  ),
  ),
  ],
  ),
  ),
  const SizedBox(height: 14),
  ],
  _buildPermTile(
  title: "Authorize & Approve Payouts",
  subtitle: "Can approve and dispatch manual and automated customer withdrawals.",
  value: isRoot ? true : (currentPerms['canApprovePayouts'] == true),
  onChanged: isRoot ? null : (v) => setMatrixState(() => currentPerms['canApprovePayouts'] = v),
  ),
  const Divider(color: Colors.white10, height: 16),
  _buildPermTile(
  title: "Adjust Customer Balances",
  subtitle: "Can manually inject or debit cash, gold, and crypto wallet balances.",
  value: isRoot ? true : (currentPerms['canAdjustBalances'] == true),
  onChanged: isRoot ? null : (v) => setMatrixState(() => currentPerms['canAdjustBalances'] = v),
  ),
  const Divider(color: Colors.white10, height: 16),
  _buildPermTile(
  title: "Review & Verify KYC Submissions",
  subtitle: "Can inspect biometric national identity scans and approve Tier-2 status.",
  value: isRoot ? true : (currentPerms['canReviewKyc'] == true),
  onChanged: isRoot ? null : (v) => setMatrixState(() => currentPerms['canReviewKyc'] = v),
  ),
  const Divider(color: Colors.white10, height: 16),
  _buildPermTile(
  title: "Account Freeze & Security Lockout",
  subtitle: "Can freeze suspicious customer accounts and wipe trusted device tokens.",
  value: isRoot ? true : (currentPerms['canFreezeUsers'] == true),
  onChanged: isRoot ? null : (v) => setMatrixState(() => currentPerms['canFreezeUsers'] = v),
  ),
  const Divider(color: Colors.white10, height: 16),
  _buildPermTile(
  title: "Edit CMS Parameters & Live Rates",
  subtitle: "Can modify gateway settings, utility billers, banners, and crypto pegs.",
  value: isRoot ? true : (currentPerms['canEditCms'] == true),
  onChanged: isRoot ? null : (v) => setMatrixState(() => currentPerms['canEditCms'] = v),
  ),
  const Divider(color: Colors.white10, height: 16),
  _buildPermTile(
  title: "Purge & Clear Audit Trail Logs",
  subtitle: "Can wipe system operational logs and export financial CSV data.",
  value: isRoot ? true : (currentPerms['canClearAuditLogs'] == true),
  onChanged: isRoot ? null : (v) => setMatrixState(() => currentPerms['canClearAuditLogs'] = v),
  ),
  ],
  ),
  ),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
  if (!isRoot)
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: const Color(0xFF021A13)),
  onPressed: () async {
  Navigator.pop(ctx);
  final updatedList = _staffList.map((e) => Map<String, dynamic>.from(e)).toList();
  final idx = updatedList.indexWhere((x) => x['id'] == staff['id']);
  if (idx != -1) {
  updatedList[idx]['permissions'] = currentPerms;
  await _saveStaffList(updatedList, admin);
  }
  },
  child: const Text("Save RBAC Privileges", style: TextStyle(fontWeight: FontWeight.w900)),
  ),
  ],
  ),
  ),
  );
  }

  Widget _buildPermTile({
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool>? onChanged,
  }) {
  return Row(
  children: [
  Expanded(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
  const SizedBox(height: 2),
  Text(subtitle, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
  ],
  ),
  ),
  Switch(
  value: value,
  activeColor: AppConstants.accentGreen,
  onChanged: onChanged,
  ),
  ],
  );
  }

  // =========================================================================
  // ADD / EDIT OPERATOR MODAL DIALOG
  // =========================================================================
  void _openAddEditStaffDialog(BuildContext context, Map<String, dynamic>? existing, AdminProvider admin) {
  final isEdit = existing != null;
  final nameController = TextEditingController(text: isEdit ? existing['name'] : '');
  final emailController = TextEditingController(text: isEdit ? existing['email'] : '');
  final usernameController = TextEditingController(text: isEdit ? existing['username'] : '');
  final passwordController = TextEditingController();

  String role = isEdit ? (existing['role'] ?? 'SUPPORT') : 'SUPPORT';
  String status = isEdit ? (existing['status'] ?? 'ACTIVE') : 'ACTIVE';

  showDialog(
  context: context,
  builder: (ctx) => StatefulBuilder(
  builder: (ctx, setDialogState) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Colors.white12)),
  title: Text(
  isEdit ? "Edit Staff: ${existing['name']}" : "Register Operator Account",
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
  ),
  content: Container(
  constraints: const BoxConstraints(maxWidth: 520),
  child: SingleChildScrollView(
  child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
  TextField(
  controller: nameController,
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "FULL LEGAL NAME",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. Tariq Mehmood",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(
  child: TextField(
  controller: usernameController,
  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
  decoration: InputDecoration(
  labelText: "OPERATOR USERNAME",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "tariq_ops",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  Expanded(
  child: TextField(
  controller: emailController,
  style: const TextStyle(color: Colors.white),
  decoration: InputDecoration(
  labelText: "OFFICIAL EMAIL",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "tariq@nexpay.vip",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 12),
  TextField(
  controller: passwordController,
  obscureText: true,
  style: const TextStyle(color: Colors.white),
  decoration: InputDecoration(
  labelText: isEdit ? "SET NEW PASSWORD (LEAVE BLANK TO RETAIN)" : "ACCOUNT ACCESS PASSWORD",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "••••••••",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(
  child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
  value: role,
  dropdownColor: AppConstants.surfaceCard,
  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "SUPER_ADMIN", child: Text("👑 Super Admin")),
  DropdownMenuItem(value: "TREASURY", child: Text("💰 Treasury Ops")),
  DropdownMenuItem(value: "COMPLIANCE", child: Text("🛡️ AML / KYC")),
  DropdownMenuItem(value: "SUPPORT", child: Text("🎧 Support Desk")),
  ],
  onChanged: (existing != null && existing['id'] == 'staff_super_root')
  ? null
      : (val) {
  if (val != null) setDialogState(() => role = val);
  },
  ),
  ),
  ),
  ),
  const SizedBox(width: 8),
  Expanded(
  child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
  value: status,
  dropdownColor: AppConstants.surfaceCard,
  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "ACTIVE", child: Text("🟢 Active")),
  DropdownMenuItem(value: "SUSPENDED", child: Text("🔴 Suspended")),
  ],
  onChanged: (existing != null && existing['id'] == 'staff_super_root')
  ? null
      : (val) {
  if (val != null) setDialogState(() => status = val);
  },
  ),
  ),
  ),
  ),
  ],
  ),
  ],
  ),
  ),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: const Color(0xFF021A13)),
  onPressed: () async {
  final name = nameController.text.trim();
  final email = emailController.text.trim();
  final username = usernameController.text.trim();
  if (name.isEmpty || email.isEmpty || username.isEmpty) return;

  Navigator.pop(ctx);

  final Map<String, dynamic> staffObj = {
  'id': isEdit ? existing['id'] : 'staff_${DateTime.now().millisecondsSinceEpoch}',
  'name': name,
  'email': email,
  'username': username,
  'role': role,
  'status': status,
  'lastLogin': isEdit ? (existing['lastLogin'] ?? 'Never') : 'Never',
  'permissions': isEdit
  ? existing['permissions']
      : {
  'canApprovePayouts': (role == 'SUPER_ADMIN' || role == 'TREASURY'),
  'canAdjustBalances': (role == 'SUPER_ADMIN'),
  'canReviewKyc': (role == 'SUPER_ADMIN' || role == 'COMPLIANCE'),
  'canFreezeUsers': (role == 'SUPER_ADMIN' || role == 'COMPLIANCE'),
  'canEditCms': (role == 'SUPER_ADMIN' || role == 'TREASURY'),
  'canClearAuditLogs': (role == 'SUPER_ADMIN'),
  },
  };

  final updatedList = _staffList.map((e) => Map<String, dynamic>.from(e)).toList();
  if (isEdit) {
  final idx = updatedList.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) updatedList[idx] = staffObj;
  } else {
  updatedList.add(staffObj);
  }

  await _saveStaffList(updatedList, admin);
  },
  child: const Text("Save Operator Account", style: TextStyle(fontWeight: FontWeight.w900)),
  ),
  ],
  ),
  ),
  );
  }

  // Toggle Staff Status (Lock / Unlock)
  Future<void> _toggleStaffStatus(Map<String, dynamic> s, AdminProvider admin) async {
  final currentStatus = (s['status'] ?? 'ACTIVE').toString().toUpperCase();
  final newStatus = currentStatus == 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';

  final updatedList = _staffList.map((e) => Map<String, dynamic>.from(e)).toList();
  final idx = updatedList.indexWhere((x) => x['id'] == s['id']);
  if (idx != -1) {
  updatedList[idx]['status'] = newStatus;
  await _saveStaffList(updatedList, admin);
  }
  }

  // Confirm Delete Staff
  void _confirmDeleteStaff(BuildContext context, Map<String, dynamic> s, AdminProvider admin) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: const Text("Delete Operator Account?", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w900)),
  content: Text(
  "Kya aap waqai operator \"${s['name']}\" (@${s['username']}) ko remove karna chahte hain? Inki console access foran block ho jayegi.",
  style: const TextStyle(color: AppConstants.textMuted),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Colors.white),
  onPressed: () async {
  Navigator.pop(ctx);
  final updatedList = _staffList.map((e) => Map<String, dynamic>.from(e)).toList();
  updatedList.removeWhere((x) => x['id'] == s['id']);
  await _saveStaffList(updatedList, admin);
  },
  child: const Text("Delete Account"),
  ),
  ],
  ),
  );
  }

  Future<void> _saveStaffList(List updatedList, AdminProvider admin) async {
  setState(() => _isSaving = true);
  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'save_config'},
  data: {'adminStaff': updatedList},
  );

  if (res.data['status'] == 'success') {
  setState(() => _staffList = updatedList);
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text(
  "✓ Operator staff & RBAC permissions synchronized live!",
  style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold),
  ),
  ),
  );
  }
  }
  } catch (_) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Failed to update staff roles.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isSaving = false);
  }
  }
}