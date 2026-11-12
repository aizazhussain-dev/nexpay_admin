import '../../widgets/institutional_scroll.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class TelecomPackagesCmsScreen extends StatefulWidget {
  const TelecomPackagesCmsScreen({super.key});

  @override
  State<TelecomPackagesCmsScreen> createState() => _TelecomPackagesCmsScreenState();
}

class _TelecomPackagesCmsScreenState extends State<TelecomPackagesCmsScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  List _packagesList = [];
  String _searchQuery = "";
  String _networkFilter = "ALL"; // ALL, JAZZ, TELENOR, ZONG, UFONE
  String _validityFilter = "ALL"; // ALL, DAILY, WEEKLY, MONTHLY
  String _statusFilter = "ALL"; // ALL, ACTIVE, DISABLED
  bool _isSaving = false;
  bool _isInitialized = false;

  // National Telco default packages fallback
  final List _defaultPackages = [
  {
  'id': 'jazz_w_super',
  'network': 'JAZZ',
  'name': 'Weekly Super Duper',
  'validity': 'WEEKLY',
  'price': 420.0,
  'data': '10 GB',
  'onNet': '5000 Mins',
  'offNet': '100 Mins',
  'sms': '5000 SMS',
  'status': 'ACTIVE',
  },
  {
  'id': 'jazz_m_super',
  'network': 'JAZZ',
  'name': 'Monthly Super Duper Plus',
  'validity': 'MONTHLY',
  'price': 1250.0,
  'data': '30 GB',
  'onNet': '10000 Mins',
  'offNet': '300 Mins',
  'sms': '10000 SMS',
  'status': 'ACTIVE',
  },
  {
  'id': 'zong_w_pro',
  'network': 'ZONG',
  'name': 'Weekly Pro Plus',
  'validity': 'WEEKLY',
  'price': 480.0,
  'data': '40 GB',
  'onNet': 'Unlimited',
  'offNet': '250 Mins',
  'sms': 'Unlimited',
  'status': 'ACTIVE',
  },
  {
  'id': 'zong_m_super',
  'network': 'ZONG',
  'name': 'Monthly Super Card',
  'validity': 'MONTHLY',
  'price': 999.0,
  'data': '20 GB',
  'onNet': '5000 Mins',
  'offNet': '350 Mins',
  'sms': '5000 SMS',
  'status': 'ACTIVE',
  },
  {
  'id': 'telenor_w_ultra',
  'network': 'TELENOR',
  'name': 'Weekly Ultra Data',
  'validity': 'WEEKLY',
  'price': 390.0,
  'data': '18 GB',
  'onNet': '1000 Mins',
  'offNet': '70 Mins',
  'sms': '1000 SMS',
  'status': 'ACTIVE',
  },
  {
  'id': 'telenor_m_easycard',
  'network': 'TELENOR',
  'name': 'Monthly EasyCard 1000',
  'validity': 'MONTHLY',
  'price': 950.0,
  'data': '15 GB',
  'onNet': '7000 Mins',
  'offNet': '300 Mins',
  'sms': '7000 SMS',
  'status': 'ACTIVE',
  },
  {
  'id': 'ufone_w_digital',
  'network': 'UFONE',
  'name': 'Weekly Digital Grand',
  'validity': 'WEEKLY',
  'price': 430.0,
  'data': '100 GB',
  'onNet': '7000 Mins',
  'offNet': '100 Mins',
  'sms': '7000 SMS',
  'status': 'ACTIVE',
  },
  {
  'id': 'ufone_m_supercard',
  'network': 'UFONE',
  'name': 'Super Card Grand',
  'validity': 'MONTHLY',
  'price': 1050.0,
  'data': '20 GB',
  'onNet': '6000 Mins',
  'offNet': '450 Mins',
  'sms': '6000 SMS',
  'status': 'ACTIVE',
  },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadPackagesFromProvider();
      _isInitialized = true;
    }
  }

  void _loadPackagesFromProvider() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;

    if (cfg['telecomPackages'] is List && (cfg['telecomPackages'] as List).isNotEmpty) {
      final list = (cfg['telecomPackages'] as List)
          .whereType()
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
      setState(() => _packagesList = list);
    } else {
      setState(() => _packagesList = <dynamic>[]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredList = _packagesList.where((p) {
      final net = (p['network'] ?? 'JAZZ').toString().toUpperCase();
      final val = (p['validity'] ?? 'MONTHLY').toString().toUpperCase();
      final status = (p['status'] ?? 'ACTIVE').toString().toUpperCase();

      if (_networkFilter != "ALL" && net != _networkFilter) return false;
      if (_validityFilter != "ALL" && val != _validityFilter) return false;
      if (_statusFilter == "ACTIVE" && status != "ACTIVE") return false;
      if (_statusFilter == "DISABLED" && status != "DISABLED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (p['name'] ?? '').toString().toLowerCase();
        final id = (p['id'] ?? '').toString().toLowerCase();
        final data = (p['data'] ?? '').toString().toLowerCase();
        return name.contains(q) || id.contains(q) || data.contains(q) || net.contains(q);
      }
      return true;
    }).toList();

    int activeCount = _packagesList.where((p) => (p['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE').length;
    int jazzCount = _packagesList.where((p) => (p['network'] ?? '').toString().toUpperCase() == 'JAZZ').length;
    int zongCount = _packagesList.where((p) => (p['network'] ?? '').toString().toUpperCase() == 'ZONG').length;
    int telenorCount = _packagesList.where((p) => (p['network'] ?? '').toString().toUpperCase() == 'TELENOR').length;
    int ufoneCount = _packagesList.where((p) => (p['network'] ?? '').toString().toUpperCase() == 'UFONE').length;

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
                          "Telecom Bundles & Mobile Packages CMS",
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
                            "$activeCount PACKAGES ONLINE",
                            style: const TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Manage prepaid and hybrid packages across Jazz, Zong, Telenor, and Ufone with live pricing and quotas",
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
                    onPressed: () => _openAddEditPackageDialog(context, null, admin),
                    icon: const Icon(Icons.add_to_photos_rounded, size: 18),
                    label: const Text("Add New Bundle", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF94A3B8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _loadPackagesFromProvider();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✓ Reloaded packages from memory.")),
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
              _buildMetricCard("JAZZ BUNDLES", "$jazzCount Packages", Color(0xFFEF4444), isDesktop),
              _buildMetricCard("ZONG 4G BUNDLES", "$zongCount Packages", Color(0xFFEC4899), isDesktop),
              _buildMetricCard("TELENOR BUNDLES", "$telenorCount Packages", Color(0xFF38BDF8), isDesktop),
              _buildMetricCard("UFONE 4G BUNDLES", "$ufoneCount Packages", Color(0xFFF97316), isDesktop),
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
                    hintText: "Search Package, Quota, Network...",
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
              _buildNetworkFilterChip("ALL", "All Networks"),
              _buildNetworkFilterChip("JAZZ", "🔴 Jazz", Color(0xFFEF4444)),
              _buildNetworkFilterChip("ZONG", "🌸 Zong", Color(0xFFEC4899)),
              _buildNetworkFilterChip("TELENOR", "🔵 Telenor", Color(0xFF38BDF8)),
              _buildNetworkFilterChip("UFONE", "🟠 Ufone", Color(0xFFF97316)),
              const SizedBox(width: 8),
              _buildValidityFilterChip("ALL", "All Validity"),
              _buildValidityFilterChip("DAILY", "Daily"),
              _buildValidityFilterChip("WEEKLY", "Weekly"),
              _buildValidityFilterChip("MONTHLY", "Monthly"),
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
                  Icon(Icons.signal_cellular_alt_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No telecom packages found matching query",
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

  Widget _buildNetworkFilterChip(String key, String label, [Color? activeColor]) {
    final isSelected = _networkFilter == key;
    final color = activeColor ?? AppConstants.accentGreen;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.25),
      backgroundColor: AppConstants.surface,
      labelStyle: TextStyle(
        color: isSelected ? color : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? color : Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() => _networkFilter = key),
    );
  }

  Widget _buildValidityFilterChip(String key, String label) {
    final isSelected = _validityFilter == key;
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
      onSelected: (_) => setState(() => _validityFilter = key),
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
  columnSpacing: 24,
  columns: const [
  DataColumn(label: Text("NETWORK", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("BUNDLE TITLE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("VALIDITY", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("INTERNET DATA", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("CALLS & SMS QUOTA", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("PRICE (PKR)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((p) {
  final status = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final net = (p['network'] ?? 'JAZZ').toString().toUpperCase();
  final val = (p['validity'] ?? 'MONTHLY').toString().toUpperCase();
  final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;

  return DataRow(
  cells: [
  DataCell(_buildNetworkBadge(net)),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(p['name'] ?? 'Bundle Name', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13.5)),
  Text("ID: ${p['id'] ?? '-'}", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11, fontFamily: 'monospace')),
  ],
  ),
  ),
  DataCell(
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: Color(0xFFE2E8F0),
  borderRadius: BorderRadius.circular(8),
  ),
  child: Text(val, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 11)),
  ),
  ),
  DataCell(
  Row(
  children: [
  const Icon(Icons.wifi_rounded, color: AppConstants.accentGreen, size: 15),
  const SizedBox(width: 6),
  Text(
  p['data'] ?? '0 GB',
  style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w700, fontSize: 13),
  ),
  ],
  ),
  ),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text("📞 ${p['onNet'] ?? '0'} On-Net • ${p['offNet'] ?? '0'} Off-Net", style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
  Text("💬 ${p['sms'] ?? '0'}", style: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5)),
  ],
  ),
  ),
  DataCell(
  Text(
  "₨ ${_currencyFormat.format(price)}",
  style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w700, fontSize: 14),
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
  tooltip: isActive ? "Disable Package" : "Enable Package",
  onPressed: () => _togglePackageStatus(p, admin),
  ),
  IconButton(
  icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppConstants.accentBlue),
  tooltip: "Edit Package Details",
  onPressed: () => _openAddEditPackageDialog(context, p, admin),
  ),
  IconButton(
  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.dangerRed),
  tooltip: "Delete Package",
  onPressed: () => _confirmDeletePackage(context, p, admin),
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
  final net = (p['network'] ?? 'JAZZ').toString().toUpperCase();
  final val = (p['validity'] ?? 'MONTHLY').toString().toUpperCase();
  final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;

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
  _buildNetworkBadge(net),
  const SizedBox(width: 8),
  Text(p['name'] ?? 'Bundle', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14.5)),
  ],
  ),
  _buildStatusBadge(isActive),
  ],
  ),
  const SizedBox(height: 10),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text("Data: ${p['data'] ?? '0 GB'}", style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w700, fontSize: 14)),
  Text("₨ ${_currencyFormat.format(price)}", style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w700, fontSize: 15)),
  ],
  ),
  const SizedBox(height: 4),
  Text("Validity: $val • Calls: ${p['onNet'] ?? '0'} On-Net / ${p['offNet'] ?? '0'} Off-Net", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
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
  onPressed: () => _togglePackageStatus(p, admin),
  icon: Icon(isActive ? Icons.power_settings_new_rounded : Icons.check_circle_rounded, size: 14),
  label: Text(isActive ? "Disable" : "Enable", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
  ),
  Row(
  children: [
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.accentBlue),
  onPressed: () => _openAddEditPackageDialog(context, p, admin),
  icon: const Icon(Icons.edit_note_rounded, size: 16),
  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ),
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.dangerRed),
  onPressed: () => _confirmDeletePackage(context, p, admin),
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

  Widget _buildNetworkBadge(String net) {
  Color color = Color(0xFFEF4444);
  if (net == 'ZONG') color = Color(0xFFEC4899);
  if (net == 'TELENOR') color = Color(0xFF38BDF8);
  if (net == 'UFONE') color = Color(0xFFF97316);

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: color.withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: color.withValues(alpha: 0.3)),
  ),
  child: Text(net, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
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
  void _openAddEditPackageDialog(BuildContext context, Map<String, dynamic>? existing, AdminProvider admin) {
  final isEdit = existing != null;
  final idController = TextEditingController(text: isEdit ? existing['id'] : '');
  final nameController = TextEditingController(text: isEdit ? existing['name'] : '');
  final priceController = TextEditingController(text: isEdit ? existing['price'].toString() : '400');
  final dataController = TextEditingController(text: isEdit ? existing['data'] : '10 GB');
  final onNetController = TextEditingController(text: isEdit ? existing['onNet'] : '1000 Mins');
  final offNetController = TextEditingController(text: isEdit ? existing['offNet'] : '100 Mins');
  final smsController = TextEditingController(text: isEdit ? existing['sms'] : '1000 SMS');

  String network = isEdit ? (existing['network'] ?? 'JAZZ') : 'JAZZ';
  String validity = isEdit ? (existing['validity'] ?? 'WEEKLY') : 'WEEKLY';
  String status = isEdit ? (existing['status'] ?? 'ACTIVE') : 'ACTIVE';

  showDialog(
  context: context,
  builder: (ctx) => StatefulBuilder(
  builder: (ctx, setDialogState) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: Text(
  isEdit ? "Edit Bundle: ${existing['name']}" : "Add Telecom Package",
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18),
  ),
  content: Container(
  constraints: const BoxConstraints(maxWidth: 520),
  child: InstitutionalVScroll(
  child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  children: [
  // Network Selector
  Expanded(
  child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
  value: network,
  dropdownColor: AppConstants.surfaceCard,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "JAZZ", child: Text("🔴 Jazz")),
  DropdownMenuItem(value: "ZONG", child: Text("🌸 Zong")),
  DropdownMenuItem(value: "TELENOR", child: Text("🔵 Telenor")),
  DropdownMenuItem(value: "UFONE", child: Text("🟠 Ufone")),
  ],
  onChanged: (val) {
  if (val != null) setDialogState(() => network = val);
  },
  ),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Validity Selector
  Expanded(
  child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
  value: validity,
  dropdownColor: AppConstants.surfaceCard,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "DAILY", child: Text("Daily (24 Hours)")),
  DropdownMenuItem(value: "WEEKLY", child: Text("Weekly (7 Days)")),
  DropdownMenuItem(value: "MONTHLY", child: Text("Monthly (30 Days)")),
  ],
  onChanged: (val) {
  if (val != null) setDialogState(() => validity = val);
  },
  ),
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 12),
  TextField(
  controller: nameController,
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "PACKAGE TITLE / MARKETING NAME",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. Weekly Super Duper Plus",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  // Price Field
  Expanded(
  child: TextField(
  controller: priceController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "PRICE (PKR)",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "420",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  prefixText: "₨ ",
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Data Quota
  Expanded(
  child: TextField(
  controller: dataController,
  style: const TextStyle(color: Color(0xFF0F172A)),
  decoration: InputDecoration(
  labelText: "INTERNET DATA",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "10 GB / 25 GB",
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
  // On-Net Calls
  Expanded(
  child: TextField(
  controller: onNetController,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
  decoration: InputDecoration(
  labelText: "SAME-NET MINS",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5),
  hintText: "5000 Mins",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Off-Net Calls
  Expanded(
  child: TextField(
  controller: offNetController,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
  decoration: InputDecoration(
  labelText: "OTHER-NET MINS",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5),
  hintText: "100 Mins",
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
  // SMS Quota
  Expanded(
  child: TextField(
  controller: smsController,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
  decoration: InputDecoration(
  labelText: "SMS ALLOCATION",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5),
  hintText: "5000 SMS",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
  final price = double.tryParse(priceController.text.trim()) ?? 0.0;
  if (name.isEmpty || price <= 0) return;

  Navigator.pop(ctx);

  final pkgObj = {
  'id': isEdit ? existing['id'] : '${network.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
  'network': network,
  'name': name,
  'validity': validity,
  'price': price,
  'data': dataController.text.trim(),
  'onNet': onNetController.text.trim(),
  'offNet': offNetController.text.trim(),
  'sms': smsController.text.trim(),
  'status': status,
  };

  final updatedList = List.from(_packagesList);
  if (isEdit) {
  final idx = updatedList.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) updatedList[idx] = pkgObj;
  } else {
  updatedList.add(pkgObj);
  }

  await _savePackagesList(updatedList, admin);
  },
  child: const Text("Save Package Live", style: TextStyle(fontWeight: FontWeight.w700)),
  ),
  ],
  ),
  ),
  );
  }

  // Toggle Package Status
  Future<void> _togglePackageStatus(Map<String, dynamic> p, AdminProvider admin) async {
  final currentStatus = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
  final newStatus = currentStatus == 'ACTIVE' ? 'DISABLED' : 'ACTIVE';

  final updatedList = List.from(_packagesList);
  final idx = updatedList.indexWhere((x) => x['id'] == p['id']);
  if (idx != -1) {
  updatedList[idx]['status'] = newStatus;
  await _savePackagesList(updatedList, admin);
  }
  }

  // Confirm Delete Package
  void _confirmDeletePackage(BuildContext context, Map<String, dynamic> p, AdminProvider admin) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: const Text("Delete Package?", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w700)),
  content: Text("Kya aap waqai ${p['network']} - ${p['name']} ko packages catalog se delete karna chahte hain?", style: const TextStyle(color: AppConstants.textMuted)),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Colors.white),
  onPressed: () async {
  Navigator.pop(ctx);
  final updatedList = List.from(_packagesList);
  updatedList.removeWhere((x) => x['id'] == p['id']);
  await _savePackagesList(updatedList, admin);
  },
  child: const Text("Delete"),
  ),
  ],
  ),
  );
  }

  Future<void> _savePackagesList(List updatedList, AdminProvider admin) async {
  setState(() => _isSaving = true);
  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'save_config'},
  data: {'telecomPackages': updatedList},
  );

  if (res.data['status'] == 'success') {
  setState(() => _packagesList = updatedList);
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ Telecom packages synchronized live!", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }
  }
  } catch (_) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Failed to update telecom packages.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isSaving = false);
  }
  }
}
