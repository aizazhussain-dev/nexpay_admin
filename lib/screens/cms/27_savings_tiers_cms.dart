import '../../widgets/institutional_scroll.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class SavingsTiersCmsScreen extends StatefulWidget {
  const SavingsTiersCmsScreen({super.key});

  @override
  State<SavingsTiersCmsScreen> createState() => _SavingsTiersCmsScreenState();
}

class _SavingsTiersCmsScreenState extends State<SavingsTiersCmsScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  List _tiersList = [];
  String _searchQuery = "";
  String _typeFilter = "ALL"; // ALL, FLEXIBLE, LOCKED
  String _statusFilter = "ALL"; // ALL, ACTIVE, DISABLED
  bool _isSaving = false;
  bool _isInitialized = false;

  // Default Shariah-compliant savings plans fallback
  final List _defaultTiers = [
  {
  'id': 'tier_liquid_flexi',
  'name': 'Liquid Halal Flexi Pot',
  'annualRate': 12.5,
  'lockDurationDays': 0, // 0 = Anytime flexible withdrawal
  'durationLabel': 'Flexible (Anytime)',
  'minDeposit': 1000.0,
  'payoutFrequency': 'DAILY ACCRUAL',
  'shariahBadge': 'Mudarabah Islamic Certified',
  'description': 'Zero lock-in days. Earn daily profit with 100% instant anytime liquidity.',
  'status': 'ACTIVE',
  },
  {
  'id': 'tier_3m_growth',
  'name': '3-Month Shariah Growth Lock',
  'annualRate': 15.0,
  'lockDurationDays': 90,
  'durationLabel': '3 Months (90 Days)',
  'minDeposit': 10000.0,
  'payoutFrequency': 'MONTHLY DISTRIBUTED',
  'shariahBadge': 'Mudarabah Certified',
  'description': 'Quarterly capital lock with enhanced monthly profit distribution.',
  'status': 'ACTIVE',
  },
  {
  'id': 'tier_6m_premium',
  'name': '6-Month Premium Vault',
  'annualRate': 18.5,
  'lockDurationDays': 180,
  'durationLabel': '6 Months (180 Days)',
  'minDeposit': 25000.0,
  'payoutFrequency': 'MONTHLY DISTRIBUTED',
  'shariahBadge': 'Ijarah Asset-Backed',
  'description': 'Asset-backed high-yield Islamic portfolio designed for medium-term goals.',
  'status': 'ACTIVE',
  },
  {
  'id': 'tier_1y_sovereign',
  'name': '1-Year Sovereign High-Yield',
  'annualRate': 21.5,
  'lockDurationDays': 365,
  'durationLabel': '1 Year (365 Days)',
  'minDeposit': 50000.0,
  'payoutFrequency': 'AT MATURITY / MONTHLY',
  'shariahBadge': 'Sukuk Sovereign Backed',
  'description': 'Highest yield institutional Sukuk tier for disciplined long-term capital compounding.',
  'status': 'ACTIVE',
  },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadTiersFromProvider();
      _isInitialized = true;
    }
  }

  void _loadTiersFromProvider() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;

    if (cfg['savingsTiers'] is List && (cfg['savingsTiers'] as List).isNotEmpty) {
      final list = (cfg['savingsTiers'] as List)
          .whereType()
          .map((t) => Map<String, dynamic>.from(t))
          .toList();
      setState(() => _tiersList = list);
    } else {
      setState(() {
        _tiersList = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredList = _tiersList.where((t) {
      final status = (t['status'] ?? 'ACTIVE').toString().toUpperCase();
      final lockDays = int.tryParse(t['lockDurationDays']?.toString() ?? '0') ?? 0;
      final isFlexible = lockDays == 0;

      if (_typeFilter == "FLEXIBLE" && !isFlexible) return false;
      if (_typeFilter == "LOCKED" && isFlexible) return false;
      if (_statusFilter == "ACTIVE" && status != "ACTIVE") return false;
      if (_statusFilter == "DISABLED" && status != "DISABLED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (t['name'] ?? '').toString().toLowerCase();
        final badge = (t['shariahBadge'] ?? '').toString().toLowerCase();
        final desc = (t['description'] ?? '').toString().toLowerCase();
        return name.contains(q) || badge.contains(q) || desc.contains(q);
      }
      return true;
    }).toList();

    int activeCount = _tiersList.where((t) => (t['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE').length;
    double maxRoi = 0.0;
    for (var t in _tiersList) {
      final r = double.tryParse(t['annualRate']?.toString() ?? '0') ?? 0.0;
      if (r > maxRoi) maxRoi = r;
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
                        const Text(
                          "Savings Vaults & Profit Tiers CMS",
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
                          child: Text(
                            "$activeCount TIERS ENFORCED",
                            style: const TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Manage Halal savings plans, annual percentage return (ROI) quotas, lock durations, and minimum capital entry thresholds",
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
                    onPressed: () => _openAddEditTierDialog(context, null, admin),
                    icon: const Icon(Icons.add_chart_rounded, size: 18),
                    label: const Text("Create Savings Tier", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF94A3B8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _loadTiersFromProvider();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✓ Reloaded savings tiers from memory.")),
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
              _buildMetricCard("MAX ANNUAL YIELD", "${maxRoi.toStringAsFixed(1)}% p.a.", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("ACTIVE VAULT PLANS", "$activeCount Plans Live", AppConstants.accentGold, isDesktop),
              _buildMetricCard("SHARIAH COMPLIANCE", "100% Asset-Backed", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("TOTAL TIERS REGISTERED", "${_tiersList.length} Tiers", Color(0xFFA855F7), isDesktop),
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
                width: isDesktop ? 320 : double.infinity,
                child: TextField(
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search Tier Name, Shariah Badge...",
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
              _buildTypeChip("ALL", "All Plans"),
              _buildTypeChip("FLEXIBLE", "💧 Flexible Liquid"),
              _buildTypeChip("LOCKED", "🔒 Term Locks"),
              const SizedBox(width: 8),
              _buildStatusFilterChip("ALL", "All"),
              _buildStatusFilterChip("ACTIVE", "Active"),
              _buildStatusFilterChip("DISABLED", "Disabled"),
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
                  Icon(Icons.savings_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No savings vault tiers found",
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
          Text(value, style: TextStyle(color: color, fontSize: 16.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String key, String label) {
    final isSelected = _typeFilter == key;
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
      onSelected: (_) => setState(() => _typeFilter = key),
    );
  }

  Widget _buildStatusFilterChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Color(0xFF94A3B8),
      backgroundColor: AppConstants.surface,
      labelStyle: TextStyle(
        color: isSelected ? Color(0xFF0F172A) : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 11,
      ),
      side: BorderSide(color: isSelected ? Color(0xFF94A3B8) : Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  columnSpacing: 26,
  columns: const [
  DataColumn(label: Text("VAULT PLAN NAME", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("ANNUAL PROFIT (ROI)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("LOCK DURATION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("MIN DEPOSIT", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("PAYOUT & SHARIAH STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("EXECUTIVE ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((t) {
  final status = (t['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final rate = double.tryParse(t['annualRate']?.toString() ?? '0') ?? 0.0;
  final minDep = double.tryParse(t['minDeposit']?.toString() ?? '0') ?? 1000.0;
  final duration = (t['durationLabel'] ?? 'Flexible').toString();
  final payout = (t['payoutFrequency'] ?? 'DAILY ACCRUAL').toString();
  final badge = (t['shariahBadge'] ?? 'Islamic').toString();

  return DataRow(
  cells: [
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(t['name'] ?? 'Vault Tier', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13.5)),
  Container(
  constraints: const BoxConstraints(maxWidth: 240),
  child: Text(
  t['description'] ?? '-',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  ),
  ),
  ],
  ),
  ),
  DataCell(
  Row(
  children: [
  const Icon(Icons.trending_up_rounded, color: AppConstants.accentGreen, size: 16),
  const SizedBox(width: 4),
  Text(
  "${rate.toStringAsFixed(1)}% p.a.",
  style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w700, fontSize: 14),
  ),
  ],
  ),
  ),
  DataCell(
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: (duration.contains('Flexible') ? Colors.cyan : AppConstants.accentGold).withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
  duration,
  style: TextStyle(
  color: duration.contains('Flexible') ? Colors.cyan : AppConstants.accentGold,
  fontWeight: FontWeight.bold,
  fontSize: 11,
  ),
  ),
  ),
  ),
  DataCell(
  Text(
  "₨ ${_currencyFormat.format(minDep)}",
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 13),
  ),
  ),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(payout, style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold, fontSize: 11)),
  Text(badge, style: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5)),
  ],
  ),
  ),
  DataCell(_buildStatusBadge(isActive)),
  DataCell(
  Row(
  children: [
  IconButton(
  icon: Icon(
  isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
  color: isActive ? AppConstants.accentGreen : AppConstants.textMuted,
  size: 26,
  ),
  tooltip: isActive ? "Disable Tier" : "Enable Tier",
  onPressed: () => _toggleTierStatus(t, admin),
  ),
  IconButton(
  icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppConstants.accentBlue),
  tooltip: "Edit Tier Parameters",
  onPressed: () => _openAddEditTierDialog(context, t, admin),
  ),
  IconButton(
  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.dangerRed),
  tooltip: "Delete Tier",
  onPressed: () => _confirmDeleteTier(context, t, admin),
  ),
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
  final t = list[idx];
  final status = (t['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final rate = double.tryParse(t['annualRate']?.toString() ?? '0') ?? 0.0;
  final minDep = double.tryParse(t['minDeposit']?.toString() ?? '0') ?? 1000.0;
  final duration = (t['durationLabel'] ?? 'Flexible').toString();
  final payout = (t['payoutFrequency'] ?? 'DAILY ACCRUAL').toString();

  return Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: isActive ? AppConstants.accentGreen.withValues(alpha: 0.3) : Color(0xFFE2E8F0)),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text(t['name'] ?? 'Plan', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14.5)),
  _buildStatusBadge(isActive),
  ],
  ),
  const SizedBox(height: 8),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text("Yield: ${rate.toStringAsFixed(1)}% p.a.", style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w700, fontSize: 15)),
  Text("Min: ₨ ${_currencyFormat.format(minDep)}", style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold, fontSize: 13)),
  ],
  ),
  const SizedBox(height: 4),
  Text("Lock: $duration • Payout: $payout", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
  const Divider(color: Color(0xFFE2E8F0), height: 20),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: isActive ? AppConstants.dangerRed.withValues(alpha: 0.15) : AppConstants.accentGreen.withValues(alpha: 0.15),
  foregroundColor: isActive ? AppConstants.dangerRed : AppConstants.accentGreen,
  elevation: 0,
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  ),
  onPressed: () => _toggleTierStatus(t, admin),
  icon: Icon(isActive ? Icons.power_settings_new_rounded : Icons.check_circle_rounded, size: 14),
  label: Text(isActive ? "Disable" : "Enable", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
  ),
  Row(
  children: [
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.accentBlue),
  onPressed: () => _openAddEditTierDialog(context, t, admin),
  icon: const Icon(Icons.edit_note_rounded, size: 16),
  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ),
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.dangerRed),
  onPressed: () => _confirmDeleteTier(context, t, admin),
  icon: const Icon(Icons.delete_outline_rounded, size: 16),
  label: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: (isActive ? AppConstants.accentGreen : AppConstants.dangerRed).withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
  isActive ? "ACTIVE" : "DISABLED",
  style: TextStyle(
  color: isActive ? AppConstants.accentGreen : AppConstants.dangerRed,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  ),
  ),
  );
  }

  // Add / Edit Modal Dialog
  void _openAddEditTierDialog(BuildContext context, Map<String, dynamic>? existing, AdminProvider admin) {
  final isEdit = existing != null;
  final nameController = TextEditingController(text: isEdit ? existing['name'] : '');
  final rateController = TextEditingController(text: isEdit ? existing['annualRate'].toString() : '15.0');
  final lockDaysController = TextEditingController(text: isEdit ? existing['lockDurationDays'].toString() : '90');
  final durationLabelController = TextEditingController(text: isEdit ? existing['durationLabel'] : '3 Months (90 Days)');
  final minDepositController = TextEditingController(text: isEdit ? existing['minDeposit'].toString() : '10000');
  final badgeController = TextEditingController(text: isEdit ? existing['shariahBadge'] : 'Mudarabah Islamic Certified');
  final descController = TextEditingController(text: isEdit ? existing['description'] : '');

  String payoutFrequency = isEdit ? (existing['payoutFrequency'] ?? 'MONTHLY DISTRIBUTED') : 'MONTHLY DISTRIBUTED';
  String status = isEdit ? (existing['status'] ?? 'ACTIVE') : 'ACTIVE';

  showDialog(
  context: context,
  builder: (ctx) => StatefulBuilder(
  builder: (ctx, setDialogState) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: Text(
  isEdit ? "Edit Plan: ${existing['name']}" : "Create Savings Vault Plan",
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18),
  ),
  content: Container(
  constraints: const BoxConstraints(maxWidth: 520),
  child: InstitutionalVScroll(
  child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  TextField(
  controller: nameController,
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "VAULT PLAN NAME",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. 6-Month Premium Vault",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  // Annual ROI Rate
  Expanded(
  child: TextField(
  controller: rateController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "ANNUAL RETURN (% p.a.)",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "18.5",
  suffixText: "%",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Min Deposit
  Expanded(
  child: TextField(
  controller: minDepositController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "MIN DEPOSIT (PKR)",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "25000",
  prefixText: "₨ ",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  // Lock Days
  Expanded(
  child: TextField(
  controller: lockDaysController,
  keyboardType: TextInputType.number,
  style: const TextStyle(color: Color(0xFF0F172A)),
  decoration: InputDecoration(
  labelText: "LOCK DAYS (0 = FLEXIBLE)",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "0 or 90 or 180",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  onChanged: (val) {
  final d = int.tryParse(val) ?? 0;
  if (d == 0) {
  durationLabelController.text = "Flexible (Anytime)";
  } else {
  durationLabelController.text = "$d Days Term Lock";
  }
  },
  ),
  ),
  const SizedBox(width: 8),
  // Duration Label
  Expanded(
  child: TextField(
  controller: durationLabelController,
  style: const TextStyle(color: Color(0xFF0F172A)),
  decoration: InputDecoration(
  labelText: "DISPLAY DURATION LABEL",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. 6 Months (180 Days)",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  // Payout Frequency Dropdown
  Expanded(
  child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
  value: payoutFrequency,
  dropdownColor: AppConstants.surfaceCard,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "DAILY ACCRUAL", child: Text("Daily Accrual")),
  DropdownMenuItem(value: "MONTHLY DISTRIBUTED", child: Text("Monthly Distributed")),
  DropdownMenuItem(value: "AT MATURITY / MONTHLY", child: Text("At Maturity / Monthly")),
  ],
  onChanged: (val) {
  if (val != null) setDialogState(() => payoutFrequency = val);
  },
  ),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Status Selector
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
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "ACTIVE", child: Text("🟢 Active")),
  DropdownMenuItem(value: "DISABLED", child: Text("🔴 Disabled")),
  ],
  onChanged: (val) {
  if (val != null) setDialogState(() => status = val);
  },
  ),
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 12),
  // Shariah Badge
  TextField(
  controller: badgeController,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
  decoration: InputDecoration(
  labelText: "SHARIAH CERTIFICATION BADGE",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "Mudarabah Islamic Certified or Sukuk Backed",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  const SizedBox(height: 12),
  // Description
  TextField(
  controller: descController,
  maxLines: 2,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
  decoration: InputDecoration(
  labelText: "PORTFOLIO SUMMARY & TERMS FOR USERS",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "Halal asset-backed growth pool with daily profit attribution.",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ],
  ),
  ),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: Colors.white),
  onPressed: () async {
  final name = nameController.text.trim();
  final rate = double.tryParse(rateController.text.trim()) ?? 0.0;
  final minDep = double.tryParse(minDepositController.text.trim()) ?? 1000.0;
  if (name.isEmpty || rate <= 0) return;

  Navigator.pop(ctx);

  final tierObj = {
  'id': isEdit ? existing['id'] : 'tier_${DateTime.now().millisecondsSinceEpoch}',
  'name': name,
  'annualRate': rate,
  'lockDurationDays': int.tryParse(lockDaysController.text.trim()) ?? 0,
  'durationLabel': durationLabelController.text.trim(),
  'minDeposit': minDep,
  'payoutFrequency': payoutFrequency,
  'shariahBadge': badgeController.text.trim(),
  'description': descController.text.trim(),
  'status': status,
  };

  final updatedList = List.from(_tiersList);
  if (isEdit) {
  final idx = updatedList.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) updatedList[idx] = tierObj;
  } else {
  updatedList.add(tierObj);
  }

  await _saveTiersList(updatedList, admin);
  },
  child: const Text("Save Vault Plan", style: TextStyle(fontWeight: FontWeight.w700)),
  ),
  ],
  ),
  ),
  );
  }

  // Toggle Tier Status
  Future<void> _toggleTierStatus(Map<String, dynamic> t, AdminProvider admin) async {
  final currentStatus = (t['status'] ?? 'ACTIVE').toString().toUpperCase();
  final newStatus = currentStatus == 'ACTIVE' ? 'DISABLED' : 'ACTIVE';

  final updatedList = List.from(_tiersList);
  final idx = updatedList.indexWhere((x) => x['id'] == t['id']);
  if (idx != -1) {
  updatedList[idx]['status'] = newStatus;
  await _saveTiersList(updatedList, admin);
  }
  }

  // Confirm Delete Tier
  void _confirmDeleteTier(BuildContext context, Map<String, dynamic> t, AdminProvider admin) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: const Text("Delete Vault Plan?", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w700)),
  content: Text("Kya aap waqai \"${t['name']}\" ko active savings tiers se delete karna chahte hain?", style: const TextStyle(color: AppConstants.textMuted)),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Colors.white),
  onPressed: () async {
  Navigator.pop(ctx);
  final updatedList = List.from(_tiersList);
  updatedList.removeWhere((x) => x['id'] == t['id']);
  await _saveTiersList(updatedList, admin);
  },
  child: const Text("Delete"),
  ),
  ],
  ),
  );
  }

  Future<void> _saveTiersList(List updatedList, AdminProvider admin) async {
  setState(() => _isSaving = true);
  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'save_config'},
  data: {'savingsTiers': updatedList},
  );

  if (res.data['status'] == 'success') {
  setState(() => _tiersList = updatedList);
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ Savings tiers & ROI rates synchronized live!", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }
  }
  } catch (_) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Failed to update savings tiers.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isSaving = false);
  }
  }
}
