import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class TakafulPlansCmsScreen extends StatefulWidget {
  const TakafulPlansCmsScreen({super.key});

  @override
  State<TakafulPlansCmsScreen> createState() => _TakafulPlansCmsScreenState();
}

class _TakafulPlansCmsScreenState extends State<TakafulPlansCmsScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  List _plansList = [];
  String _searchQuery = "";
  String _categoryFilter = "ALL"; // ALL, HEALTH, LIFE, MOTOR, DEVICE, TRAVEL
  String _statusFilter = "ALL"; // ALL, ACTIVE, DISABLED
  bool _isSaving = false;
  bool _isInitialized = false;

  // National Islamic Takaful fallback plans
  final List _defaultPlans = [
  {
  'id': 'plan_sehat_plus',
  'name': 'Sehat Tahaffuz Health Care',
  'category': 'HEALTH',
  'coverageAmount': 500000.0,
  'monthlyPremium': 350.0,
  'annualPremium': 3800.0,
  'icon': '🏥',
  'underwriter': 'Pak-Qatar Family Takaful',
  'benefits': 'Daily hospitalization cash up to ₨ 5,000/day + ICU & accidental coverage.',
  'status': 'ACTIVE',
  },
  {
  'id': 'plan_zindagi_aman',
  'name': 'Zindagi Aman Accidental Life',
  'category': 'LIFE',
  'coverageAmount': 1000000.0,
  'monthlyPremium': 250.0,
  'annualPremium': 2700.0,
  'icon': '🛡️',
  'underwriter': 'EFU General Takaful',
  'benefits': 'Pure Islamic accidental death & permanent total disability lump-sum payout.',
  'status': 'ACTIVE',
  },
  {
  'id': 'plan_motor_bike',
  'name': 'Bike & Ride Protection Shield',
  'category': 'MOTOR',
  'coverageAmount': 150000.0,
  'monthlyPremium': 180.0,
  'annualPremium': 1950.0,
  'icon': '🛵',
  'underwriter': 'Takaful Pakistan Limited',
  'benefits': 'Total loss, theft, snatching, and road accident third-party liability compensation.',
  'status': 'ACTIVE',
  },
  {
  'id': 'plan_screen_protect',
  'name': 'Smartphone Screen & Water Damage',
  'category': 'DEVICE',
  'coverageAmount': 40000.0,
  'monthlyPremium': 120.0,
  'annualPremium': 1300.0,
  'icon': '📱',
  'underwriter': 'Pak-Qatar General Takaful',
  'benefits': 'Direct cash reimbursement for cracked screen replacement & liquid damage.',
  'status': 'ACTIVE',
  },
  {
  'id': 'plan_transit_travel',
  'name': 'Domestic Commuter & Travel Cover',
  'category': 'TRAVEL',
  'coverageAmount': 200000.0,
  'monthlyPremium': 90.0,
  'annualPremium': 950.0,
  'icon': '✈️',
  'underwriter': 'EFU General Takaful',
  'benefits': 'Intercity travel delay, lost baggage, and accidental roadside medical emergency.',
  'status': 'ACTIVE',
  },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadPlansFromProvider();
      _isInitialized = true;
    }
  }

  void _loadPlansFromProvider() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;

    if (cfg['takafulPlans'] is List && (cfg['takafulPlans'] as List).isNotEmpty) {
      final list = (cfg['takafulPlans'] as List)
          .whereType()
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
      setState(() => _plansList = list);
    } else {
      setState(() {
        _plansList = _defaultPlans.map((p) => Map<String, dynamic>.from(p)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredList = _plansList.where((p) {
      final cat = (p['category'] ?? 'HEALTH').toString().toUpperCase();
      final status = (p['status'] ?? 'ACTIVE').toString().toUpperCase();

      if (_categoryFilter != "ALL" && cat != _categoryFilter) return false;
      if (_statusFilter == "ACTIVE" && status != "ACTIVE") return false;
      if (_statusFilter == "DISABLED" && status != "DISABLED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (p['name'] ?? '').toString().toLowerCase();
        final underwriter = (p['underwriter'] ?? '').toString().toLowerCase();
        final benefits = (p['benefits'] ?? '').toString().toLowerCase();
        return name.contains(q) || underwriter.contains(q) || benefits.contains(q) || cat.contains(q);
      }
      return true;
    }).toList();

    int activeCount = _plansList.where((p) => (p['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE').length;
    double maxCoverage = 0.0;
    for (var p in _plansList) {
      final c = double.tryParse(p['coverageAmount']?.toString() ?? '0') ?? 0.0;
      if (c > maxCoverage) maxCoverage = c;
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
                          "Islamic Takaful & Insurance Plans CMS",
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
                            color: AppConstants.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            "$activeCount PLANS ACTIVE",
                            style: const TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Manage Islamic insurance policies, maximum coverage caps, monthly premiums, and underwriter partners",
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
                    onPressed: () => _openAddEditPlanDialog(context, null, admin),
                    icon: const Icon(Icons.add_moderator_rounded, size: 18),
                    label: const Text("Create Takaful Plan", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFF94A3B8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _loadPlansFromProvider();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✓ Reloaded Takaful plans from memory.")),
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
              _buildMetricCard("MAX COVERAGE CAP", "₨ ${_currencyFormat.format(maxCoverage)}", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("ACTIVE PROTECTION PLANS", "$activeCount Policies Live", AppConstants.accentGold, isDesktop),
              _buildMetricCard("SHARIAH CERTIFICATION", "Mudarabah / Waqf", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("TOTAL CATALOG PLANS", "${_plansList.length} Registered", Color(0xFFA855F7), isDesktop),
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
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search Policy, Underwriter, Benefits...",
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
              _buildCategoryChip("ALL", "All Policies"),
              _buildCategoryChip("HEALTH", "🏥 Health Care"),
              _buildCategoryChip("LIFE", "🛡️ Accidental Life"),
              _buildCategoryChip("MOTOR", "🛵 Bike & Motor"),
              _buildCategoryChip("DEVICE", "📱 Smartphone Screen"),
              _buildCategoryChip("TRAVEL", "✈️ Travel & Transit"),
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
                  Icon(Icons.shield_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No Takaful insurance policies found",
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
          Text(value, style: TextStyle(color: color, fontSize: 16.5, fontWeight: FontWeight.w900)),
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
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? AppConstants.accentGreen : Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() => _categoryFilter = key),
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
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
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
  DataColumn(label: Text("ICON", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("POLICY TITLE & UNDERWRITER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("CATEGORY", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("MAX COVERAGE (PKR)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("PREMIUM (MONTHLY / ANNUAL)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("EXECUTIVE ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((p) {
  final status = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final cat = (p['category'] ?? 'HEALTH').toString().toUpperCase();
  final icon = (p['icon'] ?? '🛡️').toString();
  final coverage = double.tryParse(p['coverageAmount']?.toString() ?? '0') ?? 0.0;
  final monthly = double.tryParse(p['monthlyPremium']?.toString() ?? '0') ?? 0.0;
  final annual = double.tryParse(p['annualPremium']?.toString() ?? '0') ?? 0.0;

  return DataRow(
  cells: [
  DataCell(
  Container(
  width: 36,
  height: 36,
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: Color(0xFFE2E8F0)),
  ),
  child: Center(
  child: Text(icon, style: const TextStyle(fontSize: 18)),
  ),
  ),
  ),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(p['name'] ?? 'Policy Title', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13.5)),
  Text(p['underwriter'] ?? 'Islamic Underwriter', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
  ],
  ),
  ),
  DataCell(_buildCategoryBadge(cat)),
  DataCell(
  Row(
  children: [
  const Icon(Icons.verified_user_rounded, color: AppConstants.accentGreen, size: 16),
  const SizedBox(width: 4),
  Text(
  "₨ ${_currencyFormat.format(coverage)}",
  style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 14),
  ),
  ],
  ),
  ),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text("₨ ${_currencyFormat.format(monthly)} / Month", style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w900, fontSize: 12.5)),
  Text("₨ ${_currencyFormat.format(annual)} / Year", style: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5)),
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
  tooltip: isActive ? "Disable Policy" : "Enable Policy",
  onPressed: () => _togglePlanStatus(p, admin),
  ),
  IconButton(
  icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppConstants.accentBlue),
  tooltip: "Edit Policy Details",
  onPressed: () => _openAddEditPlanDialog(context, p, admin),
  ),
  IconButton(
  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.dangerRed),
  tooltip: "Delete Policy",
  onPressed: () => _confirmDeletePlan(context, p, admin),
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
  final p = list[idx];
  final status = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final cat = (p['category'] ?? 'HEALTH').toString().toUpperCase();
  final icon = (p['icon'] ?? '🛡️').toString();
  final coverage = double.tryParse(p['coverageAmount']?.toString() ?? '0') ?? 0.0;
  final monthly = double.tryParse(p['monthlyPremium']?.toString() ?? '0') ?? 0.0;

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
  Row(
  children: [
  Text(icon, style: const TextStyle(fontSize: 20)),
  const SizedBox(width: 8),
  Text(p['name'] ?? 'Policy', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 14.5)),
  ],
  ),
  _buildStatusBadge(isActive),
  ],
  ),
  const SizedBox(height: 8),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  _buildCategoryBadge(cat),
  Text("Coverage: ₨ ${_currencyFormat.format(coverage)}", style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 13.5)),
  ],
  ),
  const SizedBox(height: 4),
  Text("Premium: ₨ ${_currencyFormat.format(monthly)}/Month • By: ${p['underwriter'] ?? 'Takaful'}", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
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
  onPressed: () => _togglePlanStatus(p, admin),
  icon: Icon(isActive ? Icons.power_settings_new_rounded : Icons.check_circle_rounded, size: 14),
  label: Text(isActive ? "Disable" : "Enable", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
  ),
  Row(
  children: [
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.accentBlue),
  onPressed: () => _openAddEditPlanDialog(context, p, admin),
  icon: const Icon(Icons.edit_note_rounded, size: 16),
  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ),
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.dangerRed),
  onPressed: () => _confirmDeletePlan(context, p, admin),
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

  Widget _buildCategoryBadge(String cat) {
  Color color = AppConstants.accentGreen;
  if (cat == 'HEALTH') color = Color(0xFFEF4444);
  if (cat == 'LIFE') color = Color(0xFFA855F7);
  if (cat == 'MOTOR') color = Color(0xFF38BDF8);
  if (cat == 'DEVICE') color = Color(0xFFFBBF24);
  if (cat == 'TRAVEL') color = Color(0xFF22C55E);

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
  decoration: BoxDecoration(
  color: color.withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  ),
  child: Text(cat, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
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
  fontWeight: FontWeight.w900,
  ),
  ),
  );
  }

  // Add / Edit Modal Dialog
  void _openAddEditPlanDialog(BuildContext context, Map<String, dynamic>? existing, AdminProvider admin) {
  final isEdit = existing != null;
  final nameController = TextEditingController(text: isEdit ? existing['name'] : '');
  final coverageController = TextEditingController(text: isEdit ? existing['coverageAmount'].toString() : '500000');
  final monthlyController = TextEditingController(text: isEdit ? existing['monthlyPremium'].toString() : '350');
  final annualController = TextEditingController(text: isEdit ? existing['annualPremium'].toString() : '3800');
  final iconController = TextEditingController(text: isEdit ? existing['icon'] : '🛡️');
  final underwriterController = TextEditingController(text: isEdit ? existing['underwriter'] : 'Pak-Qatar Family Takaful');
  final benefitsController = TextEditingController(text: isEdit ? existing['benefits'] : '');

  String category = isEdit ? (existing['category'] ?? 'HEALTH') : 'HEALTH';
  String status = isEdit ? (existing['status'] ?? 'ACTIVE') : 'ACTIVE';

  showDialog(
  context: context,
  builder: (ctx) => StatefulBuilder(
  builder: (ctx, setDialogState) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: Text(
  isEdit ? "Edit Policy: ${existing['name']}" : "Create Islamic Takaful Policy",
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
  ),
  content: Container(
  constraints: const BoxConstraints(maxWidth: 540),
  child: SingleChildScrollView(
  child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  children: [
  // Icon Field
  SizedBox(
  width: 70,
  child: TextField(
  controller: iconController,
  textAlign: TextAlign.center,
  style: const TextStyle(fontSize: 20),
  decoration: InputDecoration(
  labelText: "ICON",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 10),
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Policy Title
  Expanded(
  child: TextField(
  controller: nameController,
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "POLICY TITLE / MARKETING NAME",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. Sehat Tahaffuz Health Care",
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
  // Category Selector
  Expanded(
  child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
  value: category,
  dropdownColor: AppConstants.surfaceCard,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "HEALTH", child: Text("🏥 Health Care")),
  DropdownMenuItem(value: "LIFE", child: Text("🛡️ Accidental Life")),
  DropdownMenuItem(value: "MOTOR", child: Text("🛵 Bike & Motor")),
  DropdownMenuItem(value: "DEVICE", child: Text("📱 Smartphone Screen")),
  DropdownMenuItem(value: "TRAVEL", child: Text("✈️ Travel & Transit")),
  ],
  onChanged: (val) {
  if (val != null) setDialogState(() => category = val);
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
  isExpanded: true,
  dropdownColor: AppConstants.surfaceCard,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, fontWeight: FontWeight.bold),
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
  Row(
  children: [
  // Coverage Amount
  Expanded(
  child: TextField(
  controller: coverageController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "MAX COVERAGE LIMIT (PKR)",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "500000",
  prefixText: "₨ ",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Underwriter Partner
  Expanded(
  child: TextField(
  controller: underwriterController,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
  decoration: InputDecoration(
  labelText: "UNDERWRITER PARTNER",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "Pak-Qatar Family Takaful",
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
  // Monthly Premium
  Expanded(
  child: TextField(
  controller: monthlyController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "MONTHLY PREMIUM (PKR)",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "350",
  prefixText: "₨ ",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Annual Premium
  Expanded(
  child: TextField(
  controller: annualController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  style: const TextStyle(color: Color(0xFF0F172A)),
  decoration: InputDecoration(
  labelText: "ANNUAL PREMIUM (PKR)",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "3800",
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
  // Benefits & Terms
  TextField(
  controller: benefitsController,
  maxLines: 2,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
  decoration: InputDecoration(
  labelText: "POLICY BENEFITS & COVERAGE SUMMARY",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "Daily hospitalization cash up to ₨ 5,000/day + ICU & accidental coverage.",
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
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: Color(0xFF021A13)),
  onPressed: () async {
  final name = nameController.text.trim();
  final coverage = double.tryParse(coverageController.text.trim()) ?? 0.0;
  final monthly = double.tryParse(monthlyController.text.trim()) ?? 0.0;
  if (name.isEmpty || coverage <= 0 || monthly <= 0) return;

  Navigator.pop(ctx);

  final planObj = {
  'id': isEdit ? existing['id'] : 'plan_${DateTime.now().millisecondsSinceEpoch}',
  'name': name,
  'category': category,
  'coverageAmount': coverage,
  'monthlyPremium': monthly,
  'annualPremium': double.tryParse(annualController.text.trim()) ?? (monthly * 11),
  'icon': iconController.text.trim().isEmpty ? '🛡️' : iconController.text.trim(),
  'underwriter': underwriterController.text.trim(),
  'benefits': benefitsController.text.trim(),
  'status': status,
  };

  final updatedList = List.from(_plansList);
  if (isEdit) {
  final idx = updatedList.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) updatedList[idx] = planObj;
  } else {
  updatedList.add(planObj);
  }

  await _savePlansList(updatedList, admin);
  },
  child: const Text("Save Takaful Policy", style: TextStyle(fontWeight: FontWeight.w900)),
  ),
  ],
  ),
  ),
  );
  }

  // Toggle Plan Status
  Future<void> _togglePlanStatus(Map<String, dynamic> p, AdminProvider admin) async {
  final currentStatus = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
  final newStatus = currentStatus == 'ACTIVE' ? 'DISABLED' : 'ACTIVE';

  final updatedList = List.from(_plansList);
  final idx = updatedList.indexWhere((x) => x['id'] == p['id']);
  if (idx != -1) {
  updatedList[idx]['status'] = newStatus;
  await _savePlansList(updatedList, admin);
  }
  }

  // Confirm Delete Plan
  void _confirmDeletePlan(BuildContext context, Map<String, dynamic> p, AdminProvider admin) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: const Text("Delete Policy?", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w900)),
  content: Text("Kya aap waqai \"${p['name']}\" ko active Takaful catalog se delete karna chahte hain?", style: const TextStyle(color: AppConstants.textMuted)),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Color(0xFF0F172A)),
  onPressed: () async {
  Navigator.pop(ctx);
  final updatedList = List.from(_plansList);
  updatedList.removeWhere((x) => x['id'] == p['id']);
  await _savePlansList(updatedList, admin);
  },
  child: const Text("Delete"),
  ),
  ],
  ),
  );
  }

  Future<void> _savePlansList(List updatedList, AdminProvider admin) async {
  setState(() => _isSaving = true);
  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'save_config'},
  data: {'takafulPlans': updatedList},
  );

  if (res.data['status'] == 'success') {
  setState(() => _plansList = updatedList);
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ Takaful insurance policies synchronized live!", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }
  }
  } catch (_) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Failed to update Takaful plans.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isSaving = false);
  }
  }
}
