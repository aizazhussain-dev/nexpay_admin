import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class HomeBannersCmsScreen extends StatefulWidget {
  const HomeBannersCmsScreen({super.key});

  @override
  State<HomeBannersCmsScreen> createState() => _HomeBannersCmsScreenState();
}

class _HomeBannersCmsScreenState extends State<HomeBannersCmsScreen> {
  final ApiClient _api = ApiClient();

  List _bannersList = [];
  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, ACTIVE, DISABLED
  bool _isSaving = false;
  bool _isInitialized = false;

  // Default fallback banners matching PHP backend
  final List _defaultBanners = [
  {
  'id': 'banner_gold',
  'title': '24K Pure Bullion Vault',
  'subtitle': 'Live Spot Trading & Doorstep Mint Delivery',
  'imageUrl': 'https://images.unsplash.com/photo-1610375461246-83df859d849d?w=800&q=80',
  'targetScreen': 'gold',
  'status': 'ACTIVE',
  },
  {
  'id': 'banner_shop',
  'title': 'Netflix 4K & IPTV Mega Pass',
  'subtitle': 'Instant Private Keys from ₨ 450',
  'imageUrl': 'https://images.unsplash.com/photo-1574375927938-d5a98e8ffe85?w=800&q=80',
  'targetScreen': 'shop',
  'status': 'ACTIVE',
  },
  {
  'id': 'banner_savings',
  'title': 'Halal Savings Growth Pots',
  'subtitle': 'Up to 21.5% p.a. Shariah Certified Payouts',
  'imageUrl': 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=800&q=80',
  'targetScreen': 'savings',
  'status': 'ACTIVE',
  },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadBannersFromProvider();
      _isInitialized = true;
    }
  }

  void _loadBannersFromProvider() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;

    if (cfg['homeBanners'] is List && (cfg['homeBanners'] as List).isNotEmpty) {
      final list = (cfg['homeBanners'] as List)
          .whereType()
          .map((b) => Map<String, dynamic>.from(b))
          .where((b) => b['isDeleted'] != true)
          .toList();
      setState(() => _bannersList = list);
    } else {
      setState(() => _bannersList = List.from(_defaultBanners));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredList = _bannersList.where((b) {
      final status = (b['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (_statusFilter == "ACTIVE" && status != "ACTIVE") return false;
      if (_statusFilter == "DISABLED" && status != "DISABLED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final title = (b['title'] ?? '').toString().toLowerCase();
        final subtitle = (b['subtitle'] ?? '').toString().toLowerCase();
        final target = (b['targetScreen'] ?? '').toString().toLowerCase();
        return title.contains(q) || subtitle.contains(q) || target.contains(q);
      }
      return true;
    }).toList();

    int activeCount = _bannersList.where((b) => (b['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE').length;
    int disabledCount = _bannersList.length - activeCount;

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
                          "Promotional Home Banners & Sliders CMS",
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
                            color: Color(0xFFA855F7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Color(0xFFA855F7).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            "$activeCount LIVE BANNERS",
                            style: const TextStyle(color: Color(0xFFA855F7), fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Manage dynamic marketing sliders, campaign banners, and deep-link click target destinations",
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
                    onPressed: () => _openAddEditBannerDialog(context, null, admin),
                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                    label: const Text("Add New Banner", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFF94A3B8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _loadBannersFromProvider();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✓ Reloaded banners from memory.")),
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
              _buildMetricCard("ACTIVE PROMO BANNERS", "$activeCount Visible", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("DISABLED / HIDDEN", "$disabledCount Inactive", AppConstants.textMuted, isDesktop),
              _buildMetricCard("TOTAL BANNERS", "${_bannersList.length} In Rotation", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("DISPLAY LOCATION", "Mobile Home Dashboard", Color(0xFFA855F7), isDesktop),
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
                width: isDesktop ? 340 : double.infinity,
                child: TextField(
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search Title, Subtitle, Target...",
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
              _buildFilterChip("ALL", "All Banners (${_bannersList.length})"),
              _buildFilterChip("ACTIVE", "Active / Visible ($activeCount)"),
              _buildFilterChip("DISABLED", "Disabled ($disabledCount)"),
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
                  Icon(Icons.view_carousel_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No promotional banners found",
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

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _statusFilter == key;
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
  DataColumn(label: Text("PREVIEW", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("OFFER HEADLINE & DETAILS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("CLICK ACTION TARGET", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((b) {
  final status = (b['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final imgUrl = (b['imageUrl'] ?? '').toString();
  final target = (b['targetScreen'] ?? 'gold').toString().toUpperCase();

  return DataRow(
  cells: [
  DataCell(
  Container(
  width: 120,
  height: 56,
  decoration: BoxDecoration(
  color: Colors.black,
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: Color(0xFFE2E8F0)),
  ),
  child: ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: imgUrl.isNotEmpty
  ? Image.network(
  imgUrl,
  fit: BoxFit.cover,
  errorBuilder: (_, __, ___) => const Center(
  child: Icon(Icons.broken_image, color: Color(0xFF94A3B8), size: 20),
  ),
  )
      : const Center(
  child: Icon(Icons.image, color: Color(0xFF94A3B8), size: 20),
  ),
  ),
  ),
  ),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(b['title'] ?? 'Banner Title', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13.5)),
  const SizedBox(height: 2),
  Text(b['subtitle'] ?? '-', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
  ],
  ),
  ),
  DataCell(
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: Color(0xFFA855F7).withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: Color(0xFFA855F7).withValues(alpha: 0.3)),
  ),
  child: Text(
  "Target: $target",
  style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w800, fontSize: 11),
  ),
  ),
  ),
  DataCell(_buildStatusBadge(isActive)),
  DataCell(
  Row(
  children: [
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: AppConstants.surfaceCard,
  foregroundColor: Color(0xFF0F172A),
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  onPressed: () => _openAddEditBannerDialog(context, b, admin),
  icon: const Icon(Icons.edit_note_rounded, size: 16, color: AppConstants.accentBlue),
  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
  ),
  const SizedBox(width: 6),
  IconButton(
  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.dangerRed),
  tooltip: "Delete Banner",
  onPressed: () => _confirmDeleteBanner(context, b, admin),
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
  final b = list[idx];
  final status = (b['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final imgUrl = (b['imageUrl'] ?? '').toString();
  final target = (b['targetScreen'] ?? 'gold').toString().toUpperCase();

  return Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: isActive ? Color(0xFFA855F7).withValues(alpha: 0.3) : Color(0xFFE2E8F0)),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  // Banner Preview Image
  Container(
  height: 120,
  width: double.infinity,
  decoration: BoxDecoration(
  color: Colors.black,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Color(0xFFE2E8F0)),
  ),
  child: ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: imgUrl.isNotEmpty
  ? Image.network(
  imgUrl,
  fit: BoxFit.cover,
  errorBuilder: (_, __, ___) => const Center(
  child: Icon(Icons.broken_image, color: Color(0xFF94A3B8)),
  ),
  )
      : const Center(
  child: Icon(Icons.image, color: Color(0xFF94A3B8)),
  ),
  ),
  ),
  const SizedBox(height: 12),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Expanded(
  child: Text(
  b['title'] ?? 'Banner Title',
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 15),
  ),
  ),
  _buildStatusBadge(isActive),
  ],
  ),
  const SizedBox(height: 4),
  Text(b['subtitle'] ?? '-', style: const TextStyle(color: AppConstants.textMuted, fontSize: 12)),
  const Divider(color: Color(0xFFE2E8F0), height: 20),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: Color(0xFFA855F7).withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  ),
  child: Text("Target: $target", style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w800, fontSize: 11)),
  ),
  Row(
  children: [
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.accentBlue),
  onPressed: () => _openAddEditBannerDialog(context, b, admin),
  icon: const Icon(Icons.edit_note_rounded, size: 16),
  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ),
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.dangerRed),
  onPressed: () => _confirmDeleteBanner(context, b, admin),
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
  fontWeight: FontWeight.w900,
  ),
  ),
  );
  }

  // Add / Edit Modal Dialog
  void _openAddEditBannerDialog(BuildContext context, Map<String, dynamic>? existing, AdminProvider admin) {
  final isEdit = existing != null;
  final titleController = TextEditingController(text: isEdit ? existing['title'] : '');
  final subtitleController = TextEditingController(text: isEdit ? existing['subtitle'] : '');
  final imageController = TextEditingController(text: isEdit ? existing['imageUrl'] : '');

  String targetScreen = isEdit ? (existing['targetScreen'] ?? 'gold') : 'gold';
  String status = isEdit ? (existing['status'] ?? 'ACTIVE') : 'ACTIVE';

  showDialog(
  context: context,
  builder: (ctx) => StatefulBuilder(
  builder: (ctx, setDialogState) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFE2E8F0))),
  title: Text(
  isEdit ? "Edit Banner: ${existing['title']}" : "Add Promotional Banner",
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
  ),
  content: Container(
  constraints: const BoxConstraints(maxWidth: 520),
  child: SingleChildScrollView(
  child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  TextField(
  controller: titleController,
  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "OFFER HEADLINE / TITLE",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. 24K Physical Gold Vault",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  const SizedBox(height: 12),
  TextField(
  controller: subtitleController,
  style: const TextStyle(color: Color(0xFF0F172A)),
  decoration: InputDecoration(
  labelText: "OFFER SUBTITLE / DETAILS",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. Pure 999.9 Bullion Custody @ 0% Trading Fees",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  const SizedBox(height: 12),
  TextField(
  controller: imageController,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
  decoration: InputDecoration(
  labelText: "BANNER BACKGROUND IMAGE URL",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "https://images.unsplash.com/... or direct image link",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  const SizedBox(height: 14),
  Row(
  children: [
  // Target Screen Dropdown
  Expanded(
  child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
  value: targetScreen,
  dropdownColor: AppConstants.surfaceCard,
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "gold", child: Text("🥇 24K Gold Vault")),
  DropdownMenuItem(value: "shop", child: Text("🛍️ Digital Shop")),
  DropdownMenuItem(value: "savings", child: Text("📈 Savings Vault")),
  DropdownMenuItem(value: "bills", child: Text("💡 Pay Utility Bills")),
  DropdownMenuItem(value: "kameti", child: Text("🤝 Digital Kameti")),
  DropdownMenuItem(value: "binance", child: Text("⚡ Binance P2P Hub")),
  DropdownMenuItem(value: "telecom", child: Text("📱 Mobile Packages")),
  ],
  onChanged: (val) {
  if (val != null) setDialogState(() => targetScreen = val);
  },
  ),
  ),
  ),
  ),
  const SizedBox(width: 10),
  // Status Dropdown
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
  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "ACTIVE", child: Text("🟢 Active (Shown)")),
  DropdownMenuItem(value: "DISABLED", child: Text("🔴 Disabled (Hidden)")),
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
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: Color(0xFF021A13)),
  onPressed: () async {
  final title = titleController.text.trim();
  final subtitle = subtitleController.text.trim();
  final img = imageController.text.trim();
  if (title.isEmpty) return;

  Navigator.pop(ctx);

  final bannerObj = {
  'id': isEdit ? existing['id'] : 'banner_${DateTime.now().millisecondsSinceEpoch}',
  'title': title,
  'subtitle': subtitle,
  'imageUrl': img,
  'targetScreen': targetScreen,
  'status': status,
  'isDeleted': false,
  };

  final updatedList = List.from(_bannersList);
  if (isEdit) {
  final idx = updatedList.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) updatedList[idx] = bannerObj;
  } else {
  updatedList.add(bannerObj);
  }

  await _saveBannersList(updatedList, admin);
  },
  child: const Text("Save & Publish Banner", style: TextStyle(fontWeight: FontWeight.w900)),
  ),
  ],
  ),
  ),
  );
  }

  // Delete Banner Confirmation
  void _confirmDeleteBanner(BuildContext context, Map<String, dynamic> b, AdminProvider admin) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: const Text("Delete Banner?", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w900)),
  content: Text("Kya aap waqai \"${b['title']}\" ko customer app se remove karna chahte hain?", style: const TextStyle(color: AppConstants.textMuted)),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Color(0xFF0F172A)),
  onPressed: () async {
  Navigator.pop(ctx);
  final updatedList = List.from(_bannersList);
  updatedList.removeWhere((x) => x['id'] == b['id']);
  await _saveBannersList(updatedList, admin);
  },
  child: const Text("Delete Banner"),
  ),
  ],
  ),
  );
  }

  Future<void> _saveBannersList(List updatedList, AdminProvider admin) async {
  setState(() => _isSaving = true);
  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'save_config'},
  data: {'homeBanners': updatedList},
  );

  if (res.data['status'] == 'success') {
  setState(() => _bannersList = updatedList);
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ Home banners synchronized live!", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }
  }
  } catch (_) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Failed to update banners.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isSaving = false);
  }
  }
}
