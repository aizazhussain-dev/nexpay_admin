import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class BillProvidersCmsScreen extends StatefulWidget {
  const BillProvidersCmsScreen({super.key});

  @override
  State<BillProvidersCmsScreen> createState() => _BillProvidersCmsScreenState();
}

class _BillProvidersCmsScreenState extends State<BillProvidersCmsScreen> {
  final ApiClient _api = ApiClient();

  List _providersList = [];
  String _searchQuery = "";
  String _categoryFilter = "ALL"; // ALL, ELECTRICITY, GAS, WATER, INTERNET
  String _statusFilter = "ALL"; // ALL, ACTIVE, DISABLED
  bool _isSaving = false;
  bool _isInitialized = false;

  // Default national billing providers fallback
  final List _defaultProviders = [
  {
  'id': 'kelectric',
  'name': 'K-Electric (Karachi)',
  'category': 'ELECTRICITY',
  'consumerDigits': 13,
  'fee': 0.0,
  'status': 'ACTIVE',
  'icon': '⚡',
  'sampleReference': '0400012345678',
  },
  {
  'id': 'lesco',
  'name': 'LESCO (Lahore Electric)',
  'category': 'ELECTRICITY',
  'consumerDigits': 14,
  'fee': 0.0,
  'status': 'ACTIVE',
  'icon': '⚡',
  'sampleReference': '08112345678901',
  },
  {
  'id': 'hesco',
  'name': 'HESCO (Hyderabad Electric)',
  'category': 'ELECTRICITY',
  'consumerDigits': 14,
  'fee': 0.0,
  'status': 'ACTIVE',
  'icon': '⚡',
  'sampleReference': '12112345678901',
  },
  {
  'id': 'ssgc',
  'name': 'SSGC (Sui Southern Gas)',
  'category': 'GAS',
  'consumerDigits': 10,
  'fee': 0.0,
  'status': 'ACTIVE',
  'icon': '🔥',
  'sampleReference': '8192019281',
  },
  {
  'id': 'sngpl',
  'name': 'SNGPL (Sui Northern Gas)',
  'category': 'GAS',
  'consumerDigits': 11,
  'fee': 0.0,
  'status': 'ACTIVE',
  'icon': '🔥',
  'sampleReference': '99201928102',
  },
  {
  'id': 'ptcl',
  'name': 'PTCL Landline & Flash Fiber',
  'category': 'INTERNET',
  'consumerDigits': 10,
  'fee': 0.0,
  'status': 'ACTIVE',
  'icon': '🌐',
  'sampleReference': '1000291029',
  },
  {
  'id': 'stormfiber',
  'name': 'StormFiber Broadband',
  'category': 'INTERNET',
  'consumerDigits': 8,
  'fee': 0.0,
  'status': 'ACTIVE',
  'icon': '🌐',
  'sampleReference': '88291029',
  },
  {
  'id': 'wasa',
  'name': 'WASA Water & Sanitation',
  'category': 'WATER',
  'consumerDigits': 8,
  'fee': 0.0,
  'status': 'ACTIVE',
  'icon': '💧',
  'sampleReference': '12903810',
  },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadProvidersFromProvider();
      _isInitialized = true;
    }
  }

  void _loadProvidersFromProvider() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;

    if (cfg['billProviders'] is List && (cfg['billProviders'] as List).isNotEmpty) {
      final list = (cfg['billProviders'] as List)
          .whereType()
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
      setState(() => _providersList = list);
    } else {
      setState(() => _providersList = List.from(_defaultProviders));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredList = _providersList.where((p) {
      final status = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
      final cat = (p['category'] ?? 'ELECTRICITY').toString().toUpperCase();

      if (_categoryFilter != "ALL" && cat != _categoryFilter) return false;
      if (_statusFilter == "ACTIVE" && status != "ACTIVE") return false;
      if (_statusFilter == "DISABLED" && status != "DISABLED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (p['name'] ?? '').toString().toLowerCase();
        final id = (p['id'] ?? '').toString().toLowerCase();
        return name.contains(q) || id.contains(q) || cat.contains(q);
      }
      return true;
    }).toList();

    int activeCount = _providersList.where((p) => (p['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE').length;
    int electricityCount = _providersList.where((p) => (p['category'] ?? '').toString().toUpperCase() == 'ELECTRICITY').length;
    int gasWaterCount = _providersList.where((p) {
      final c = (p['category'] ?? '').toString().toUpperCase();
      return c == 'GAS' || c == 'WATER';
    }).length;

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
                          "Utility Bill Companies & Providers CMS",
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
                            "$activeCount BILLERS ONLINE",
                            style: const TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Manage Electricity DISCOs, Sui Gas companies, WASA water boards, broadband ISPs, and reference number validation",
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
                    onPressed: () => _openAddEditProviderDialog(context, null, admin),
                    icon: const Icon(Icons.add_business_rounded, size: 18),
                    label: const Text("Add Utility Biller", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFF94A3B8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _loadProvidersFromProvider();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✓ Reloaded utility billers from memory.")),
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
              _buildMetricCard("ACTIVE BILLERS", "$activeCount Providers", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("POWER DISCOS", "$electricityCount Companies", AppConstants.accentGold, isDesktop),
              _buildMetricCard("GAS & WATER UTILITIES", "$gasWaterCount Providers", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("TOTAL BILLERS", "${_providersList.length} Integrated", Color(0xFFA855F7), isDesktop),
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
                    hintText: "Search Biller, DISCO, Gas, ISP...",
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
              _buildCategoryChip("ALL", "All Utilities"),
              _buildCategoryChip("ELECTRICITY", "⚡ Electricity"),
              _buildCategoryChip("GAS", "🔥 Sui Gas"),
              _buildCategoryChip("INTERNET", "🌐 Broadband & Fiber"),
              _buildCategoryChip("WATER", "💧 Water & Sanitation"),
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
                  Icon(Icons.receipt_long_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No billing utility companies found",
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
  DataColumn(label: Text("BILLER COMPANY NAME", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("UTILITY CATEGORY", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("CONSUMER DIGITS & FORMAT", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("PLATFORM SURCHARGE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("EXECUTIVE ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((p) {
  final status = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final cat = (p['category'] ?? 'ELECTRICITY').toString().toUpperCase();
  final icon = (p['icon'] ?? '⚡').toString();
  final digits = p['consumerDigits'] ?? 14;
  final fee = double.tryParse(p['fee']?.toString() ?? '0') ?? 0.0;

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
  Text(p['name'] ?? 'Biller Name', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13.5)),
  Text("ID: ${p['id'] ?? '-'}", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11, fontFamily: 'monospace')),
  ],
  ),
  ),
  DataCell(_buildCategoryBadge(cat)),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text("$digits Digits Number", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12)),
  Text("e.g. ${p['sampleReference'] ?? '-'}", style: const TextStyle(color: AppConstants.accentBlue, fontSize: 10.5, fontFamily: 'monospace')),
  ],
  ),
  ),
  DataCell(
  Text(
  fee == 0.0 ? "FREE (₨ 0)" : "₨ ${fee.toStringAsFixed(0)}",
  style: TextStyle(
  color: fee == 0.0 ? AppConstants.accentGreen : AppConstants.accentGold,
  fontWeight: FontWeight.w900,
  fontSize: 12.5,
  ),
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
  tooltip: isActive ? "Disable Provider" : "Enable Provider",
  onPressed: () => _toggleProviderStatus(p, admin),
  ),
  IconButton(
  icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppConstants.accentBlue),
  tooltip: "Edit Provider Parameters",
  onPressed: () => _openAddEditProviderDialog(context, p, admin),
  ),
  IconButton(
  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.dangerRed),
  tooltip: "Delete Provider",
  onPressed: () => _confirmDeleteProvider(context, p, admin),
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
  final cat = (p['category'] ?? 'ELECTRICITY').toString().toUpperCase();
  final icon = (p['icon'] ?? '⚡').toString();
  final digits = p['consumerDigits'] ?? 14;
  final fee = double.tryParse(p['fee']?.toString() ?? '0') ?? 0.0;

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
  Text(p['name'] ?? 'Biller', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 14.5)),
  ],
  ),
  _buildStatusBadge(isActive),
  ],
  ),
  const SizedBox(height: 10),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  _buildCategoryBadge(cat),
  Text(
  fee == 0.0 ? "Fee: FREE" : "Fee: ₨ ${fee.toStringAsFixed(0)}",
  style: TextStyle(color: fee == 0.0 ? AppConstants.accentGreen : AppConstants.accentGold, fontWeight: FontWeight.bold, fontSize: 11.5),
  ),
  ],
  ),
  const Divider(color: Color(0xFFE2E8F0), height: 20),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text("Ref Digits: $digits Digits", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
  Text("Format: ${p['sampleReference'] ?? '-'}", style: const TextStyle(color: AppConstants.accentBlue, fontFamily: 'monospace', fontSize: 11)),
  ],
  ),
  const SizedBox(height: 12),
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
  onPressed: () => _toggleProviderStatus(p, admin),
  icon: Icon(isActive ? Icons.power_settings_new_rounded : Icons.check_circle_rounded, size: 14),
  label: Text(isActive ? "Disable Biller" : "Enable Biller", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
  ),
  Row(
  children: [
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.accentBlue),
  onPressed: () => _openAddEditProviderDialog(context, p, admin),
  icon: const Icon(Icons.edit_note_rounded, size: 16),
  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ),
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.dangerRed),
  onPressed: () => _confirmDeleteProvider(context, p, admin),
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
  if (cat == 'ELECTRICITY') color = Colors.amber;
  if (cat == 'GAS') color = Colors.deepOrange;
  if (cat == 'WATER') color = Colors.cyan;
  if (cat == 'INTERNET') color = Color(0xFFA855F7);

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
  void _openAddEditProviderDialog(BuildContext context, Map<String, dynamic>? existing, AdminProvider admin) {
  final isEdit = existing != null;
  final idController = TextEditingController(text: isEdit ? existing['id'] : '');
  final nameController = TextEditingController(text: isEdit ? existing['name'] : '');
  final digitsController = TextEditingController(text: isEdit ? existing['consumerDigits'].toString() : '14');
  final feeController = TextEditingController(text: isEdit ? existing['fee'].toString() : '0.0');
  final iconController = TextEditingController(text: isEdit ? existing['icon'] : '⚡');
  final sampleController = TextEditingController(text: isEdit ? existing['sampleReference'] : '12345678901234');

  String category = isEdit ? (existing['category'] ?? 'ELECTRICITY') : 'ELECTRICITY';
  String status = isEdit ? (existing['status'] ?? 'ACTIVE') : 'ACTIVE';

  showDialog(
  context: context,
  builder: (ctx) => StatefulBuilder(
  builder: (ctx, setDialogState) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: Text(
  isEdit ? "Edit Biller: ${existing['name']}" : "Add Utility Billing Company",
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
  ),
  content: Container(
  constraints: const BoxConstraints(maxWidth: 520),
  child: SingleChildScrollView(
  child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  children: [
  // Emoji / Icon
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
  // Company Name
  Expanded(
  child: TextField(
  controller: nameController,
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "UTILITY COMPANY LEGAL NAME",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. K-Electric (Karachi)",
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
  // ID / Slug
  Expanded(
  child: TextField(
  controller: idController,
  readOnly: isEdit,
  style: const TextStyle(color: Color(0xFF0F172A), fontFamily: 'monospace'),
  decoration: InputDecoration(
  labelText: "UNIQUE SLUG / ID",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. kelectric",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Utility Category Dropdown
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
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "ELECTRICITY", child: Text("⚡ Electricity")),
  DropdownMenuItem(value: "GAS", child: Text("🔥 Sui Gas")),
  DropdownMenuItem(value: "WATER", child: Text("💧 Water Board")),
  DropdownMenuItem(value: "INTERNET", child: Text("🌐 Broadband")),
  ],
  onChanged: (val) {
  if (val != null) setDialogState(() => category = val);
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
  // Consumer Digits
  Expanded(
  child: TextField(
  controller: digitsController,
  keyboardType: TextInputType.number,
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "REF DIGITS LENGTH",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "14",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Surcharge Fee
  Expanded(
  child: TextField(
  controller: feeController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  style: const TextStyle(color: Color(0xFF0F172A)),
  decoration: InputDecoration(
  labelText: "CONVENIENCE FEE (PKR)",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "0.0",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 12),
  // Sample Consumer Reference
  TextField(
  controller: sampleController,
  style: const TextStyle(color: Color(0xFF0F172A), fontFamily: 'monospace'),
  decoration: InputDecoration(
  labelText: "SAMPLE CONSUMER REFERENCE FORMAT",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "0400012345678",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  const SizedBox(height: 12),
  // Status Selector
  Container(
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
  DropdownMenuItem(value: "ACTIVE", child: Text("🟢 Active (Accepting Bill Payments)")),
  DropdownMenuItem(value: "DISABLED", child: Text("🔴 Disabled (Cutoff / Under Maintenance)")),
  ],
  onChanged: (val) {
  if (val != null) setDialogState(() => status = val);
  },
  ),
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
  final id = idController.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  if (name.isEmpty || id.isEmpty) return;

  Navigator.pop(ctx);

  final provObj = {
  'id': id,
  'name': name,
  'category': category,
  'consumerDigits': int.tryParse(digitsController.text.trim()) ?? 14,
  'fee': double.tryParse(feeController.text.trim()) ?? 0.0,
  'icon': iconController.text.trim().isEmpty ? '⚡' : iconController.text.trim(),
  'sampleReference': sampleController.text.trim(),
  'status': status,
  };

  final updatedList = List.from(_providersList);
  if (isEdit) {
  final idx = updatedList.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) updatedList[idx] = provObj;
  } else {
  updatedList.add(provObj);
  }

  await _saveProvidersList(updatedList, admin);
  },
  child: const Text("Save Utility Biller", style: TextStyle(fontWeight: FontWeight.w900)),
  ),
  ],
  ),
  ),
  );
  }

  // Toggle Provider Status
  Future<void> _toggleProviderStatus(Map<String, dynamic> p, AdminProvider admin) async {
  final currentStatus = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
  final newStatus = currentStatus == 'ACTIVE' ? 'DISABLED' : 'ACTIVE';

  final updatedList = List.from(_providersList);
  final idx = updatedList.indexWhere((x) => x['id'] == p['id']);
  if (idx != -1) {
  updatedList[idx]['status'] = newStatus;
  await _saveProvidersList(updatedList, admin);
  }
  }

  // Confirm Delete Provider
  void _confirmDeleteProvider(BuildContext context, Map<String, dynamic> p, AdminProvider admin) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: const Text("Delete Biller?", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w900)),
  content: Text("Kya aap waqai ${p['name']} ko active billers list se delete karna chahte hain?", style: const TextStyle(color: AppConstants.textMuted)),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Color(0xFF0F172A)),
  onPressed: () async {
  Navigator.pop(ctx);
  final updatedList = List.from(_providersList);
  updatedList.removeWhere((x) => x['id'] == p['id']);
  await _saveProvidersList(updatedList, admin);
  },
  child: const Text("Delete"),
  ),
  ],
  ),
  );
  }

  Future<void> _saveProvidersList(List updatedList, AdminProvider admin) async {
  setState(() => _isSaving = true);
  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'save_config'},
  data: {'billProviders': updatedList},
  );

  if (res.data['status'] == 'success') {
  setState(() => _providersList = updatedList);
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ Utility billers synchronized live!", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }
  }
  } catch (_) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Failed to update billers.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isSaving = false);
  }
  }
}
